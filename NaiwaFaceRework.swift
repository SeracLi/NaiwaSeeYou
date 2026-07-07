//
//  NaiwaFaceRework.swift
//  NaiwaSeeYou
//
//  v3 face rework based on official character proportions.
//

import SwiftUI

// MARK: - Layout and Color Spec

enum NaiwaFaceSpec {
    static let eyeLineHeightFraction: CGFloat = 0.335
    static let featureScale: CGFloat = 1.15

    static let eyeSeparation: CGFloat = 0.356
    static let eyeWidth: CGFloat = 0.142
    static let eyeHeight: CGFloat = 0.152
    static let pupilWidth: CGFloat = 0.077
    static let pupilHeight: CGFloat = 0.089
    static let pupilRestingDrop: CGFloat = 0.006
    static let pupilTravelX: CGFloat = 0.024
    static let pupilTravelY: CGFloat = 0.021

    static let mouthDropBelowEyes: CGFloat = 0.148
    static let mouthWidth: CGFloat = 0.252
    static let mouthCornerLift: CGFloat = 0.021
    static let mouthThickness: CGFloat = 0.0067
    static let upperLipRise: CGFloat = 0.009
    static let upperLipDip: CGFloat = 0.003

    static let bellyRadiusX: CGFloat = 0.62
    static let bellyRadiusY: CGFloat = 0.711
    static let bellyApexAboveBottom: CGFloat = 0.43

    static let skinTop = Color(red: 1.000, green: 0.820, blue: 0.286)
    static let skinUpperMid = Color(red: 1.000, green: 0.800, blue: 0.274)
    static let skinLowerMid = Color(red: 0.984, green: 0.660, blue: 0.176)
    static let skinChest = Color(red: 0.984, green: 0.631, blue: 0.145)

    /// 八字倾斜角度（度）。左眼顺时针、右眼逆时针，眼顶朝内，微微即可
    static let eyeTiltDegrees: Double = 18.0
    /// 闭眼黑线的净倾斜角（度）。眼睛整体倾斜时，黑线反向抵消到这个更温和的角度
    static let seamTiltDegrees: Double = 7.0

    static let irisBright = Color(red: 0.510, green: 0.816, blue: 0.561)
    static let irisMid = Color(red: 0.376, green: 0.698, blue: 0.384)
    static let irisDeep = Color(red: 0.286, green: 0.588, blue: 0.259)
    static let irisRim = Color(red: 0.098, green: 0.216, blue: 0.118)
    static let eyelidTop = Color(red: 1.000, green: 0.860, blue: 0.370)
    static let eyelidMid = Color(red: 1.000, green: 0.780, blue: 0.260)
    static let eyelidBottom = Color(red: 0.970, green: 0.700, blue: 0.190)

    static let bellyLight = Color(red: 0.980, green: 0.840, blue: 0.640)
    static let bellyMid = Color(red: 0.965, green: 0.827, blue: 0.643)
    static let bellyEdge = Color(red: 0.859, green: 0.690, blue: 0.467)

    static let eyeProtrusionGlow = Color(red: 1.00, green: 0.875, blue: 0.40)
    static let chinShadowTone = Color(red: 0.85, green: 0.48, blue: 0.08)
    static let muzzleGlow = Color(red: 1.00, green: 0.88, blue: 0.45)
    static let upperLipMid = Color(red: 0.86, green: 0.71, blue: 0.42)
    static let upperLipDeep = Color(red: 0.40, green: 0.32, blue: 0.18)
    static let mouthInk = Color(red: 0.118, green: 0.071, blue: 0.039)

    static func featureUnit(for size: CGSize) -> CGFloat {
        size.width * featureScale
    }

    static func eyeCenters(in size: CGSize) -> (left: CGPoint, right: CGPoint) {
        let y = size.height * eyeLineHeightFraction
        let dx = eyeSeparation * featureUnit(for: size) / 2
        return (
            CGPoint(x: size.width / 2 - dx, y: y),
            CGPoint(x: size.width / 2 + dx, y: y)
        )
    }

    static func mouthCenter(in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width / 2,
            y: size.height * eyeLineHeightFraction + mouthDropBelowEyes * featureUnit(for: size)
        )
    }

    static func bellyRect(in size: CGSize) -> CGRect {
        let w = size.width
        let rx = bellyRadiusX * w
        let ry = bellyRadiusY * w
        let centerY = size.height + (ry - bellyApexAboveBottom * w)
        return CGRect(x: w / 2 - rx, y: centerY - ry, width: rx * 2, height: ry * 2)
    }

    static func clampedPupilVector(_ raw: CGPoint) -> CGPoint {
        let length = sqrt(raw.x * raw.x + raw.y * raw.y)
        guard length > 1 else { return raw }
        return CGPoint(x: raw.x / length, y: raw.y / length)
    }

    enum HitRegion {
        case leftEye
        case rightEye
        case mouth
        // 躯干四象限（嘴以下、肚皮以上）——对应四段语音
        case speakTopLeft      // 音频 1
        case speakBottomLeft   // 音频 2
        case speakTopRight     // 音频 3
        case speakBottomRight  // 音频 4
        // 底部长方形（肚皮位置）——大笑
        case belly
    }

    static func hitRegion(at point: CGPoint, in size: CGSize) -> HitRegion? {
        let u = featureUnit(for: size)
        let pad: CGFloat = 18
        let eyes = eyeCenters(in: size)
        let eyeSize = CGSize(width: eyeWidth * u, height: eyeHeight * u)

        func frame(_ center: CGPoint, _ size: CGSize) -> CGRect {
            CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            .insetBy(dx: -pad, dy: -pad)
        }

        if frame(eyes.left, eyeSize).contains(point) { return .leftEye }
        if frame(eyes.right, eyeSize).contains(point) { return .rightEye }

        let mouthSize = CGSize(
            width: mouthWidth * u,
            height: (mouthCornerLift + upperLipRise) * u + 24
        )
        if frame(mouthCenter(in: size), mouthSize).contains(point) { return .mouth }

        // 底部长方形（与肚皮顶点对齐，全宽）——大笑，无关是否显示肚皮
        let bellyTopY = size.height - bellyApexAboveBottom * size.width
        if point.y >= bellyTopY { return .belly }

        // 躯干说话区：嘴稍下方 → 肚皮顶点，切成左右×上下四象限
        let bodyTop = mouthCenter(in: size).y + u * 0.10
        if point.y >= bodyTop && point.y < bellyTopY {
            let midY = (bodyTop + bellyTopY) / 2
            let isLeft = point.x < size.width / 2
            let isUpper = point.y < midY
            switch (isLeft, isUpper) {
            case (true, true):   return .speakTopLeft
            case (true, false):  return .speakBottomLeft
            case (false, true):  return .speakTopRight
            case (false, false): return .speakBottomRight
            }
        }

        return nil
    }
}

// MARK: - Background Theme

struct NaiwaThemePalette {
    let skinTop: Color
    let skinUpperMid: Color
    let skinLowerMid: Color
    let skinChest: Color
    let eyelidTop: Color
    let eyelidMid: Color
    let eyelidBottom: Color
    let eyeProtrusionGlow: Color
    let chinShadowTone: Color
    let muzzleGlow: Color
    let moundCore: Color
    let moundLight: Color
    let moundShadow: Color
    let rimShadow: Color
    let rimLight: Color
}

extension NaiwaThemePalette {
    static let yellow = NaiwaThemePalette(
        skinTop: Color(red: 1.000, green: 0.820, blue: 0.286),
        skinUpperMid: Color(red: 1.000, green: 0.800, blue: 0.274),
        skinLowerMid: Color(red: 0.984, green: 0.660, blue: 0.176),
        skinChest: Color(red: 0.984, green: 0.631, blue: 0.145),
        eyelidTop: Color(red: 1.000, green: 0.860, blue: 0.370),
        eyelidMid: Color(red: 1.000, green: 0.780, blue: 0.260),
        eyelidBottom: Color(red: 0.970, green: 0.700, blue: 0.190),
        eyeProtrusionGlow: Color(red: 1.000, green: 0.875, blue: 0.400),
        chinShadowTone: Color(red: 0.850, green: 0.480, blue: 0.080),
        muzzleGlow: Color(red: 1.000, green: 0.880, blue: 0.450),
        moundCore: Color(red: 1.000, green: 0.930, blue: 0.550),
        moundLight: Color(red: 0.984, green: 0.875, blue: 0.302),
        moundShadow: Color(red: 0.890, green: 0.639, blue: 0.090),
        rimShadow: Color(red: 0.620, green: 0.360, blue: 0.050),
        rimLight: Color(red: 1.000, green: 0.860, blue: 0.340)
    )

    static let pink = NaiwaThemePalette(
        skinTop: Color(red: 1.000, green: 0.815, blue: 0.860),
        skinUpperMid: Color(red: 1.000, green: 0.735, blue: 0.795),
        skinLowerMid: Color(red: 0.980, green: 0.555, blue: 0.660),
        skinChest: Color(red: 0.960, green: 0.470, blue: 0.585),
        eyelidTop: Color(red: 1.000, green: 0.855, blue: 0.895),
        eyelidMid: Color(red: 1.000, green: 0.755, blue: 0.815),
        eyelidBottom: Color(red: 0.980, green: 0.590, blue: 0.690),
        eyeProtrusionGlow: Color(red: 1.000, green: 0.870, blue: 0.900),
        chinShadowTone: Color(red: 0.720, green: 0.280, blue: 0.420),
        muzzleGlow: Color(red: 1.000, green: 0.900, blue: 0.930),
        moundCore: Color(red: 1.000, green: 0.920, blue: 0.940),
        moundLight: Color(red: 1.000, green: 0.780, blue: 0.830),
        moundShadow: Color(red: 0.880, green: 0.500, blue: 0.610),
        rimShadow: Color(red: 0.550, green: 0.190, blue: 0.300),
        rimLight: Color(red: 1.000, green: 0.800, blue: 0.860)
    )

