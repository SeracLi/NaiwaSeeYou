//
//  ContentView.swift
//  NaiwaSeeYou
//
//  Created by Serac on 2026/5/24.
//

import SwiftUI
import AVFoundation
import Vision
import CoreMotion

// MARK: - Face Tracker

@Observable
final class FaceTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var pupilOffset: CGPoint = .zero
    var isFaceDetected = false

    // Timestamp of the last frame that contained a face. Mutated at camera
    // frame rate — kept out of SwiftUI observation so it doesn't churn the view.
    @ObservationIgnored
    var lastFaceSeenAt: Date = Date()

    // Running low-pass state, only touched on the serial capture queue —
    // nonisolated(unsafe) because that queue guarantees exclusive access.
    @ObservationIgnored
    nonisolated(unsafe) private var filteredOffset: CGPoint = .zero

    private var captureSession: AVCaptureSession?

    func requestAccessAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    Task { @MainActor [weak self] in
                        self?.startSession()
                    }
                }
            }
        default:
            break
        }
    }

    private func startSession() {
        guard captureSession == nil else { return }

        let session = AVCaptureSession()
        session.sessionPreset = .low

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "face-tracking"))

        guard session.canAddOutput(output) else { return }
        session.addOutput(output)

        captureSession = session

        Task.detached { [session] in
            session.startRunning()
        }
    }

    // Called when the app returns to the foreground. iOS interrupts the
    // capture session during long backgrounding and does not always resume
    // it — without this, no frames arrive and the pupils stay frozen.
    func resume() {
        guard let session = captureSession else {
            requestAccessAndStart()
            return
        }
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.3)) {
                self.isFaceDetected = false
                self.pupilOffset = .zero
            }
        }
        Task.detached { [session] in
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
        try? handler.perform([request])

        if let face = request.results?.first {
            let bbox = face.boundingBox
            let rawX = min(max((bbox.midX - 0.5) * 2.0, -1), 1)
            let rawY = min(max(-(bbox.midY - 0.5) * 2.0, -1), 1)

            // Adaptive low-pass filter. Vision's bbox center jitters a few
            // percent every frame even when the subject is still; feeding that
            // straight through makes the pupils vibrate. When the target barely
            // moves we smooth hard (small alpha) to absorb the noise; when the
            // face genuinely moves, alpha opens up so tracking stays snappy.
            let dx = rawX - filteredOffset.x
            let dy = rawY - filteredOffset.y
            let dist = (dx * dx + dy * dy).squareRoot()
            let alpha = dist < 0.02 ? 0.05 : min(0.18 + dist * 1.8, 0.6)
            filteredOffset = CGPoint(
                x: filteredOffset.x + dx * alpha,
                y: filteredOffset.y + dy * alpha
            )
            let smoothed = filteredOffset

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.lastFaceSeenAt = Date()
                withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.78)) {
                    self.pupilOffset = smoothed
                    self.isFaceDetected = true
                }
            }
        } else {
            filteredOffset = .zero
            Task { @MainActor [weak self] in
                guard let self else { return }
                withAnimation(.easeOut(duration: 0.4)) {
                    self.isFaceDetected = false
                    self.pupilOffset = .zero
                }
            }
        }
    }
}

// MARK: - Shake Detector

@Observable
final class ShakeDetector {
    var intensity: Double = 0

    @ObservationIgnored
    private let motion = CMMotionManager()
    @ObservationIgnored
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "naiwa-shake"
        q.qualityOfService = .userInitiated
        return q
    }()

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        guard !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let a = motion.userAcceleration
            let mag = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            // Ignore very small motion (e.g. natural hand-tremor) to keep the
            // idle baseline near zero. Above the floor, contributions accumulate
            // through a leaky integrator so brief taps do not trigger dizzy but
            // sustained shaking builds up over ~700ms.
            let contribution = mag > 0.05 ? mag * 0.10 : 0
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.intensity = min(self.intensity * 0.97 + contribution, 3.0)
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }

    @MainActor
    func reset() {
        intensity = 0
    }
}

// MARK: - Laugh Controller

@MainActor
@Observable
final class LaughController {
    var isLaughing = false

    private var player: AVAudioPlayer?
    private var playbackID = UUID()

    func toggle() {
        if isLaughing {
            stop()
        } else {
            play()
        }
    }

