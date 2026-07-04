//
//  ContentView.swift
//  NaiwaSeeYou
//
//  Created by Serac on 2026/5/24.
//

import SwiftUI
import AVFoundation
import Vision

// MARK: - Face Tracker

@Observable
final class FaceTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var pupilOffset: CGPoint = .zero
    var isFaceDetected = false

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

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
        try? handler.perform([request])

        if let face = request.results?.first {
            let bbox = face.boundingBox
            let ox = (bbox.midX - 0.5) * 2.0
            let oy = -(bbox.midY - 0.5) * 2.0

            Task { @MainActor [weak self] in
                guard let self else { return }
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.7)) {
                    self.pupilOffset = CGPoint(
                        x: min(max(ox, -1), 1),
                        y: min(max(oy, -1), 1)
                    )
                    self.isFaceDetected = true
                }
            }
        } else {
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

        guard let url = Bundle.main.url(forResource: "hhhhh", withExtension: "mp3"),
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

// MARK: - Laughing Face

struct NaiwaLaughingExpressionView: View {
    let size: CGFloat

    var body: some View {
        Image("大笑表情")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
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
    @State private var dragPupilOffset: CGPoint?
    @State private var isLeftEyeClosed = false
    @State private var isRightEyeClosed = false

    private let eyeSize: CGFloat = 86
    private let eyeSpacing: CGFloat = 116
    private let mouthTopPadding: CGFloat = 28

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
        dragPupilOffset ?? faceTracker.pupilOffset
    }

    var body: some View {
        ZStack {
            Color(red: 0.988, green: 0.8, blue: 0.145)
                .ignoresSafeArea()

            VStack {
                Spacer()
                NaiwaBellyView()
            }
            .ignoresSafeArea(edges: .bottom)

            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(interactionGesture(in: geometry.size))

                    Group {
                        if laughController.isLaughing {
                            NaiwaLaughingExpressionView(size: laughingImageSize(in: geometry.size))
                                .frame(width: geometry.size.width, alignment: .center)
                                .offset(y: laughingVerticalOffset(in: geometry.size))
                                .transition(.scale(scale: 0.92).combined(with: .opacity))
                        } else {
                            VStack(spacing: 0) {
                                HStack(spacing: eyeSpacing) {
                                    NaiwaEyeView(
                                        pupilOffset: activePupilOffset,
                                        size: eyeSize,
                                        isClosed: isLeftEyeClosed
                                    )
                                    NaiwaEyeView(
                                        pupilOffset: activePupilOffset,
                                        size: eyeSize,
                                        isClosed: isRightEyeClosed
                                    )
                                }

                                NaiwaMouthView()
                                    .padding(.top, mouthTopPadding)
                            }
                            .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.top, expressionTop(in: geometry.size))
                    .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            faceTracker.requestAccessAndStart()
        }
    }

    private func interactionGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
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
                if dragDistance(for: value) <= 8 {
                    handleTap(at: value.location, in: size)
                } else {
                    withAnimation(.easeOut(duration: 0.22)) {
                        dragPupilOffset = nil
                    }
                }
            }
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
        let eyeCenter = CGPoint(
            x: size.width * 0.5,
            y: expressionTop(in: size) + eyeSize * 0.5
        )
        let x = (location.x - eyeCenter.x) / (size.width * 0.34)
        let y = (location.y - eyeCenter.y) / (size.height * 0.24)

        return CGPoint(
            x: min(max(x, -1), 1),
            y: min(max(y, -1), 1)
        )
    }

    private func expressionControl(at point: CGPoint, in size: CGSize) -> ExpressionControl? {
        let top = expressionTop(in: size)
        let eyeWidth = eyeSize * 0.86
        let eyeHeight = eyeSize
        let eyeCenterDistance = eyeWidth + eyeSpacing
        let leftEyeOrigin = CGPoint(
            x: size.width * 0.5 - eyeCenterDistance * 0.5 - eyeWidth * 0.5,
            y: top
        )
        let rightEyeOrigin = CGPoint(
            x: size.width * 0.5 + eyeCenterDistance * 0.5 - eyeWidth * 0.5,
            y: top
        )
        let mouthSize = CGSize(width: 188, height: 34)
        let mouthOrigin = CGPoint(
            x: size.width * 0.5 - mouthSize.width * 0.5,
            y: top + eyeSize + mouthTopPadding
        )

        let leftEyeFrame = CGRect(origin: leftEyeOrigin, size: CGSize(width: eyeWidth, height: eyeHeight)).insetBy(dx: -18, dy: -18)
        let rightEyeFrame = CGRect(origin: rightEyeOrigin, size: CGSize(width: eyeWidth, height: eyeHeight)).insetBy(dx: -18, dy: -18)
        let mouthFrame = CGRect(origin: mouthOrigin, size: mouthSize).insetBy(dx: -18, dy: -18)

        if leftEyeFrame.contains(point) {
            return .leftEye
        } else if rightEyeFrame.contains(point) {
            return .rightEye
        } else if mouthFrame.contains(point) {
            return .mouth
        } else {
            return nil
        }
    }

    private func expressionTop(in size: CGSize) -> CGFloat {
        size.height * 0.23
    }

    private func laughingImageSize(in size: CGSize) -> CGFloat {
        min(max(size.width * 1.18, 440), 520)
    }

    private func laughingVerticalOffset(in size: CGSize) -> CGFloat {
        -size.height * 0.1
    }
}

#Preview {
    ContentView()
}