    static let blue = NaiwaThemePalette(
        skinTop: Color(red: 0.740, green: 0.905, blue: 1.000),
        skinUpperMid: Color(red: 0.665, green: 0.850, blue: 1.000),
        skinLowerMid: Color(red: 0.395, green: 0.680, blue: 0.960),
        skinChest: Color(red: 0.290, green: 0.590, blue: 0.920),
        eyelidTop: Color(red: 0.800, green: 0.940, blue: 1.000),
        eyelidMid: Color(red: 0.700, green: 0.870, blue: 1.000),
        eyelidBottom: Color(red: 0.470, green: 0.740, blue: 0.970),
        eyeProtrusionGlow: Color(red: 0.800, green: 0.920, blue: 1.000),
        chinShadowTone: Color(red: 0.100, green: 0.280, blue: 0.550),
        muzzleGlow: Color(red: 0.850, green: 0.950, blue: 1.000),
        moundCore: Color(red: 0.920, green: 0.970, blue: 1.000),
        moundLight: Color(red: 0.700, green: 0.870, blue: 1.000),
        moundShadow: Color(red: 0.320, green: 0.600, blue: 0.860),
        rimShadow: Color(red: 0.090, green: 0.260, blue: 0.500),
        rimLight: Color(red: 0.700, green: 0.860, blue: 1.000)
    )

    static let green = NaiwaThemePalette(
        skinTop: Color(red: 0.760, green: 0.960, blue: 0.740),
        skinUpperMid: Color(red: 0.650, green: 0.920, blue: 0.620),
        skinLowerMid: Color(red: 0.400, green: 0.770, blue: 0.400),
        skinChest: Color(red: 0.310, green: 0.660, blue: 0.310),
        eyelidTop: Color(red: 0.815, green: 0.975, blue: 0.795),
        eyelidMid: Color(red: 0.700, green: 0.910, blue: 0.680),
        eyelidBottom: Color(red: 0.510, green: 0.810, blue: 0.490),
        eyeProtrusionGlow: Color(red: 0.850, green: 0.960, blue: 0.800),
        chinShadowTone: Color(red: 0.100, green: 0.420, blue: 0.150),
        muzzleGlow: Color(red: 0.880, green: 0.970, blue: 0.830),
        moundCore: Color(red: 0.940, green: 1.000, blue: 0.880),
        moundLight: Color(red: 0.700, green: 0.930, blue: 0.670),
        moundShadow: Color(red: 0.320, green: 0.660, blue: 0.290),
        rimShadow: Color(red: 0.100, green: 0.360, blue: 0.100),
        rimLight: Color(red: 0.750, green: 0.930, blue: 0.720)
    )
}

enum NaiwaBackgroundTheme: String, CaseIterable, Identifiable {
    case yellow
    case pink
    case blue
    case green

    var id: String { rawValue }

    var palette: NaiwaThemePalette {
        switch self {
        case .yellow: return .yellow
        case .pink:   return .pink
        case .blue:   return .blue
        case .green:  return .green
        }
    }

    var swatchGradient: [Color] { [palette.skinTop, palette.skinChest] }
}

private struct NaiwaThemeKey: EnvironmentKey {
    static let defaultValue: NaiwaBackgroundTheme = .yellow
}

extension EnvironmentValues {
    var naiwaTheme: NaiwaBackgroundTheme {
        get { self[NaiwaThemeKey.self] }
        set { self[NaiwaThemeKey.self] = newValue }
    }
}

// MARK: - Skin

struct NaiwaReworkSkinView: View {
    @Environment(\.naiwaTheme) private var theme
    /// 渐变起点在屏高中的位置（0 = 屏顶）。剪影模式传入轮廓顶点高度，
    /// 亮色从头顶开始向下过渡，顶点以上钳制为最亮色。
    var topAnchor: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let palette = theme.palette

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: palette.skinTop, location: 0.00),
                        .init(color: palette.skinUpperMid, location: 0.30),
                        .init(color: palette.skinLowerMid, location: 0.55),
                        .init(color: palette.skinChest, location: 0.80),
                        .init(color: palette.skinChest, location: 1.00)
                    ],
                    startPoint: UnitPoint(x: 0.5, y: Double(topAnchor)),
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [Color.white.opacity(0.10), .clear],
                    center: UnitPoint(x: 0.5, y: 0.10 + Double(topAnchor) * 0.9),
                    startRadius: 0,
                    endRadius: w * 0.7
                )

                LinearGradient(
                    colors: [Color.black.opacity(0.045), .clear, .clear, Color.black.opacity(0.045)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Eye

/// Animated eyelids that close toward a shared seam, with the upper lid traveling farther.
struct NaiwaLidShape: Shape {
    var close: CGFloat
    let isUpper: Bool
    let arcRise: CGFloat

    var animatableData: CGFloat {
        get { close }
        set { close = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let meetY = rect.height * 0.60
        let start: CGFloat = isUpper
            ? -rect.height * 0.06
            : rect.height * 1.06 + 2 * arcRise
        // The lower lid overshoots the seam slightly so the two lids overlap
        // instead of merely abutting — abutting fills leave an anti-aliased
        // hairline at the seam that reveals the iris beneath as a faint pale
        // line. Both lids share the same gradient, so the overlap is seamless.
        let overlap: CGFloat = isUpper ? 0 : rect.height * 0.03 * close
        let edgeY = start + (meetY - start) * close - overlap
        var path = Path()

        if isUpper {
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: edgeY))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: edgeY),
                control: CGPoint(x: rect.width / 2, y: edgeY - 2 * arcRise)
            )
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        } else {
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: edgeY))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: edgeY),
                control: CGPoint(x: rect.width / 2, y: edgeY - 2 * arcRise)
            )
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        }

        path.closeSubpath()
        return path
    }
}

struct NaiwaReworkEyeView: View {
    @Environment(\.naiwaTheme) private var theme
    let pupilOffset: CGPoint
    let unit: CGFloat
    var closeAmount: CGFloat = 0
    var isLeft: Bool = true
    var dizzyProgress: CGFloat = 0
    /// A held close (tap-to-close / sleep) shows the original crisp seam; an
    /// automatic blink uses a softened, later-fading seam so it doesn't flash.
    var strongSeam: Bool = false
    var tilted: Bool = false

    var body: some View {
        let palette = theme.palette
        let eyeW = NaiwaFaceSpec.eyeWidth * unit
        let eyeH = NaiwaFaceSpec.eyeHeight * unit
        let clamped = NaiwaFaceSpec.clampedPupilVector(pupilOffset)
        let drop = NaiwaFaceSpec.pupilRestingDrop * unit * (1 - abs(clamped.y))
        let close = min(max(closeAmount, 0), 1)
        let lidW = eyeW * 1.10
        let lidH = eyeH * 1.10
        let arcRise = NaiwaLaughSpec.crescentRise * unit * 0.55
        let seamOffsetY = ((-0.06 + 0.66 * close) - 0.5) * lidH

        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: palette.eyeProtrusionGlow.opacity(0.0), location: 0.00),
                            .init(color: palette.eyeProtrusionGlow.opacity(0.55), location: 0.52),
                            .init(color: palette.eyeProtrusionGlow.opacity(0.0), location: 1.00)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: eyeW * 0.92
                    )
                )
                .frame(width: eyeW * 1.75, height: eyeH * 1.62)
                .blur(radius: unit * 0.010)

            Ellipse()
                .fill(Color(red: 0.55, green: 0.32, blue: 0.05).opacity(0.10))
                .frame(width: eyeW * 1.30, height: eyeH * 0.36)
                .offset(y: eyeH * 0.50)
                .blur(radius: unit * 0.013)

            Ellipse()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: NaiwaFaceSpec.irisBright, location: 0.00),
                            .init(color: NaiwaFaceSpec.irisMid, location: 0.55),
                            .init(color: NaiwaFaceSpec.irisDeep, location: 1.00)
                        ],
                        center: UnitPoint(x: 0.5, y: 0.30),
                        startRadius: eyeW * 0.05,
                        endRadius: eyeW * 0.62
                    )
                )
                .overlay {
                    Ellipse()
                        .strokeBorder(
                            NaiwaFaceSpec.irisRim.opacity(0.45),
                            lineWidth: unit * 0.003
                        )
                }
                .frame(width: eyeW, height: eyeH)

            Ellipse()
                .fill(Color(red: 0.04, green: 0.04, blue: 0.04))
                .frame(
                    width: NaiwaFaceSpec.pupilWidth * unit,
                    height: NaiwaFaceSpec.pupilHeight * unit
                )
                .offset(
                    x: clamped.x * NaiwaFaceSpec.pupilTravelX * unit,
                    y: drop + clamped.y * NaiwaFaceSpec.pupilTravelY * unit
                )
                .opacity(1 - Double(dizzyProgress) * 0.85)

            TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: dizzyProgress < 0.02)) { timeline in
                let sign: Double = isLeft ? 1.0 : -1.0
                let angle = timeline.date.timeIntervalSinceReferenceDate * 3.2 * sign
                DizzySpiralShape(turns: 2.6)
                    .stroke(
                        Color(red: 0.05, green: 0.05, blue: 0.05).opacity(0.92),
                        style: StrokeStyle(lineWidth: unit * 0.0045, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.radians(angle))
            }
            .frame(width: eyeW * 0.80, height: eyeH * 0.78)
            .mask(Ellipse().frame(width: eyeW * 0.94, height: eyeH * 0.94))
            .opacity(Double(dizzyProgress))

            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: palette.eyelidTop, location: 0.00),
                                .init(color: palette.eyelidMid, location: 0.60),
                                .init(color: palette.eyelidBottom, location: 1.00)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(NaiwaLidShape(close: close, isUpper: true, arcRise: arcRise))
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: palette.eyelidTop, location: 0.00),
                                .init(color: palette.eyelidMid, location: 0.60),
                                .init(color: palette.eyelidBottom, location: 1.00)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(NaiwaLidShape(close: close, isUpper: false, arcRise: arcRise))
            }
            .frame(width: lidW, height: lidH)
            .clipShape(Ellipse())

            NaiwaCrescentShape(
                unit: unit,
                squeeze: 0,
                innerOnRight: isLeft,
                thickScale: strongSeam ? 0.55 : 0.42,
                riseScale: 0.55
            )
            .fill(strongSeam
                ? Color.black.opacity(0.88)
                : palette.chinShadowTone.opacity(0.55))
            .frame(
                width: NaiwaLaughSpec.crescentWidth * unit + unit * 0.03,
                height: NaiwaLaughSpec.crescentThick * unit * 3 + unit * 0.03
            )
            .offset(y: seamOffsetY)
            .blur(radius: strongSeam ? 0 : unit * 0.004)
            // Held close: original crisp seam (fades in early). Blink: softened
            // seam that only appears near full closure so it barely registers
            // as the eye sweeps past the low-close range.
            .opacity(strongSeam
                ? Double(min(close * 3, 1))
                : Double(max(0, close - 0.55) / 0.45))
            // 反向旋转抵消容器倾斜：眼睛整体转 eyeTiltDegrees，这里回转，
            // 让黑线净倾斜停在更温和的 seamTiltDegrees，闭眼更好看。
            .rotationEffect(.degrees(
                tilted ? Double(isLeft ? 1 : -1) * (NaiwaFaceSpec.seamTiltDegrees - NaiwaFaceSpec.eyeTiltDegrees) : 0
            ))
        }
        .frame(width: eyeW * 1.8, height: eyeH * 1.7)
        .rotationEffect(.degrees(tilted ? (isLeft ? 1 : -1) * NaiwaFaceSpec.eyeTiltDegrees : 0))
    }
}