    func play() {
        playbackID = UUID()
        let currentID = playbackID

        guard let url = Bundle.main.url(forResource: "hhhh", withExtension: "mp3"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                isLaughing = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                guard currentID == playbackID else { return }
                withAnimation(.easeOut(duration: 0.18)) {
                    isLaughing = false
                }
            }
            return
        }

        self.player?.stop()
        self.player = player
        player.currentTime = 0
        player.prepareToPlay()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.66)) {
            isLaughing = true
        }
        player.play()

        Task {
            try? await Task.sleep(for: .seconds(player.duration))
            guard currentID == playbackID else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                isLaughing = false
            }
        }
    }

    func stop() {
        playbackID = UUID()
        player?.stop()
        player?.currentTime = 0

        withAnimation(.easeOut(duration: 0.12)) {
            isLaughing = false
        }
    }
}

// MARK: - Naiwa Eye

struct NaiwaEyeView: View {
    let pupilOffset: CGPoint
    let size: CGFloat
    let isClosed: Bool

    private let irisCenterColor = Color(red: 0.64, green: 0.9, blue: 0.49)
    private let irisEdgeColor = Color(red: 0.29, green: 0.63, blue: 0.34)
    private let irisRimColor = Color(red: 0.22, green: 0.52, blue: 0.28)
    private let skinColor = Color(red: 0.988, green: 0.8, blue: 0.145)

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.52, green: 0.45, blue: 0.15, opacity: 0.24),
                            Color(red: 0.52, green: 0.45, blue: 0.15, opacity: 0)
                        ],
                        center: .center,
                        startRadius: size * 0.12,
                        endRadius: size * 0.64
                    )
                )
                .frame(width: size * 1.12, height: size * 1.24)
                .offset(y: size * 0.06)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            irisCenterColor,
                            irisCenterColor,
                            irisEdgeColor
                        ],
                        center: UnitPoint(x: 0.42, y: 0.32),
                        startRadius: size * 0.04,
                        endRadius: size * 0.55
                    )
                )
                .overlay {
                    Ellipse()
                        .stroke(irisRimColor.opacity(0.42), lineWidth: size * 0.014)
                        .blur(radius: 0.15)
                }
                .overlay(alignment: .topLeading) {
                    Ellipse()
                        .fill(.white.opacity(0.18))
                        .frame(width: size * 0.42, height: size * 0.28)
                        .offset(x: size * 0.22, y: size * 0.12)
                        .blur(radius: 5)
                }
                .frame(width: size * 0.86, height: size)

            Ellipse()
                .fill(.black)
                .frame(width: size * 0.45, height: size * 0.58)
                .offset(
                x: pupilOffset.x * size * 0.055,
                y: pupilOffset.y * size * 0.055
            )

            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                skinColor.opacity(0.98),
                                Color(red: 0.9, green: 0.67, blue: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.9, height: size * 1.04)

                Canvas { context, canvasSize in
                    let w = canvasSize.width
                    let h = canvasSize.height
                    var crease = Path()
                    crease.move(to: CGPoint(x: w * 0.18, y: h * 0.5))
                    crease.addQuadCurve(
                        to: CGPoint(x: w * 0.82, y: h * 0.5),
                        control: CGPoint(x: w * 0.5, y: h * 0.64)
                    )
                    context.stroke(
                        crease,
                        with: .color(.black.opacity(0.78)),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                }
                .frame(width: size * 0.8, height: size * 0.48)
            }
            .scaleEffect(y: isClosed ? 1 : 0.001, anchor: .top)
            .opacity(isClosed ? 1 : 0)
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isClosed)
    }
}

// MARK: - Naiwa Mouth

struct NaiwaMouthView: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            var lip = Path()
            lip.move(to: CGPoint(x: w * 0.05, y: h * 0.36))
            lip.addCurve(
                to: CGPoint(x: w * 0.43, y: h * 0.35),
                control1: CGPoint(x: w * 0.18, y: h * 0.48),
                control2: CGPoint(x: w * 0.31, y: h * 0.5)
            )
            lip.addCurve(
                to: CGPoint(x: w * 0.57, y: h * 0.35),
                control1: CGPoint(x: w * 0.47, y: h * 0.28),
                control2: CGPoint(x: w * 0.53, y: h * 0.28)
            )
            lip.addCurve(
                to: CGPoint(x: w * 0.95, y: h * 0.36),
                control1: CGPoint(x: w * 0.69, y: h * 0.5),
                control2: CGPoint(x: w * 0.82, y: h * 0.48)
            )
            lip.addCurve(
                to: CGPoint(x: w * 0.05, y: h * 0.36),
                control1: CGPoint(x: w * 0.72, y: h * 0.68),
                control2: CGPoint(x: w * 0.28, y: h * 0.68)
            )
            lip.closeSubpath()

            context.fill(
                lip,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.62, green: 0.56, blue: 0.46).opacity(0.88),
                        Color(red: 0.2, green: 0.18, blue: 0.15).opacity(0.96)
                    ]),
                    startPoint: CGPoint(x: w * 0.5, y: h * 0.24),
                    endPoint: CGPoint(x: w * 0.5, y: h * 0.66)
                )
            )
        }
        .frame(width: 218, height: 28)
    }
}