// MARK: - Chin Shadow

struct NaiwaChinShadowView: View {
    @Environment(\.naiwaTheme) private var theme
    let unit: CGFloat

    var body: some View {
        let tone = theme.palette.chinShadowTone
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        tone.opacity(0.26),
                        tone.opacity(0.0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: unit * 0.15
                )
            )
            .frame(width: unit * 0.32, height: unit * 0.115)
            .blur(radius: unit * 0.012)
    }
}

// MARK: - Mouth

struct NaiwaReworkMouthView: View {
    @Environment(\.naiwaTheme) private var theme
    let unit: CGFloat

    var body: some View {
        let palette = theme.palette
        let width = NaiwaFaceSpec.mouthWidth * unit
        let lift = NaiwaFaceSpec.mouthCornerLift * unit
        let halfThickness = NaiwaFaceSpec.mouthThickness * unit / 2
        let lipRise = NaiwaFaceSpec.upperLipRise * unit
        let pad = unit * 0.03
        let cornerY = lipRise + pad
        let boxHeight = cornerY + lift + halfThickness * 2 + pad
        let anchorFix = boxHeight / 2 - (cornerY + lift / 2)

        ZStack(alignment: .topLeading) {
            lipTopCurve(width: width, cornerY: cornerY, lift: lift, rise: lipRise)
                .stroke(
                    palette.muzzleGlow.opacity(0.50),
                    style: StrokeStyle(lineWidth: unit * 0.014, lineCap: .round)
                )
                .offset(y: -unit * 0.006)
                .blur(radius: unit * 0.010)
                .mask(horizontalFade(width: width, height: boxHeight))

            lipBand(
                width: width,
                cornerY: cornerY,
                lift: lift,
                rise: lipRise,
                lowerOffset: halfThickness * 0.6
            )
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: NaiwaFaceSpec.upperLipMid.opacity(0.0), location: 0.00),
                        .init(color: NaiwaFaceSpec.upperLipMid.opacity(0.30), location: 0.24),
                        .init(color: NaiwaFaceSpec.upperLipMid.opacity(0.72), location: 0.50),
                        .init(color: NaiwaFaceSpec.upperLipDeep.opacity(0.92), location: 0.82),
                        .init(color: NaiwaFaceSpec.upperLipDeep.opacity(1.0), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blur(radius: unit * 0.0015)

            smileBody(
                width: width,
                cornerY: cornerY,
                lift: lift,
                halfThickness: halfThickness
            )
            .fill(
                LinearGradient(
                    colors: [
                        NaiwaFaceSpec.mouthInk.opacity(0.88),
                        NaiwaFaceSpec.mouthInk
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .offset(y: anchorFix)
        .frame(width: width, height: boxHeight)
    }

    private func lipTopCurve(width: CGFloat, cornerY: CGFloat, lift: CGFloat, rise: CGFloat) -> Path {
        Path { path in
            let dip = NaiwaFaceSpec.upperLipDip / NaiwaFaceSpec.upperLipRise * rise
            let plateauY = cornerY - rise
            path.move(to: CGPoint(x: 0, y: cornerY))
            path.addQuadCurve(
                to: CGPoint(x: width * 0.35, y: plateauY),
                control: CGPoint(x: width * 0.14, y: cornerY + dip * 2.2)
            )
            path.addQuadCurve(
                to: CGPoint(x: width * 0.65, y: plateauY),
                control: CGPoint(x: width * 0.50, y: plateauY - rise * 0.10)
            )
            path.addQuadCurve(
                to: CGPoint(x: width, y: cornerY),
                control: CGPoint(x: width * 0.86, y: cornerY + dip * 2.2)
            )
        }
    }

    private func smileBody(width: CGFloat, cornerY: CGFloat, lift: CGFloat, halfThickness: CGFloat) -> Path {
        Path { path in
            let left = CGPoint(x: 0, y: cornerY)
            let right = CGPoint(x: width, y: cornerY)
            let dipY = cornerY + lift
            let topControl = CGPoint(x: width / 2, y: 2 * (dipY - halfThickness) - cornerY)
            let bottomControl = CGPoint(x: width / 2, y: 2 * (dipY + halfThickness) - cornerY)

            path.move(to: left)
            path.addQuadCurve(to: right, control: topControl)
            path.addQuadCurve(to: left, control: bottomControl)
            path.closeSubpath()
        }
    }

    private func lipBand(
        width: CGFloat,
        cornerY: CGFloat,
        lift: CGFloat,
        rise: CGFloat,
        lowerOffset: CGFloat
    ) -> Path {
        Path { path in
            let dip = NaiwaFaceSpec.upperLipDip / NaiwaFaceSpec.upperLipRise * rise
            let plateauY = cornerY - rise
            let dipY = cornerY + lift

            path.move(to: CGPoint(x: 0, y: cornerY))
            path.addQuadCurve(
                to: CGPoint(x: width * 0.35, y: plateauY),
                control: CGPoint(x: width * 0.14, y: cornerY + dip * 2.2)
            )
            path.addQuadCurve(
                to: CGPoint(x: width * 0.65, y: plateauY),
                control: CGPoint(x: width * 0.50, y: plateauY - rise * 0.10)
            )
            path.addQuadCurve(
                to: CGPoint(x: width, y: cornerY),
                control: CGPoint(x: width * 0.86, y: cornerY + dip * 2.2)
            )
            path.addQuadCurve(
                to: CGPoint(x: 0, y: cornerY),
                control: CGPoint(x: width / 2, y: 2 * (dipY - lowerOffset) - cornerY)
            )
            path.closeSubpath()
        }
    }

    private func horizontalFade(width: CGFloat, height: CGFloat) -> some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.00),
                .init(color: .white, location: 0.20),
                .init(color: .white, location: 0.80),
                .init(color: .clear, location: 1.00)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: width, height: height)
    }
}

// MARK: - Speaking Mouth

/// 说话口型层：读取 SpeechController 的实时开合值，局部刷新（不拖累整脸重绘）。
struct NaiwaSpeakLayer: View {
    let speech: SpeechController
    let unit: CGFloat

    var body: some View {
        NaiwaSpeakMouthView(unit: unit, openness: speech.openness)
            .opacity(speech.isSpeaking ? 1 : 0)
            .animation(.easeInOut(duration: 0.18), value: speech.isSpeaking)
    }
}

/// 从微笑口缝“张开”的小口腔：高度随 openness 变化，配舌头与上齿暗示。
struct NaiwaSpeakMouthView: View {
    @Environment(\.naiwaTheme) private var theme
    let unit: CGFloat
    /// 0 = 闭合（贴合微笑）, 1 = 张到最大
    var openness: CGFloat

    var body: some View {
        let o = min(max(openness, 0), 1)
        let width = NaiwaFaceSpec.mouthWidth * unit * (0.58 + 0.06 * o)
        let minH = unit * 0.008
        let maxH = unit * 0.115
        let height = minH + (maxH - minH) * o
        // 嘴主要向下张开，所以随开合把中心稍微下移
        let dropY = height * 0.28

        ZStack {
            // 口腔
            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: NaiwaLaughSpec.cavityBlack, location: 0.00),
                            .init(color: NaiwaLaughSpec.cavityMid, location: 0.55),
                            .init(color: NaiwaLaughSpec.cavityBottomRed, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)

            // 舌头：张够大才露出，贴在底部
            Ellipse()
                .fill(NaiwaLaughSpec.tongue)
                .frame(width: width * 0.62, height: height * 0.42)
                .offset(y: height * 0.24)
                .opacity(Double(max(0, o - 0.35) / 0.65))
                .blur(radius: unit * 0.002)

            // 上齿暗示：顶部一条白色细带
            Capsule(style: .continuous)
                .fill(NaiwaLaughSpec.toothWhite)
                .frame(width: width * 0.72, height: max(unit * 0.010, height * 0.14))
                .offset(y: -height * 0.40)
                .opacity(Double(min(o * 1.4, 1)))

            // 上唇高光，让张口边缘更柔和
            Ellipse()
                .strokeBorder(theme.palette.muzzleGlow.opacity(0.35), lineWidth: unit * 0.008)
                .frame(width: width, height: height)
                .blur(radius: unit * 0.006)
        }
        .clipShape(Ellipse())
        .frame(width: width, height: height)
        .offset(y: dropY)
    }
}

// MARK: - Belly

struct NaiwaReworkBellyView: View {
    var body: some View {
        GeometryReader { geo in
            let rect = NaiwaFaceSpec.bellyRect(in: geo.size)
            let w = geo.size.width

            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: NaiwaFaceSpec.bellyLight, location: 0.00),
                                .init(color: NaiwaFaceSpec.bellyMid, location: 0.45),
                                .init(color: NaiwaFaceSpec.bellyEdge, location: 1.00)
                            ],
                            center: UnitPoint(x: 0.5, y: 0.16),
                            startRadius: 0,
                            endRadius: rect.width * 0.62
                        )
                    )
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                Ellipse()
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: w * 0.006)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .mask {
                        Rectangle()
                            .frame(height: w * 0.10)
                            .position(x: rect.midX, y: rect.minY + w * 0.03)
                    }
                    .blur(radius: w * 0.006)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Full Face

struct NaiwaReworkFaceView: View {
    var pupilOffset: CGPoint = .zero
    var isLeftEyeClosed = false
    var isRightEyeClosed = false

    var body: some View {
        GeometryReader { geo in
            let unit = NaiwaFaceSpec.featureUnit(for: geo.size)
            let eyes = NaiwaFaceSpec.eyeCenters(in: geo.size)
            let mouth = NaiwaFaceSpec.mouthCenter(in: geo.size)

            ZStack {
                NaiwaReworkSkinView()
                NaiwaReworkBellyView()

                NaiwaChinShadowView(unit: unit)
                    .position(x: mouth.x, y: mouth.y + unit * 0.035)

                NaiwaReworkMouthView(unit: unit)
                    .position(x: mouth.x, y: mouth.y)

                NaiwaReworkEyeView(
                    pupilOffset: pupilOffset,
                    unit: unit,
                    closeAmount: isLeftEyeClosed ? 1 : 0,
                    isLeft: true
                )
                .position(eyes.left)

                NaiwaReworkEyeView(
                    pupilOffset: pupilOffset,
                    unit: unit,
                    closeAmount: isRightEyeClosed ? 1 : 0,
                    isLeft: false
                )
                .position(eyes.right)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Laughing Face

enum NaiwaLaughSpec {
    static let crescentWidth: CGFloat = 0.149
    static let crescentThick: CGFloat = 0.024
    static let crescentRise: CGFloat = 0.021
    static let crescentApexRatio: CGFloat = 0.36
    static let crescentInnerDrop: CGFloat = 0.014
    static let crescentOuterDrop: CGFloat = 0.001
    static let crescentTipRadiusRatio: CGFloat = 0.32
    static let moundDiameter: CGFloat = 0.21
    static let moundWidthRatio: CGFloat = 0.86

    static let mouthTopHalfWidth: CGFloat = 0.183
    static let mouthTopSag: CGFloat = 0.033
    static let mouthMaxDepth: CGFloat = 0.251
    static let mouthCornersRaise: CGFloat = 0.028
    static let toothHeight: CGFloat = 0.056
    static let toothWidth: CGFloat = 0.050
    static let fangLength: CGFloat = 0.100

    static let upperTeethSpan: ClosedRange<CGFloat> = 0.24...0.76
    static let lowerTeethHalfWidthRatio: CGFloat = 0.50
    static let lowerTeethTopDepth: CGFloat = 0.52
    static let lowerTeethBottomDepth: CGFloat = 1.05
    static let lowerTeethFlatness: CGFloat = 0.55

    static let pulseHz: Double = 4.4
    static let wobbleHz: Double = 1.1

    static let cavityBlack = Color(red: 0.02, green: 0.005, blue: 0.005)
    static let cavityTop = Color(red: 0.37, green: 0.27, blue: 0.21)
    static let cavityMid = Color(red: 0.15, green: 0.03, blue: 0.03)
    static let cavityEdge = Color(red: 0.40, green: 0.13, blue: 0.09)
    static let cavityBottomRed = Color(red: 0.46, green: 0.08, blue: 0.09)
    static let tongue = Color(red: 0.52, green: 0.12, blue: 0.13)
    static let toothWhite = Color(red: 0.95, green: 0.93, blue: 0.90)
    static let toothShade = Color(red: 0.76, green: 0.71, blue: 0.66)
    static let moundCore = Color(red: 1.00, green: 0.93, blue: 0.55)
    static let moundLight = Color(red: 0.984, green: 0.875, blue: 0.302)
    static let moundShadow = Color(red: 0.890, green: 0.639, blue: 0.090)
    static let rimShadow = Color(red: 0.62, green: 0.36, blue: 0.05)
    static let rimLight = Color(red: 1.00, green: 0.86, blue: 0.34)
}

struct NaiwaCrescentShape: Shape {
    let unit: CGFloat
    var squeeze: Double
    let innerOnRight: Bool
    var thickScale: CGFloat = 1
    var riseScale: CGFloat = 1

    func path(in rect: CGRect) -> Path {
        let width = NaiwaLaughSpec.crescentWidth * unit
        let rise = NaiwaLaughSpec.crescentRise * unit * riseScale * (1 + 0.10 * squeeze)
        let thick = NaiwaLaughSpec.crescentThick * unit * thickScale
        let offsetTop = thick * 0.62
        let offsetBottom = thick * 0.38
        let tipRadius = thick * NaiwaLaughSpec.crescentTipRadiusRatio
        let innerDrop = NaiwaLaughSpec.crescentInnerDrop * unit
        let outerDrop = NaiwaLaughSpec.crescentOuterDrop * unit
        let centerX = rect.midX
        let baseY = rect.midY + rise * 0.5
        let leftDrop = innerOnRight ? outerDrop : innerDrop
        let rightDrop = innerOnRight ? innerDrop : outerDrop

        let tipLeft = CGPoint(x: centerX - width / 2, y: baseY + leftDrop)
        let tipRight = CGPoint(x: centerX + width / 2, y: baseY + rightDrop)
        let apexX = innerOnRight
            ? tipLeft.x + width * NaiwaLaughSpec.crescentApexRatio
            : tipRight.x - width * NaiwaLaughSpec.crescentApexRatio
        let control = CGPoint(x: apexX, y: baseY - 2 * rise)

        func normalize(_ dx: CGFloat, _ dy: CGFloat) -> CGVector {
            let length = max(sqrt(dx * dx + dy * dy), 0.0001)
            return CGVector(dx: dx / length, dy: dy / length)
        }

        let dirLeft = normalize(control.x - tipLeft.x, control.y - tipLeft.y)
        let dirRight = normalize(control.x - tipRight.x, control.y - tipRight.y)
        let capLeft = CGPoint(
            x: tipLeft.x + dirLeft.dx * tipRadius,
            y: tipLeft.y + dirLeft.dy * tipRadius
        )
        let capRight = CGPoint(
            x: tipRight.x + dirRight.dx * tipRadius,
            y: tipRight.y + dirRight.dy * tipRadius
        )
        let normalLeft = CGVector(dx: -dirLeft.dy, dy: dirLeft.dx)
        let normalRight = CGVector(dx: -dirRight.dy, dy: dirRight.dx)

        func offsetPoint(_ point: CGPoint, _ normal: CGVector, _ distance: CGFloat) -> CGPoint {
            CGPoint(x: point.x + normal.dx * distance, y: point.y + normal.dy * distance)
        }

        let leftA = offsetPoint(capLeft, normalLeft, tipRadius)
        let leftB = offsetPoint(capLeft, normalLeft, -tipRadius)
        let topLeft = leftA.y < leftB.y ? leftA : leftB
        let bottomLeft = leftA.y < leftB.y ? leftB : leftA
        let rightA = offsetPoint(capRight, normalRight, tipRadius)
        let rightB = offsetPoint(capRight, normalRight, -tipRadius)
        let topRight = rightA.y < rightB.y ? rightA : rightB
        let bottomRight = rightA.y < rightB.y ? rightB : rightA

        let baseMidY = (tipLeft.y + tipRight.y) / 2
        let topMidY = baseMidY - rise - offsetTop
        let bottomMidY = baseMidY - rise + offsetBottom
        let controlTop = CGPoint(x: apexX, y: 2 * topMidY - 0.5 * (topLeft.y + topRight.y))
        let controlBottom = CGPoint(x: apexX, y: 2 * bottomMidY - 0.5 * (bottomLeft.y + bottomRight.y))
        let capControlLeft = CGPoint(
            x: capLeft.x - dirLeft.dx * 2 * tipRadius,
            y: capLeft.y - dirLeft.dy * 2 * tipRadius
        )
        let capControlRight = CGPoint(
            x: capRight.x - dirRight.dx * 2 * tipRadius,
            y: capRight.y - dirRight.dy * 2 * tipRadius
        )

        var path = Path()
        path.move(to: topLeft)
        path.addQuadCurve(to: topRight, control: controlTop)
        path.addQuadCurve(to: bottomRight, control: capControlRight)
        path.addQuadCurve(to: bottomLeft, control: controlBottom)
        path.addQuadCurve(to: topLeft, control: capControlLeft)
        path.closeSubpath()
        return path
    }
}

struct NaiwaLaughEyeView: View {
    @Environment(\.naiwaTheme) private var theme
    let unit: CGFloat
    let squeeze: Double
    let isLeft: Bool
    var tilted: Bool = false

    var body: some View {
        let palette = theme.palette
        let mound = NaiwaLaughSpec.moundDiameter * unit
        let moundWidth = mound * NaiwaLaughSpec.moundWidthRatio

        ZStack {
            Ellipse()
                .fill(palette.chinShadowTone.opacity(0.22))
                .frame(width: moundWidth * 0.58, height: mound * 0.13)
                .offset(y: mound * 0.52)
                .blur(radius: unit * 0.012)

            Ellipse()
                .trim(from: 0.06, to: 0.44)
                .stroke(
                    palette.moundShadow.opacity(0.68),
                    style: StrokeStyle(lineWidth: unit * 0.022, lineCap: .round)
                )
                .frame(width: moundWidth * 0.88, height: mound * 0.88)
                .blur(radius: unit * 0.009)

            Ellipse()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: palette.moundCore.opacity(0.95), location: 0.00),
                            .init(color: palette.moundLight.opacity(0.55), location: 0.42),
                            .init(color: .clear, location: 1.0)
                        ],
                        center: UnitPoint(x: isLeft ? 0.44 : 0.56, y: 0.28),
                        startRadius: 0,
                        endRadius: mound * 0.58
                    )
                )
                .frame(width: moundWidth, height: mound)
                .blur(radius: unit * 0.004)

            NaiwaCrescentShape(unit: unit, squeeze: squeeze, innerOnRight: isLeft)
                .fill(Color.black)
                .frame(
                    width: NaiwaLaughSpec.crescentWidth * unit + unit * 0.06,
                    height: (
                        NaiwaLaughSpec.crescentRise * 2
                            + NaiwaLaughSpec.crescentThick * 2
                            + NaiwaLaughSpec.crescentInnerDrop
                    ) * unit + unit * 0.06
                )
        }
        .frame(width: mound * 1.25, height: mound * 1.25)
        .rotationEffect(.degrees(tilted ? (isLeft ? 1 : -1) * NaiwaFaceSpec.eyeTiltDegrees : 0))
    }
}

struct NaiwaLaughMouthShape: Shape {
    let unit: CGFloat
    var jaw: Double

    var animatableData: Double {
        get { jaw }
        set { jaw = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let halfTop = NaiwaLaughSpec.mouthTopHalfWidth * unit
        let sag = NaiwaLaughSpec.mouthTopSag * unit
        let depth = NaiwaLaughSpec.mouthMaxDepth * unit * (0.66 + 0.34 * jaw)
        let centerX = rect.midX
        let cornerY = rect.minY + unit * 0.02
        let left = CGPoint(x: centerX - halfTop, y: cornerY)
        let right = CGPoint(x: centerX + halfTop, y: cornerY)
        let bottom = CGPoint(x: centerX, y: cornerY + depth)

        var path = Path()
        path.move(to: left)
        path.addQuadCurve(to: right, control: CGPoint(x: centerX, y: cornerY + 2 * sag))
        path.addCurve(
            to: bottom,
            control1: CGPoint(x: centerX + halfTop * 1.02, y: cornerY + depth * 0.48),
            control2: CGPoint(x: centerX + halfTop * 0.58, y: cornerY + depth * 1.02)
        )
        path.addCurve(
            to: left,
            control1: CGPoint(x: centerX - halfTop * 0.58, y: cornerY + depth * 1.02),
            control2: CGPoint(x: centerX - halfTop * 1.02, y: cornerY + depth * 0.48)
        )
        path.closeSubpath()
        return path
    }
}

struct NaiwaLaughMouthView: View {
    @Environment(\.naiwaTheme) private var theme
    let unit: CGFloat
    let jaw: Double