// MARK: - Belly

struct NaiwaBellyView: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let w = size.width
                let h = size.height

                var belly = Path()
                belly.move(to: CGPoint(x: 0, y: h * 0.54))
                belly.addQuadCurve(
                    to: CGPoint(x: w, y: h * 0.54),
                    control: CGPoint(x: w * 0.5, y: h * 0.1)
                )
                belly.addLine(to: CGPoint(x: w, y: h))
                belly.addLine(to: CGPoint(x: 0, y: h))
                belly.closeSubpath()

                context.fill(
                    belly,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 1.0, green: 0.9, blue: 0.42).opacity(0.72),
                            Color(red: 1.0, green: 0.86, blue: 0.31).opacity(0.9)
                        ]),
                        startPoint: CGPoint(x: w * 0.5, y: 0),
                        endPoint: CGPoint(x: w * 0.5, y: h)
                    )
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: 320)
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var faceTracker = FaceTracker()
    @State private var laughController = LaughController()
    @State private var shakeDetector = ShakeDetector()
    @State private var dragPupilOffset: CGPoint?
    @State private var isLeftEyeClosed = false
    @State private var isRightEyeClosed = false
    @State private var isSleeping = false
    @State private var sleepStartedAt: Date?
    @State private var isDrooling = false
    @State private var isDizzy = false
    @State private var dizzyProgress: CGFloat = 0
    @State private var shakeDart: CGPoint = .zero
    @State private var dizzyPlayer: AVAudioPlayer?
    @State private var isAbsorbingWakeGesture = false
    @State private var showControlPanel = false
    @AppStorage("naiwaBellyEnabled") private var bellyEnabled: Bool = true
    @AppStorage("naiwaBackgroundThemeRaw") private var backgroundThemeRaw: String = NaiwaBackgroundTheme.yellow.rawValue
    @Environment(\.scenePhase) private var scenePhase

    private static let sleepIdleThreshold: TimeInterval = 60
    private static let droolAfterSleep: TimeInterval = 30
    private static let dizzyEnterThreshold: Double = 1.5
    private static let dizzyExitThreshold: Double = 0.6

    private var backgroundTheme: NaiwaBackgroundTheme {
        NaiwaBackgroundTheme(rawValue: backgroundThemeRaw) ?? .yellow
    }

    private var pupilDartAmount: CGFloat {
        CGFloat(min(max(shakeDetector.intensity - 0.2, 0) / 1.0, 1))
    }

    private enum ExpressionControl {
        case leftEye
        case rightEye
        case mouth
    }

    private enum EyeSide {
        case left
        case right
    }

    private var activePupilOffset: CGPoint {
        let base = dragPupilOffset ?? faceTracker.pupilOffset
        return CGPoint(x: base.x + shakeDart.x, y: base.y + shakeDart.y)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geometry in
                    ZStack(alignment: .top) {
                        NaiwaLivingFaceView(
                            pupilOffset: activePupilOffset,
                            isLeftEyeClosed: isLeftEyeClosed,
                            isRightEyeClosed: isRightEyeClosed,
                            isLaughing: laughController.isLaughing,
                            isSleeping: isSleeping,
                            isDrooling: isDrooling,
                            dizzyProgress: dizzyProgress,
                            backgroundTheme: backgroundTheme,
                            showBelly: bellyEnabled
                        )
                        .allowsHitTesting(false)

                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(interactionGesture(in: geometry.size))
                    }
                }

                VStack {
                    HStack(spacing: 0) {
                        Spacer()
                        Button {
                            showControlPanel = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.black.opacity(0.4))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.black.opacity(0.4))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }
                    Spacer()
                }
                .padding(.trailing, 4)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                faceTracker.requestAccessAndStart()
                shakeDetector.start()
                preloadDizzyPlayer()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    faceTracker.resume()
                    shakeDetector.start()
                    try? AVAudioSession.sharedInstance().setActive(true)
                } else {
                    shakeDetector.stop()
                }
            }
            .onChange(of: laughController.isLaughing) { _, laughing in
                if laughing {
                    shakeDetector.reset()
                    dizzyPlayer?.stop()
                    if isDizzy {
                        isDizzy = false
                    }
                }
            }
            .onChange(of: isDizzy) { _, dizzy in
                withAnimation(.easeInOut(duration: dizzy ? 0.3 : 0.6)) {
                    dizzyProgress = dizzy ? 1 : 0
                }
                if dizzy && !laughController.isLaughing {
                    playDizzySound()
                }
            }
            .sheet(isPresented: $showControlPanel) {
                NaiwaControlPanel(
                    bellyEnabled: $bellyEnabled,
                    theme: Binding(
                        get: { backgroundTheme },
                        set: { backgroundThemeRaw = $0.rawValue }
                    )
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.white)
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(500))
                    let idle = Date().timeIntervalSince(faceTracker.lastFaceSeenAt)

                    if isSleeping {
                        // Face detection alone does NOT wake — biological realism.
                        // Only sustained shake (or laugh / dizzy which imply user
                        // action) breaks sleep. Direct taps wake via wakeUp() in
                        // the gesture handler.
                        let shouldWake = laughController.isLaughing
                            || isDizzy
                            || shakeDetector.intensity > 0.3
                        if shouldWake {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isSleeping = false
                            }
                            sleepStartedAt = nil
                        }
                    } else {
                        let shouldEnter = idle > Self.sleepIdleThreshold
                            && !laughController.isLaughing
                            && !isDizzy
                            && shakeDetector.intensity < 0.3
                        if shouldEnter {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                isSleeping = true
                            }
                            sleepStartedAt = Date()
                        }
                    }

                    let shouldDrool: Bool = {
                        guard isSleeping, let start = sleepStartedAt else { return false }
                        return Date().timeIntervalSince(start) > Self.droolAfterSleep
                    }()
                    if shouldDrool != isDrooling {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isDrooling = shouldDrool
                        }
                    }
                }
            }
            .task {
                // Dizzy state supervisor — reads intensity every 180ms, applies
                // hysteresis so brief jitters near the threshold do not chatter.
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(180))
                    guard !laughController.isLaughing else { continue }
                    let i = shakeDetector.intensity
                    let should = i > Self.dizzyEnterThreshold || (isDizzy && i > Self.dizzyExitThreshold)
                    if should != isDizzy {
                        isDizzy = should
                    }
                }
            }
            .task {
                // Erratic pupil dart — retargets every 140ms with amplitude
                // proportional to shake intensity. Smooth interp between targets
                // reads as panicked eye-flicking rather than teleporting jitter.
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(140))
                    let amount = pupilDartAmount
                    if amount > 0.05 {
                        let mag = Double(amount) * 0.85
                        let dx = Double.random(in: -1...1) * mag
                        let dy = Double.random(in: -1...1) * mag
                        withAnimation(.easeOut(duration: 0.12)) {
                            shakeDart = CGPoint(x: dx, y: dy)
                        }
                    } else if shakeDart != .zero {
                        withAnimation(.easeOut(duration: 0.22)) {
                            shakeDart = .zero
                        }
                    }
                }
            }
        }
    }

    private func interactionGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // Sleep is a barrier: any first touch on a sleeping character
                // wakes it — no laugh, no eye-close, no drag. The absorb flag
                // blocks the rest of the ongoing gesture (subsequent .onChanged
                // fires) so the drag doesn't retroactively move the eyes on the
                // now-awake face.
                if isSleeping {
                    if !isAbsorbingWakeGesture {
                        wakeUp()
                        isAbsorbingWakeGesture = true
                    }
                    return
                }
                if isAbsorbingWakeGesture { return }

                guard !laughController.isLaughing else {
                    dragPupilOffset = nil
                    return
                }
                guard dragDistance(for: value) > 8 else { return }
                guard expressionControl(at: value.startLocation, in: size) == nil else {
                    dragPupilOffset = nil
                    return
                }

                withAnimation(.interactiveSpring(response: 0.12, dampingFraction: 0.78)) {
                    dragPupilOffset = pupilOffset(for: value.location, in: size)
                }
            }
            .onEnded { value in
                if isAbsorbingWakeGesture {
                    isAbsorbingWakeGesture = false
                    return
                }
                if dragDistance(for: value) <= 8 {
                    handleTap(at: value.location, in: size)
                } else {
                    withAnimation(.easeOut(duration: 0.22)) {
                        dragPupilOffset = nil
                    }
                }
            }
    }

    private func wakeUp() {
        guard isSleeping else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            isSleeping = false
        }
        sleepStartedAt = nil
        // Give a grace period so the sleep task doesn't immediately re-enter
        // sleep on the next tick (idle would otherwise still be > threshold).
        faceTracker.lastFaceSeenAt = Date()
    }

    private func preloadDizzyPlayer() {
        guard dizzyPlayer == nil else { return }
        guard let url = Bundle.main.url(forResource: "眩晕", withExtension: "mp3") else { return }
        dizzyPlayer = try? AVAudioPlayer(contentsOf: url)
        dizzyPlayer?.prepareToPlay()
    }

    private func playDizzySound() {
        guard let player = dizzyPlayer else { return }
        player.stop()
        player.currentTime = 0
        player.play()
    }

    private func handleTap(at point: CGPoint, in size: CGSize) {
        guard !laughController.isLaughing else {
            laughController.stop()
            return
        }

        switch expressionControl(at: point, in: size) {
        case .leftEye:
            closeEye(.left)
        case .rightEye:
            closeEye(.right)
        case .mouth:
            laughController.play()
        case nil:
            laughController.play()
        }
    }

    private func closeEye(_ side: EyeSide) {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.68)) {
            setEye(side, isClosed: true)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(820))
            withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
                setEye(side, isClosed: false)
            }
        }
    }

    private func setEye(_ side: EyeSide, isClosed: Bool) {
        switch side {
        case .left:
            isLeftEyeClosed = isClosed
        case .right:
            isRightEyeClosed = isClosed
        }
    }

    private func dragDistance(for value: DragGesture.Value) -> CGFloat {
        hypot(value.translation.width, value.translation.height)
    }

    private func pupilOffset(for location: CGPoint, in size: CGSize) -> CGPoint {
        let eyes = NaiwaFaceSpec.eyeCenters(in: size)
        let eyeCenter = CGPoint(
            x: size.width * 0.5,
            y: (eyes.left.y + eyes.right.y) * 0.5
        )
        let x = (location.x - eyeCenter.x) / (size.width * 0.34)
        let y = (location.y - eyeCenter.y) / (size.height * 0.24)

        return CGPoint(
            x: min(max(x, -1), 1),
            y: min(max(y, -1), 1)
        )
    }

    private func expressionControl(at point: CGPoint, in size: CGSize) -> ExpressionControl? {
        switch NaiwaFaceSpec.hitRegion(at: point, in: size) {
        case .leftEye:
            return .leftEye
        case .rightEye:
            return .rightEye
        case .mouth:
            return .mouth
        case nil:
            return nil
        }
    }

}