    var body: some View {
        let palette = theme.palette
        let boxWidth = NaiwaLaughSpec.mouthTopHalfWidth * 2 * unit + unit * 0.14
        let boxHeight = (NaiwaLaughSpec.mouthMaxDepth + NaiwaLaughSpec.mouthTopSag) * unit + unit * 0.14

        ZStack {
            NaiwaLaughMouthShape(unit: unit, jaw: jaw)
                .stroke(palette.rimShadow.opacity(0.35), lineWidth: unit * 0.020)
                .blur(radius: unit * 0.016)
                .offset(y: unit * 0.034)
                .mask(bottomSidesMask)

            NaiwaLaughMouthShape(unit: unit, jaw: jaw)
                .stroke(palette.rimLight.opacity(0.65), lineWidth: unit * 0.016)
                .blur(radius: unit * 0.008)
                .offset(y: unit * 0.012)
                .mask(bottomSidesMask)

            NaiwaLaughMouthShape(unit: unit, jaw: jaw)
                .stroke(palette.rimLight.opacity(0.55), lineWidth: unit * 0.016)
                .blur(radius: unit * 0.010)
                .offset(y: -unit * 0.024)
                .mask(topMask)

            NaiwaLaughMouthShape(unit: unit, jaw: jaw)
                .stroke(palette.rimShadow.opacity(0.42), lineWidth: unit * 0.018)
                .blur(radius: unit * 0.012)
                .offset(y: -unit * 0.008)
                .mask(topMask)

            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let mouthPath = NaiwaLaughMouthShape(unit: unit, jaw: jaw).path(in: rect)
                let halfTop = NaiwaLaughSpec.mouthTopHalfWidth * unit
                let sag = NaiwaLaughSpec.mouthTopSag * unit
                let depth = NaiwaLaughSpec.mouthMaxDepth * unit * (0.66 + 0.34 * jaw)
                let centerX = rect.midX
                let cornerY = rect.minY + unit * 0.02
                let left = CGPoint(x: centerX - halfTop, y: cornerY)
                let right = CGPoint(x: centerX + halfTop, y: cornerY)
                let topControl = CGPoint(x: centerX, y: cornerY + 2 * sag)

                context.fill(
                    mouthPath,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: NaiwaLaughSpec.cavityBlack, location: 0.00),
                            .init(color: NaiwaLaughSpec.cavityBlack, location: 0.38),
                            .init(color: NaiwaLaughSpec.cavityMid, location: 0.66),
                            .init(color: NaiwaLaughSpec.cavityBottomRed, location: 0.90),
                            .init(color: Color(red: 0.52, green: 0.10, blue: 0.11), location: 1.00)
                        ]),
                        startPoint: CGPoint(x: centerX, y: cornerY),
                        endPoint: CGPoint(x: centerX, y: cornerY + depth)
                    )
                )

                context.drawLayer { layer in
                    layer.clip(to: mouthPath)

                    layer.fill(
                        Path(ellipseIn: CGRect(
                            x: centerX - halfTop * 0.60,
                            y: cornerY + depth * 0.58,
                            width: halfTop * 1.20,
                            height: depth * 0.55
                        )),
                        with: .radialGradient(
                            Gradient(stops: [
                                .init(
                                    color: Color(red: 0.50, green: 0.10, blue: 0.11).opacity(0.85),
                                    location: 0.0
                                ),
                                .init(
                                    color: Color(red: 0.50, green: 0.10, blue: 0.11).opacity(0.0),
                                    location: 1.0
                                )
                            ]),
                            center: CGPoint(x: centerX, y: cornerY + depth * 0.88),
                            startRadius: 0,
                            endRadius: halfTop * 0.85
                        )
                    )

                    func topEdge(_ t: CGFloat) -> (position: CGPoint, angle: CGFloat) {
                        let mt = 1 - t
                        let x = mt * mt * left.x + 2 * mt * t * topControl.x + t * t * right.x
                        let y = mt * mt * left.y + 2 * mt * t * topControl.y + t * t * right.y
                        let dx = 2 * mt * (topControl.x - left.x) + 2 * t * (right.x - topControl.x)
                        let dy = 2 * mt * (topControl.y - left.y) + 2 * t * (right.y - topControl.y)
                        return (CGPoint(x: x, y: y), atan2(dy, dx))
                    }

                    func toothColor(_ norm: CGFloat) -> GraphicsContext.Shading {
                        let factor = Double(min(max(norm, 0), 1)) * 0.9
                        return .color(Color(
                            red: 0.95 - 0.19 * factor,
                            green: 0.93 - 0.22 * factor,
                            blue: 0.90 - 0.24 * factor
                        ))
                    }

                    let lowerHalfWidth = halfTop * NaiwaLaughSpec.lowerTeethHalfWidthRatio
                    let lowerLeft = CGPoint(
                        x: centerX - lowerHalfWidth,
                        y: cornerY + depth * NaiwaLaughSpec.lowerTeethTopDepth
                    )
                    let lowerRight = CGPoint(
                        x: centerX + lowerHalfWidth,
                        y: cornerY + depth * NaiwaLaughSpec.lowerTeethTopDepth
                    )
                    let lowerBottomY = cornerY + depth * NaiwaLaughSpec.lowerTeethBottomDepth
                    let spread = lowerHalfWidth * NaiwaLaughSpec.lowerTeethFlatness
                    let lowerC1 = CGPoint(x: centerX - spread, y: lowerBottomY)
                    let lowerC2 = CGPoint(x: centerX + spread, y: lowerBottomY)
                    func lowerEdge(_ t: CGFloat) -> (position: CGPoint, angle: CGFloat) {
                        let mt = 1 - t
                        let x = mt * mt * mt * lowerLeft.x
                            + 3 * mt * mt * t * lowerC1.x
                            + 3 * mt * t * t * lowerC2.x
                            + t * t * t * lowerRight.x
                        let y = mt * mt * mt * lowerLeft.y
                            + 3 * mt * mt * t * lowerC1.y
                            + 3 * mt * t * t * lowerC2.y
                            + t * t * t * lowerRight.y
                        let dx = 3 * mt * mt * (lowerC1.x - lowerLeft.x)
                            + 6 * mt * t * (lowerC2.x - lowerC1.x)
                            + 3 * t * t * (lowerRight.x - lowerC2.x)
                        let dy = 3 * mt * mt * (lowerC1.y - lowerLeft.y)
                            + 6 * mt * t * (lowerC2.y - lowerC1.y)
                            + 3 * t * t * (lowerRight.y - lowerC2.y)
                        return (CGPoint(x: x, y: y), atan2(dy, dx))
                    }

                    let arcSamples = 64
                    var arcPoints: [CGPoint] = []
                    for index in 0...arcSamples {
                        arcPoints.append(lowerEdge(CGFloat(index) / CGFloat(arcSamples)).position)
                    }
                    var arcCumulative: [CGFloat] = [0]
                    for index in 1...arcSamples {
                        let distance = hypot(
                            arcPoints[index].x - arcPoints[index - 1].x,
                            arcPoints[index].y - arcPoints[index - 1].y
                        )
                        arcCumulative.append(arcCumulative[index - 1] + distance)
                    }
                    let arcTotal = max(arcCumulative[arcSamples], 0.0001)
                    func tForArcFraction(_ fraction: CGFloat) -> CGFloat {
                        let target = fraction * arcTotal
                        var index = 0
                        while index < arcSamples - 1 && arcCumulative[index + 1] < target {
                            index += 1
                        }
                        let segment = arcCumulative[index + 1] - arcCumulative[index]
                        let localFraction = segment > 0 ? (target - arcCumulative[index]) / segment : 0
                        return (CGFloat(index) + localFraction) / CGFloat(arcSamples)
                    }

                    let lowerFractions: [CGFloat] = [0.058, 0.942, 0.178, 0.822, 0.303, 0.697, 0.432, 0.568]
                    for fraction in lowerFractions {
                        let t = tForArcFraction(fraction)
                        let norm = abs(fraction - 0.5) * 2
                        let lowerToothWidth = NaiwaLaughSpec.toothWidth * unit * 0.72 * (1 - 0.20 * norm)
                        let lowerToothHeight = NaiwaLaughSpec.toothHeight * unit * 0.62 * (1 - 0.28 * norm)
                        let (position, angle) = lowerEdge(t)
                        var toothContext = layer
                        toothContext.translateBy(x: position.x, y: position.y)
                        toothContext.rotate(by: Angle(radians: Double(angle)))
                        toothContext.fill(
                            Path(roundedRect: CGRect(
                                x: -lowerToothWidth / 2,
                                y: -lowerToothHeight,
                                width: lowerToothWidth,
                                height: lowerToothHeight
                            ), cornerRadius: lowerToothWidth * 0.35),
                            with: toothColor(norm)
                        )
                    }

                    let span = NaiwaLaughSpec.upperTeethSpan
                    let teethCount = 8
                    let upperBaseHeight = NaiwaLaughSpec.toothHeight * unit * 0.86
                    let upperOrder = [0, 7, 1, 6, 2, 5, 3, 4]
                    for index in upperOrder {
                        let t = span.lowerBound
                            + CGFloat(index) * (span.upperBound - span.lowerBound)
                            / CGFloat(teethCount - 1)
                        let norm = abs(t - 0.5) / ((span.upperBound - span.lowerBound) / 2)
                        let toothWidth = NaiwaLaughSpec.toothWidth * unit * 0.86 * (1 - 0.50 * norm)
                        let (position, angle) = topEdge(t)
                        var toothContext = layer
                        toothContext.translateBy(x: position.x, y: position.y)
                        toothContext.rotate(by: Angle(radians: Double(angle)))

                        if index == 1 || index == 6 {
                            let fangHeight = upperBaseHeight * (1 - 0.56 * norm) * 1.18
                            let halfWidth = toothWidth * 0.62
                            var fang = Path()
                            fang.move(to: CGPoint(x: -halfWidth, y: -unit * 0.008))
                            fang.addLine(to: CGPoint(x: halfWidth, y: -unit * 0.008))
                            fang.addQuadCurve(
                                to: CGPoint(x: halfWidth * 0.06, y: fangHeight),
                                control: CGPoint(x: halfWidth * 0.85, y: fangHeight * 0.55)
                            )
                            fang.addQuadCurve(
                                to: CGPoint(x: -halfWidth, y: -unit * 0.008),
                                control: CGPoint(x: -halfWidth * 0.78, y: fangHeight * 0.55)
                            )
                            fang.closeSubpath()
                            toothContext.fill(fang, with: toothColor(norm))
                        } else {
                            let toothHeight = upperBaseHeight * (1 - 0.56 * norm)
                            toothContext.fill(
                                Path(roundedRect: CGRect(
                                    x: -toothWidth / 2,
                                    y: -unit * 0.008,
                                    width: toothWidth,
                                    height: toothHeight
                                ), cornerRadius: toothWidth * 0.28),
                                with: toothColor(norm)
                            )
                        }
                    }
                }
            }
        }
        .frame(width: boxWidth, height: boxHeight)
    }

    private var bottomSidesMask: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.00),
                .init(color: .clear, location: 0.18),
                .init(color: .white, location: 0.42),
                .init(color: .white, location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topMask: some View {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0.00),
                .init(color: .white, location: 0.22),
                .init(color: .clear, location: 0.45)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Silhouette（角色剪影系统：黑色蒙版 + 轮廓镂空 + 轮廓光）

enum NaiwaSilhouette: String, CaseIterable, Identifiable {
    case block  // 奶块：整块无剪影
    case frog   // 奶蛙：头部轮廓
    case egg    // 奶蛋：蛋形轮廓

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .block: return "奶块"
        case .frog:  return "奶蛙"
        case .egg:   return "奶蛋"
        }
    }

    /// 轮廓点表（nil = 无剪影）
    var profile: [(dy: CGFloat, halfWidth: CGFloat)]? {
        switch self {
        case .block: return nil
        case .frog:  return NaiwaSilhouetteSpec.frogProfile
        case .egg:   return NaiwaSilhouetteSpec.eggProfile
        }
    }

    /// 轮廓顶点相对眼睛中线的偏移（供背景渐变锚定）
    var apexDy: CGFloat? { profile?.first?.dy }
}

enum NaiwaSilhouetteSpec {
    static let scale: CGFloat = 1.0

    /// 点表约定：首行为顶点（halfWidth = 0）；首尾之外的行自上而下；
    /// 末行 halfWidth ≈ 0 → 底部圆顶闭合（奶蛋），否则向屏幕下方溢出（奶蛙）。
    /// dy = 相对眼睛中线的纵向偏移，halfWidth = 半宽，单位均为屏宽。

    /// 奶蛙头部（眼距标定 0.313 图宽 ↔ 0.409 屏宽）
    static let frogProfile: [(dy: CGFloat, halfWidth: CGFloat)] = [
        (-0.238, 0.000),   // 头顶（圆顶由代码生成，故删去原 -0.204 行）
        (-0.157, 0.237),
        (-0.111, 0.282),
        (-0.038, 0.320),
        ( 0.036, 0.339),
        ( 0.110, 0.354),
        ( 0.183, 0.370),
        ( 0.275, 0.397),
        ( 0.367, 0.438),
        ( 0.460, 0.496),
        ( 0.552, 0.568),
        ( 0.616, 0.640),
        ( 0.950, 0.900)    // 溢出屏幕
    ]

    /// 奶蛋（眼距标定 0.253 图宽 ↔ 0.409 屏宽）。
    /// 上半沿用原始测量点；下半与奶蛙一致向屏幕外溢出，不做底部遮罩。
    static let eggProfile: [(dy: CGFloat, halfWidth: CGFloat)] = [
        (-0.273, 0.000),   // 蛋顶
        (-0.123, 0.357),
        (-0.007, 0.458),
        ( 0.110, 0.535),
        ( 0.227, 0.592),
        ( 0.343, 0.635),
        ( 0.460, 0.666),
        ( 0.576, 0.684),   // 近最宽处
        ( 0.950, 0.900)    // 下身溢出屏幕（与奶蛙一致，无底部遮罩）
    ]
}

/// 通用轮廓形状：顶点圆顶（三次曲线，顶部切线水平、曲率连续）
/// + 侧面中点平滑 + 底部圆顶或溢出
struct NaiwaProfileOutlineShape: Shape {
    let profile: [(dy: CGFloat, halfWidth: CGFloat)]

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let cx = rect.midX
        let eyeY = rect.height * NaiwaFaceSpec.eyeLineHeightFraction
        let s = NaiwaSilhouetteSpec.scale
        let apexDy = profile[0].dy

        func pt(_ e: (dy: CGFloat, halfWidth: CGFloat), _ mirrored: Bool) -> CGPoint {
            CGPoint(x: cx + e.halfWidth * w * s * (mirrored ? -1 : 1),
                    y: eyeY + (apexDy + (e.dy - apexDy) * s) * w)
        }

        let closesAtBottom = profile.last!.halfWidth < 0.01
        // 侧面点集：去掉顶点，若底部闭合再去掉底点
        let sideRows = closesAtBottom
            ? Array(profile[1..<(profile.count - 1)])
            : Array(profile.dropFirst())

        let apex = pt(profile[0], false)
        let topShoulderL = pt(sideRows[0], true)
        let topShoulderR = pt(sideRows[0], false)
        // 圆顶控制点：令曲线最高点恰好触及顶点
        // 三次曲线中点 y = (yL + 3yc1 + 3yc2 + yR) / 8
        let topCtrlY = (8 * apex.y - 2 * topShoulderL.y) / 6
        let topCtrlDX = sideRows[0].halfWidth * w * s * 0.42

        var p = Path()
        // 左侧自下而上
        let leftPts = sideRows.reversed().map { pt($0, true) }
        p.move(to: leftPts[0])
        for i in 1..<leftPts.count - 1 {
            let mid = CGPoint(x: (leftPts[i].x + leftPts[i + 1].x) / 2,
                              y: (leftPts[i].y + leftPts[i + 1].y) / 2)
            p.addQuadCurve(to: mid, control: leftPts[i])
        }
        p.addLine(to: topShoulderL)

        // 顶部圆顶
        p.addCurve(to: topShoulderR,
                   control1: CGPoint(x: cx - topCtrlDX, y: topCtrlY),
                   control2: CGPoint(x: cx + topCtrlDX, y: topCtrlY))

        // 右侧自上而下
        let rightPts = sideRows.map { pt($0, false) }
        for i in 1..<rightPts.count - 1 {
            let mid = CGPoint(x: (rightPts[i].x + rightPts[i + 1].x) / 2,
                              y: (rightPts[i].y + rightPts[i + 1].y) / 2)
            p.addQuadCurve(to: mid, control: rightPts[i])
        }
        p.addLine(to: rightPts[rightPts.count - 1])

        if closesAtBottom {
            // 底部圆顶闭合
            let bottomApex = pt(profile[profile.count - 1], false)
            let botShoulder = sideRows[sideRows.count - 1]
            let botCtrlY = (8 * bottomApex.y - 2 * pt(botShoulder, false).y) / 6
            let botCtrlDX = botShoulder.halfWidth * w * s * 0.42
            p.addCurve(to: leftPts[0],
                       control1: CGPoint(x: cx + botCtrlDX, y: botCtrlY),
                       control2: CGPoint(x: cx - botCtrlDX, y: botCtrlY))
        } else {
            // 沿屏幕外溢出闭合
            let overflow = rect.maxY + w * 0.2
            p.addLine(to: CGPoint(x: rightPts[rightPts.count - 1].x, y: overflow))
            p.addLine(to: CGPoint(x: leftPts[0].x, y: overflow))
        }
        p.closeSubpath()
        return p
    }
}

/// 黑色蒙版：全屏挖掉轮廓
struct NaiwaSilhouetteCutoutShape: Shape {
    let style: NaiwaSilhouette

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect.insetBy(dx: -200, dy: -200))
        if let profile = style.profile {
            p.addPath(NaiwaProfileOutlineShape(profile: profile).path(in: rect))
        }
        return p
    }
}

/// 蒙版 + 轮廓光（顶部受光的柔和亮边，给剪影 3D 感）
enum NaiwaSceneBackground: String, CaseIterable, Identifiable {
    case white, black, gray, blue, pink, mint

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .white: return Color(red: 1.00, green: 1.00, blue: 1.00)
        case .black: return Color(red: 0.00, green: 0.00, blue: 0.00)
        case .gray:  return Color(red: 0.90, green: 0.90, blue: 0.92)
        case .blue:  return Color(red: 0.80, green: 0.90, blue: 1.00)
        case .pink:  return Color(red: 1.00, green: 0.86, blue: 0.90)
        case .mint:  return Color(red: 0.83, green: 0.95, blue: 0.87)
        }
    }

    var displayName: String {
        switch self {
        case .white: return "白"
        case .black: return "黑"
        case .gray:  return "灰"
        case .blue:  return "蓝"
        case .pink:  return "粉"
        case .mint:  return "绿"
        }
    }
}

struct NaiwaSilhouetteMaskView: View {
    let style: NaiwaSilhouette
    var backgroundColor: Color = .white

    var body: some View {
        if let profile = style.profile {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    NaiwaSilhouetteCutoutShape(style: style)
                        .fill(backgroundColor, style: FillStyle(eoFill: true))

                    // 轮廓内侧的受光亮边：上强下弱，柔和渐隐
                    NaiwaProfileOutlineShape(profile: profile)
                        .stroke(Color(red: 1.0, green: 0.94, blue: 0.62).opacity(0.55),
                                lineWidth: w * 0.022)
                        .blur(radius: w * 0.018)
                        .clipShape(NaiwaProfileOutlineShape(profile: profile))
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .white,               location: 0.00),
                                    .init(color: .white.opacity(0.55), location: 0.35),
                                    .init(color: .white.opacity(0.15), location: 0.70),
                                    .init(color: .clear,               location: 1.00)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Hairstyle（发型：戴在头顶的装饰层，压在最上层）

enum NaiwaHairstyle: String, CaseIterable, Identifiable {
    case none, ahoge, mohawk, bun, bow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:   return "无"
        case .ahoge:  return "呆毛"
        case .mohawk: return "莫西干"
        case .bun:    return "丸子头"
        case .bow:    return "蝴蝶结"
        }
    }
}