// MARK: - Naiwa Control Panel

struct NaiwaControlPanel: View {
    @Binding var bellyEnabled: Bool
    @Binding var theme: NaiwaBackgroundTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            bellyRow
            themeRow
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    private var bellyRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.bottomhalf.filled")
                .font(.system(size: 18))
                .foregroundColor(.black.opacity(0.75))
                .frame(width: 24)
            Text("显示肚子")
                .font(.system(size: 16))
                .foregroundColor(.black)
            Spacer()
            Toggle("", isOn: $bellyEnabled)
                .labelsHidden()
                .tint(.black)
        }
    }

    private var themeRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.75))
                    .frame(width: 24)
                Text("背景配色")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                Spacer()
            }
            HStack(spacing: 16) {
                ForEach(NaiwaBackgroundTheme.allCases) { swatch in
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            theme = swatch
                        }
                    } label: {
                        themeSwatch(for: swatch)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.leading, 36)
        }
    }

    private func themeSwatch(for swatch: NaiwaBackgroundTheme) -> some View {
        let selected = theme == swatch
        return ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: swatch.swatchGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
                )

            if selected {
                Circle()
                    .strokeBorder(Color.black.opacity(0.85), lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
        }
        .frame(width: 40, height: 40)
    }
}

#Preview {
    ContentView()
}

#Preview("Control Panel") {
    NaiwaControlPanel(
        bellyEnabled: .constant(true),
        theme: .constant(.yellow)
    )
}