struct NaiwaHairstyleView: View {
    let style: NaiwaHairstyle
    /// 头顶相对眼线的纵向偏移（屏宽单位），发型据此锚定在头顶
    let apexDy: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let cx = w / 2
            let topY = geo.size.height * NaiwaFaceSpec.eyeLineHeightFraction + apexDy * w
            ZStack {
                switch style {
                case .none:   EmptyView()
                case .ahoge:  ahoge(w, cx, topY)
                case .mohawk: mohawk(w, cx, topY)
                case .bun:    bun(w, cx, topY)
                case .bow:    bow(w, cx, topY)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // 呆毛：一根从头顶伸出、俏皮卷翘的细毛
    private func ahoge(_ w: CGFloat, _ cx: CGFloat, _ topY: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: cx - w * 0.015, y: topY + w * 0.03))
            p.addQuadCurve(
                to: CGPoint(x: cx + w * 0.02, y: topY - w * 0.10),
                control: CGPoint(x: cx - w * 0.10, y: topY - w * 0.055)
            )
            p.addQuadCurve(
                to: CGPoint(x: cx + w * 0.105, y: topY - w * 0.185),
                control: CGPoint(x: cx + w * 0.115, y: topY - w * 0.10)
            )
        }
        .stroke(
            LinearGradient(
                colors: [Color(red: 0.30, green: 0.18, blue: 0.10),
                         Color(red: 0.46, green: 0.29, blue: 0.16)],
                startPoint: .bottom, endPoint: .top
            ),
            style: StrokeStyle(lineWidth: w * 0.022, lineCap: .round)
        )
    }

    // 莫西干：一排竖立尖刺，中间最高，品红→紫撞色
    private func mohawk(_ w: CGFloat, _ cx: CGFloat, _ topY: CGFloat) -> some View {
        let spikes = 5
        let spread = w * 0.22
        let baseY = topY + w * 0.02
        let left = cx - spread / 2
        let step = spread / CGFloat(spikes)
        return Path { p in
            p.move(to: CGPoint(x: left, y: baseY))
            for i in 0..<spikes {
                let x0 = left + CGFloat(i) * step
                let mid = x0 + step / 2
                let norm = 1 - abs(CGFloat(i) - CGFloat(spikes - 1) / 2) / (CGFloat(spikes - 1) / 2)
                let tipH = w * (0.10 + 0.13 * norm)
                p.addLine(to: CGPoint(x: mid, y: baseY - tipH))
                p.addLine(to: CGPoint(x: x0 + step, y: baseY))
            }
            p.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.22, blue: 0.45),
                         Color(red: 0.56, green: 0.25, blue: 0.87)],
                startPoint: .leading, endPoint: .trailing
            )
        )
    }

    // 丸子头：头顶一个发髻 + 粉色发带
    private func bun(_ w: CGFloat, _ cx: CGFloat, _ topY: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.50, green: 0.32, blue: 0.18),
                                 Color(red: 0.34, green: 0.20, blue: 0.10)],
                        center: UnitPoint(x: 0.4, y: 0.35),
                        startRadius: 0, endRadius: w * 0.10
                    )
                )
                .frame(width: w * 0.17, height: w * 0.17)
                .position(x: cx, y: topY - w * 0.055)
            Capsule()
                .fill(Color(red: 1.0, green: 0.46, blue: 0.62))
                .frame(width: w * 0.14, height: w * 0.045)
                .position(x: cx, y: topY + w * 0.012)
        }
    }

    // 蝴蝶结：头顶正上方一个粉红蝴蝶结
    private func bow(_ w: CGFloat, _ cx: CGFloat, _ topY: CGFloat) -> some View {
        let by = topY - w * 0.01
        let petal = w * 0.075
        let grad = LinearGradient(
            colors: [Color(red: 1.0, green: 0.50, blue: 0.66),
                     Color(red: 0.96, green: 0.30, blue: 0.50)],
            startPoint: .top, endPoint: .bottom
        )
        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: cx, y: by))
                p.addLine(to: CGPoint(x: cx - petal * 1.4, y: by - petal))
                p.addLine(to: CGPoint(x: cx - petal * 1.4, y: by + petal))
                p.closeSubpath()
            }.fill(grad)
            Path { p in
                p.move(to: CGPoint(x: cx, y: by))
                p.addLine(to: CGPoint(x: cx + petal * 1.4, y: by - petal))
                p.addLine(to: CGPoint(x: cx + petal * 1.4, y: by + petal))
                p.closeSubpath()
            }.fill(grad)
            RoundedRectangle(cornerRadius: w * 0.012)
                .fill(Color(red: 0.90, green: 0.24, blue: 0.44))
                .frame(width: w * 0.03, height: w * 0.05)
                .position(x: cx, y: by)
        }
    }
}

// MARK: - Living Face

struct NaiwaLivingFaceView: View {
    var pupilOffset: CGPoint = .zero
    var isLeftEyeClosed = false
    var isRightEyeClosed = false
    var isLaughing = false
    var isSleeping = false
    var isDrooling = false
    var dizzyProgress: CGFloat = 0
    var backgroundTheme: NaiwaBackgroundTheme = .yellow
    var showBelly: Bool = true
    var silhouette: NaiwaSilhouette = .block
    var tiltedEyes: Bool = false
    var sceneBackground: NaiwaSceneBackground = .white
    var hairstyle: NaiwaHairstyle = .none
    var speech: SpeechController? = nil

    @State private var blink: CGFloat = 0
    @State private var breatheScale: CGFloat = 1.0
    @State private var wobblePhase: Double = 0

    var body: some View {
        GeometryReader { geometry in
            let unit = NaiwaFaceSpec.featureUnit(for: geometry.size)
            let eyes = NaiwaFaceSpec.eyeCenters(in: geometry.size)
            let mouth = NaiwaFaceSpec.mouthCenter(in: geometry.size)
            let progress: CGFloat = isLaughing ? 1 : 0
            let cornersY = mouth.y - NaiwaLaughSpec.mouthCornersRaise * unit
            let boxHeight = (NaiwaLaughSpec.mouthMaxDepth + NaiwaLaughSpec.mouthTopSag) * unit + unit * 0.10
            let laughMouthCenterY = cornersY - unit * 0.02 + boxHeight / 2
            let sleepClose: CGFloat = isSleeping ? 1 : 0
            let closeLeft = max(blink, isLeftEyeClosed ? 1 : 0, sleepClose)
            let closeRight = max(blink, isRightEyeClosed ? 1 : 0, sleepClose)

            // 剪影模式下背景渐变锚定到轮廓顶点
            let skinAnchor: CGFloat = {
                guard let apexDy = silhouette.apexDy else { return 0 }
                let apexY = geometry.size.height * NaiwaFaceSpec.eyeLineHeightFraction
                    + apexDy * geometry.size.width * NaiwaSilhouetteSpec.scale
                return max(0, apexY / geometry.size.height)
            }()

            ZStack {
                // Static skin layer sitting behind everything that can wobble/scale.
                // Fills the corners that get exposed when the wobble group rotates
                // ± 2.5° during dizzy — same gradient as the moving skin, so the
                // seam at the rotating edge is invisible.
                NaiwaReworkSkinView(topAnchor: skinAnchor)

                Group {
                    Group {
                NaiwaReworkSkinView(topAnchor: skinAnchor)
                if showBelly {
                    NaiwaReworkBellyView()
                }

                TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isLaughing)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let pulse = isLaughing ? abs(sin(time * .pi * NaiwaLaughSpec.pulseHz)) : 0
                    let wobble = isLaughing ? sin(time * .pi * 2 * NaiwaLaughSpec.wobbleHz) : 0

                    ZStack {
                        Group {
                            NaiwaChinShadowView(unit: unit)
                                .position(x: mouth.x, y: mouth.y + unit * 0.035)
                            NaiwaReworkMouthView(unit: unit)
                                .position(x: mouth.x, y: mouth.y)
                            if let speech {
                                // 说话口型：叠在微笑之上，随真实语音振幅开合
                                NaiwaSpeakLayer(speech: speech, unit: unit)
                                    .position(x: mouth.x, y: mouth.y)
                            }
                            NaiwaDroolView(unit: unit, isDrooling: isDrooling)
                                .position(
                                    x: mouth.x + NaiwaFaceSpec.mouthWidth * unit * 0.48,
                                    y: mouth.y + unit * 0.028
                                )
                            NaiwaReworkEyeView(
                                pupilOffset: pupilOffset,
                                unit: unit,
                                closeAmount: closeLeft,
                                isLeft: true,
                                dizzyProgress: dizzyProgress,
                                strongSeam: isLeftEyeClosed || isSleeping,
                                tilted: tiltedEyes
                            )
                            .position(eyes.left)
                            .animation(
                                .spring(response: 0.22, dampingFraction: 0.72),
                                value: isLeftEyeClosed
                            )
                            NaiwaReworkEyeView(
                                pupilOffset: pupilOffset,
                                unit: unit,
                                closeAmount: closeRight,
                                isLeft: false,
                                dizzyProgress: dizzyProgress,
                                strongSeam: isRightEyeClosed || isSleeping,
                                tilted: tiltedEyes
                            )
                            .position(eyes.right)
                            .animation(
                                .spring(response: 0.22, dampingFraction: 0.72),
                                value: isRightEyeClosed
                            )
                        }
                        .opacity(1 - progress)
                        .scaleEffect(1 - 0.05 * progress, anchor: UnitPoint(x: 0.5, y: 0.38))

                        Group {
                            // 大笑眼始终水平（不受倾斜眼设置影响）——倾斜后的月牙
                            // 太陡不好看，大笑时回到对称的经典样子。
                            NaiwaLaughEyeView(unit: unit, squeeze: pulse, isLeft: true)
                                .position(eyes.left)
                            NaiwaLaughEyeView(unit: unit, squeeze: pulse, isLeft: false)
                                .position(eyes.right)

                            NaiwaLaughMouthView(unit: unit, jaw: 0.78 + 0.22 * pulse)
                                .position(x: mouth.x, y: laughMouthCenterY)
                        }
                        .opacity(progress)
                        .scaleEffect(0.86 + 0.14 * progress, anchor: UnitPoint(x: 0.5, y: 0.40))
                        .offset(y: -unit * 0.014 * pulse)
                        .rotationEffect(.degrees(wobble * 0.8), anchor: UnitPoint(x: 0.5, y: 0.45))
                    }
                    .animation(.spring(response: 0.30, dampingFraction: 0.72), value: isLaughing)
                }
                }
                .scaleEffect(y: breatheScale, anchor: .bottom)

                    NaiwaDizzyStarsView(unit: unit, dizzyProgress: dizzyProgress)
                        .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.17)
                        .opacity(isLaughing ? 0 : 1)
                        .animation(.easeInOut(duration: 0.35), value: isLaughing)
                        .allowsHitTesting(false)
                }
                .rotationEffect(
                    .degrees(wobblePhase * 2.5 * Double(dizzyProgress)),
                    anchor: .center
                )

                NaiwaSleepZeesView(unit: unit, isSleeping: isSleeping)
                    .position(
                        x: geometry.size.width * 0.62,
                        y: geometry.size.height * 0.19
                    )
                    .opacity(isLaughing ? 0 : 1)
                    .animation(.easeInOut(duration: 0.35), value: isLaughing)
                    .allowsHitTesting(false)

                // 剪影蒙版：压在一切之上（含眩晕摇摆时露出的角落）。放在最外层而
                // 非摇摆组内 —— 角色在固定的"剪影窗口"里摇，轮廓纹丝不动。
                NaiwaSilhouetteMaskView(style: silhouette, backgroundColor: sceneBackground.color)

                // 发型：最顶层装饰，锚定头顶（剪影模式用轮廓顶点，整块模式用默认值）
                NaiwaHairstyleView(style: hairstyle, apexDy: silhouette.apexDy ?? -0.34)
            }
        }
        .ignoresSafeArea()
        .environment(\.naiwaTheme, backgroundTheme)
        .task { await autoBlinkLoop() }
        .task(id: isSleeping) { await breatheLoop() }
        .task(id: dizzyProgress > 0.3) { await wobbleLoop() }
    }

    private func wobbleLoop() async {
        guard dizzyProgress > 0.3 else {
            withAnimation(.easeOut(duration: 0.5)) {
                wobblePhase = 0
            }
            return
        }
        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: 1.25)) {
                wobblePhase = 1
            }
            try? await Task.sleep(nanoseconds: 1_250_000_000)
            guard !Task.isCancelled else { break }
            withAnimation(.easeInOut(duration: 1.25)) {
                wobblePhase = -1
            }
            try? await Task.sleep(nanoseconds: 1_250_000_000)
        }
    }

    private func breatheLoop() async {
        guard isSleeping else {
            withAnimation(.easeOut(duration: 0.6)) {
                breatheScale = 1.0
            }
            return
        }
        while !Task.isCancelled {
            withAnimation(.easeInOut(duration: 2.0)) {
                breatheScale = 1.015
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { break }
            withAnimation(.easeInOut(duration: 2.0)) {
                breatheScale = 1.0
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    private func autoBlinkLoop() async {
        while !Task.isCancelled {
            let wait = Double.random(in: 5.0...10.0)
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            guard !Task.isCancelled else { return }
            guard !isLaughing, !isSleeping, !isLeftEyeClosed, !isRightEyeClosed else { continue }
            await performBlink()
            if Double.random(in: 0...1) < 0.10 {
                try? await Task.sleep(nanoseconds: 160_000_000)
                guard !isLaughing, !isSleeping else { continue }
                await performBlink()
            }
        }
    }

    private func performBlink() async {
        withAnimation(.easeIn(duration: 0.09)) { blink = 1 }
        try? await Task.sleep(nanoseconds: 120_000_000)
        withAnimation(.easeOut(duration: 0.17)) { blink = 0 }
        try? await Task.sleep(nanoseconds: 180_000_000)
    }
}

// MARK: - Sleep Zees

struct NaiwaSleepZeesView: View {
    let unit: CGFloat
    var isSleeping: Bool

    private static let period: Double = 3.2
    private static let count = 3

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isSleeping)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                ForEach(0..<Self.count, id: \.self) { index in
                    let stagger = Double(index) * (Self.period / Double(Self.count))
                    let raw = (now + stagger).truncatingRemainder(dividingBy: Self.period)
                    let phase = raw / Self.period
                    let phaseCG = CGFloat(phase)

                    let riseY = -phaseCG * unit * 0.28
                    let driftX = CGFloat(sin(phase * .pi * 2 + Double(index) * 0.7)) * unit * 0.028
                    let scale = 0.55 + phaseCG * 0.75
                    let fadeIn = min(1, phase * 5)
                    let fadeOut = min(1, (1 - phase) * 3)
                    let opacity = fadeIn * fadeOut

                    Text("Z")
                        .font(.system(size: unit * 0.11, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.72),
                                    Color(red: 0.20, green: 0.14, blue: 0.06).opacity(0.55)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .white.opacity(0.55), radius: 0.5, x: 0, y: 0.5)
                        .scaleEffect(scale)
                        .offset(x: driftX, y: riseY)
                        .opacity(opacity)
                }
            }
        }
        .opacity(isSleeping ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: isSleeping)
    }
}

// MARK: - Sleep Drool

struct DroolTeardropShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let w = rect.width
            let h = rect.height
            let cx = rect.midX
            let bulbCenterY = h * 0.60
            let bulbRadius = min(w / 2, h * 0.38)

            path.move(to: CGPoint(x: cx, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: cx + bulbRadius, y: bulbCenterY),
                control: CGPoint(x: cx + w * 0.44, y: h * 0.34)
            )
            path.addArc(
                center: CGPoint(x: cx, y: bulbCenterY),
                radius: bulbRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false
            )
            path.addQuadCurve(
                to: CGPoint(x: cx, y: 0),
                control: CGPoint(x: cx - w * 0.44, y: h * 0.34)
            )
            path.closeSubpath()
        }
    }
}

struct NaiwaDroolView: View {
    let unit: CGFloat
    var isDrooling: Bool

    private static let period: Double = 5.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isDrooling)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let phase = (now.truncatingRemainder(dividingBy: Self.period)) / Self.period

            let appear = min(1.0, phase / 0.15)
            let sag = max(0.0, min(1.0, (phase - 0.65) / 0.20))
            let fade = 1.0 - max(0.0, (phase - 0.85) / 0.15)

            let bob = CGFloat(sin(phase * .pi * 6)) * unit * 0.0012
            let sagDrift = CGFloat(sag) * unit * 0.010 + bob
            let stretch = 1 + CGFloat(sag) * 0.55
            let opacity = CGFloat(appear) * CGFloat(fade)

            let width = unit * 0.028
            let baseHeight = unit * 0.048
            let height = baseHeight * stretch
            // Keep the drop's tip anchored to the mouth corner while the bulb
            // sags downward — .position centers the frame, so compensate by
            // shifting down by half of the height gained via stretch.
            let anchorFix = (height - baseHeight) / 2

            ZStack {
                DroolTeardropShape()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.87, green: 0.95, blue: 1.0).opacity(0.70), location: 0.00),
                                .init(color: Color(red: 0.60, green: 0.80, blue: 0.97).opacity(0.78), location: 0.55),
                                .init(color: Color(red: 0.42, green: 0.66, blue: 0.90).opacity(0.90), location: 1.00)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        DroolTeardropShape()
                            .stroke(Color.white.opacity(0.55), lineWidth: 0.6)
                            .blur(radius: 0.3)
                    }
                    .overlay {
                        Ellipse()
                            .fill(Color.white.opacity(0.72))
                            .frame(width: width * 0.28, height: height * 0.11)
                            .offset(x: -width * 0.16, y: height * 0.14)
                    }
            }
            .frame(width: width, height: height)
            .offset(y: sagDrift + anchorFix)
            .opacity(opacity)
        }
        .opacity(isDrooling ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: isDrooling)
    }
}

#Preview("Naiwa 1:1 Face v3") {
    NaiwaReworkFaceView()
}

#Preview("Look Down Left") {
    NaiwaReworkFaceView(pupilOffset: CGPoint(x: -1, y: 1))
}

#Preview("Left Eye Closed") {
    NaiwaReworkFaceView(isLeftEyeClosed: true)
}

#Preview("Laughing") {
    NaiwaLivingFaceView(isLaughing: true)
}

#Preview("Sleeping") {
    NaiwaLivingFaceView(isSleeping: true)
}

#Preview("Sleeping + Drooling") {
    NaiwaLivingFaceView(isSleeping: true, isDrooling: true)
}

// MARK: - Dizzy Overlay

struct DizzySpiralShape: Shape {
    var turns: Double = 2.6

    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let maxR = min(rect.width, rect.height) / 2
            let steps = 140
            let coefficient = maxR / (turns * 2 * .pi)

            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let theta = t * turns * 2 * .pi
                let r = coefficient * theta
                let x = center.x + CGFloat(cos(theta)) * r
                let y = center.y + CGFloat(sin(theta)) * r
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

struct NaiwaDizzyStarsView: View {
    let unit: CGFloat
    var dizzyProgress: CGFloat

    private static let count = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: dizzyProgress < 0.02)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let angularVel = 2 * .pi / 3.2

            ZStack {
                ForEach(0..<Self.count, id: \.self) { index in
                    let phase = Double(index) / Double(Self.count)
                    let angle = now * angularVel + phase * 2 * .pi
                    let radiusX = unit * 0.30
                    let radiusY = unit * 0.11
                    let x = CGFloat(cos(angle)) * radiusX
                    let y = CGFloat(sin(angle)) * radiusY - unit * 0.02

                    let scaleBase: CGFloat = index.isMultiple(of: 2) ? 1.0 : 0.72
                    let scale = scaleBase * (0.82 + 0.18 * CGFloat(sin(angle * 2 + Double(index))))

                    let starColor: Color = index.isMultiple(of: 2)
                        ? Color(red: 1.00, green: 0.86, blue: 0.20)
                        : Color(red: 1.00, green: 0.98, blue: 0.86)

                    Image(systemName: "star.fill")
                        .font(.system(size: unit * 0.046))
                        .foregroundStyle(starColor)
                        .shadow(color: .black.opacity(0.20), radius: 0.6, x: 0, y: 0.4)
                        .scaleEffect(scale)
                        .offset(x: x, y: y)
                }
            }
            .frame(width: unit * 0.75, height: unit * 0.32)
            .opacity(Double(dizzyProgress))
        }
    }
}

#Preview("Dizzy") {
    NaiwaLivingFaceView(dizzyProgress: 1)
}

#Preview("Frog Silhouette") {
    NaiwaLivingFaceView(silhouette: .frog)
}

#Preview("Egg Silhouette") {
    NaiwaLivingFaceView(silhouette: .egg)
}
