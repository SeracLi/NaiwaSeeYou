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

    static let irisBright = Color(red: 0.510, green: 0.816, blue: 0.561)
    static let irisMid = Color(red: 0.376, green: 0.698, blue: 0.384)
    static let irisDeep = Color(red: 0.286, green: 0.588, blue: 0.259)
    static let irisRim = Color(red: 0.098, green: 0.216, blue: 0.118)

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
        return nil
    }
}

// MARK: - Skin

struct NaiwaReworkSkinView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: NaiwaFaceSpec.skinTop, location: 0.00),
                        .init(color: NaiwaFaceSpec.skinUpperMid, location: 0.30),
                        .init(color: NaiwaFaceSpec.skinLowerMid, location: 0.55),
                        .init(color: NaiwaFaceSpec.skinChest, location: 0.80),
                        .init(color: NaiwaFaceSpec.skinChest, location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [Color.white.opacity(0.10), .clear],
                    center: UnitPoint(x: 0.5, y: 0.10),
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

struct NaiwaReworkEyeView: View {
    let pupilOffset: CGPoint
    let unit: CGFloat
    let isClosed: Bool

    var body: some View {
        let eyeW = NaiwaFaceSpec.eyeWidth * unit
        let eyeH = NaiwaFaceSpec.eyeHeight * unit
        let clamped = NaiwaFaceSpec.clampedPupilVector(pupilOffset)
        let drop = NaiwaFaceSpec.pupilRestingDrop * unit * (1 - abs(clamped.y))

        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: NaiwaFaceSpec.eyeProtrusionGlow.opacity(0.0), location: 0.00),
                            .init(color: NaiwaFaceSpec.eyeProtrusionGlow.opacity(0.55), location: 0.52),
                            .init(color: NaiwaFaceSpec.eyeProtrusionGlow.opacity(0.0), location: 1.00)
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

            eyelid(eyeW: eyeW, eyeH: eyeH)
                .scaleEffect(y: isClosed ? 1 : 0.001, anchor: .top)
                .opacity(isClosed ? 1 : 0)
        }
        .frame(width: eyeW * 1.8, height: eyeH * 1.7)
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isClosed)
    }

    private func eyelid(eyeW: CGFloat, eyeH: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            NaiwaFaceSpec.skinUpperMid,
                            Color(red: 0.95, green: 0.68, blue: 0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: eyeW * 1.06, height: eyeH * 1.06)

            Canvas { context, size in
                var crease = Path()
                crease.move(to: CGPoint(x: size.width * 0.16, y: size.height * 0.5))
                crease.addQuadCurve(
                    to: CGPoint(x: size.width * 0.84, y: size.height * 0.5),
                    control: CGPoint(x: size.width * 0.5, y: size.height * 0.68)
                )
                context.stroke(
                    crease,
                    with: .color(NaiwaFaceSpec.mouthInk.opacity(0.82)),
                    style: StrokeStyle(lineWidth: unit * 0.009, lineCap: .round)
                )
            }
            .frame(width: eyeW * 0.85, height: eyeH * 0.5)
        }
    }
}

// MARK: - Chin Shadow

struct NaiwaChinShadowView: View {
    let unit: CGFloat

    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        NaiwaFaceSpec.chinShadowTone.opacity(0.26),
                        NaiwaFaceSpec.chinShadowTone.opacity(0.0)
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
    let unit: CGFloat

    var body: some View {
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
                    NaiwaFaceSpec.muzzleGlow.opacity(0.50),
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
                    isClosed: isLeftEyeClosed
                )
                .position(eyes.left)

                NaiwaReworkEyeView(
                    pupilOffset: pupilOffset,
                    unit: unit,
                    isClosed: isRightEyeClosed
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
    static let crescentRise: CGFloat = 0.025
    static let crescentInnerDrop: CGFloat = 0.016
    static let crescentOuterDrop: CGFloat = 0.004
    static let moundDiameter: CGFloat = 0.21

    static let mouthTopHalfWidth: CGFloat = 0.183
    static let mouthTopSag: CGFloat = 0.033
    static let mouthMaxDepth: CGFloat = 0.251
    static let mouthCornersRaise: CGFloat = 0.040
    static let toothHeight: CGFloat = 0.056
    static let toothWidth: CGFloat = 0.050
    static let fangLength: CGFloat = 0.100

    static let upperTeethSpan: ClosedRange<CGFloat> = 0.24...0.76
    static let lowerTeethHalfWidthRatio: CGFloat = 0.62
    static let lowerTeethTopDepth: CGFloat = 0.62

    static let pulseHz: Double = 4.4
    static let wobbleHz: Double = 1.1

    static let cavityBlack = Color(red: 0.02, green: 0.005, blue: 0.005)
    static let cavityTop = Color(red: 0.37, green: 0.27, blue: 0.21)
    static let cavityMid = Color(red: 0.15, green: 0.03, blue: 0.03)
    static let cavityEdge = Color(red: 0.40, green: 0.13, blue: 0.09)
    static let cavityBottomRed = Color(red: 0.46, green: 0.08, blue: 0.09)
    static let tongue = Color(red: 0.52, green: 0.12, blue: 0.13)
    static let toothWhite = Color(red: 0.95, green: 0.93, blue: 0.90)
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

    func path(in rect: CGRect) -> Path {
        let width = NaiwaLaughSpec.crescentWidth * unit
        let rise = NaiwaLaughSpec.crescentRise * unit * (1 + 0.12 * squeeze)
        let thickness = NaiwaLaughSpec.crescentThick * unit
        let innerDrop = NaiwaLaughSpec.crescentInnerDrop * unit
        let outerDrop = NaiwaLaughSpec.crescentOuterDrop * unit
        let centerX = rect.midX
        let baseY = rect.midY + rise * 0.5
        let leftDrop = innerOnRight ? outerDrop : innerDrop
        let rightDrop = innerOnRight ? innerDrop : outerDrop
        let left = CGPoint(x: centerX - width / 2, y: baseY + leftDrop)
        let right = CGPoint(x: centerX + width / 2, y: baseY + rightDrop)
        let endInset = thickness * 0.46
        let endHalfHeight = thickness * 0.24
        let topLeft = CGPoint(x: left.x + endInset, y: left.y - endHalfHeight)
        let bottomLeft = CGPoint(x: left.x + endInset * 0.92, y: left.y + endHalfHeight)
        let topRight = CGPoint(x: right.x - endInset, y: right.y - endHalfHeight)
        let bottomRight = CGPoint(x: right.x - endInset * 0.92, y: right.y + endHalfHeight)

        var path = Path()
        path.move(to: topLeft)
        path.addCurve(
            to: topRight,
            control1: CGPoint(x: centerX - width * 0.34, y: baseY - 2 * rise - thickness * 0.72),
            control2: CGPoint(x: centerX + width * 0.34, y: baseY - 2 * rise - thickness * 0.72)
        )
        path.addQuadCurve(
            to: bottomRight,
            control: CGPoint(x: right.x - endInset * 0.08, y: right.y)
        )
        path.addCurve(
            to: bottomLeft,
            control1: CGPoint(x: centerX + width * 0.32, y: baseY - 2 * rise + thickness * 0.58),
            control2: CGPoint(x: centerX - width * 0.32, y: baseY - 2 * rise + thickness * 0.58)
        )
        path.addQuadCurve(
            to: topLeft,
            control: CGPoint(x: left.x + endInset * 0.08, y: left.y)
        )
        path.closeSubpath()
        return path
    }
}

struct NaiwaLaughEyeView: View {
    let unit: CGFloat
    let squeeze: Double
    let isLeft: Bool

    var body: some View {
        let mound = NaiwaLaughSpec.moundDiameter * unit

        ZStack {
            Ellipse()
                .fill(Color(red: 0.55, green: 0.32, blue: 0.05).opacity(0.30))
                .frame(width: mound * 0.72, height: mound * 0.26)
                .offset(y: mound * 0.48)
                .blur(radius: unit * 0.014)

            Ellipse()
                .fill(NaiwaLaughSpec.moundShadow.opacity(0.72))
                .frame(width: mound * 0.62, height: mound * 0.30)
                .offset(y: mound * 0.36)
                .blur(radius: unit * 0.010)

            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: NaiwaLaughSpec.moundCore.opacity(0.95), location: 0.00),
                            .init(color: NaiwaLaughSpec.moundLight.opacity(0.55), location: 0.42),
                            .init(color: .clear, location: 1.0)
                        ],
                        center: UnitPoint(x: isLeft ? 0.44 : 0.56, y: 0.28),
                        startRadius: 0,
                        endRadius: mound * 0.58
                    )
                )
                .frame(width: mound, height: mound)
                .blur(radius: unit * 0.004)

            NaiwaCrescentShape(unit: unit, squeeze: squeeze, innerOnRight: isLeft)
                .fill(Color.black)
                .frame(
                    width: NaiwaLaughSpec.crescentWidth * unit + unit * 0.03,
                    height: (
                        NaiwaLaughSpec.crescentRise * 2
                            + NaiwaLaughSpec.crescentThick
                            + NaiwaLaughSpec.crescentInnerDrop
                    ) * unit + unit * 0.03
                )
        }
        .frame(width: mound * 1.25, height: mound * 1.25)
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
    let unit: CGFloat
    let jaw: Double

    var body: some View {
        let boxWidth = NaiwaLaughSpec.mouthTopHalfWidth * 2 * unit + unit * 0.14
        let boxHeight = (NaiwaLaughSpec.mouthMaxDepth + NaiwaLaughSpec.mouthTopSag) * unit + unit * 0.14

        ZStack {
            NaiwaLaughMouthShape(unit: unit, jaw: jaw)
                .stroke(NaiwaLaughSpec.rimShadow.opacity(0.35), lineWidth: unit * 0.020)
                .blur(radius: unit * 0.016)
                .offset(y: unit * 0.034)
                .mask(bottomSidesMask)

            NaiwaLaughMouthShape(unit: unit, jaw: jaw)
                .stroke(NaiwaLaughSpec.rimLight.opacity(0.65), lineWidth: unit * 0.016)
                .blur(radius: unit * 0.008)
                .offset(y: unit * 0.012)
                .mask(bottomSidesMask)

            NaiwaLaughMouthShape(unit: unit, jaw: jaw)
                .stroke(NaiwaLaughSpec.rimShadow.opacity(0.42), lineWidth: unit * 0.018)
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
                            .init(color: NaiwaLaughSpec.cavityBlack, location: 0.30),
                            .init(color: NaiwaLaughSpec.cavityMid, location: 0.62),
                            .init(color: NaiwaLaughSpec.cavityBottomRed, location: 1.00)
                        ]),
                        startPoint: CGPoint(x: centerX, y: cornerY),
                        endPoint: CGPoint(x: centerX, y: cornerY + depth)
                    )
                )

                context.drawLayer { layer in
                    layer.clip(to: mouthPath)

                    layer.fill(
                        Path(ellipseIn: CGRect(
                            x: centerX - halfTop * 0.46,
                            y: cornerY + depth * 0.62,
                            width: halfTop * 0.92,
                            height: depth * 0.40
                        )),
                        with: .color(NaiwaLaughSpec.tongue)
                    )

                    func topEdge(_ t: CGFloat) -> (position: CGPoint, angle: CGFloat) {
                        let mt = 1 - t
                        let x = mt * mt * left.x + 2 * mt * t * topControl.x + t * t * right.x
                        let y = mt * mt * left.y + 2 * mt * t * topControl.y + t * t * right.y
                        let dx = 2 * mt * (topControl.x - left.x) + 2 * t * (right.x - topControl.x)
                        let dy = 2 * mt * (topControl.y - left.y) + 2 * t * (right.y - topControl.y)
                        return (CGPoint(x: x, y: y), atan2(dy, dx))
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
                    let lowerControl = CGPoint(x: centerX, y: cornerY + depth * 1.08)
                    func lowerEdge(_ t: CGFloat) -> (position: CGPoint, angle: CGFloat) {
                        let mt = 1 - t
                        let x = mt * mt * lowerLeft.x + 2 * mt * t * lowerControl.x + t * t * lowerRight.x
                        let y = mt * mt * lowerLeft.y + 2 * mt * t * lowerControl.y + t * t * lowerRight.y
                        let dx = 2 * mt * (lowerControl.x - lowerLeft.x) + 2 * t * (lowerRight.x - lowerControl.x)
                        let dy = 2 * mt * (lowerControl.y - lowerLeft.y) + 2 * t * (lowerRight.y - lowerControl.y)
                        return (CGPoint(x: x, y: y), atan2(dy, dx))
                    }

                    for t in [CGFloat(0.06), CGFloat(0.20), CGFloat(0.35), CGFloat(0.50), CGFloat(0.65), CGFloat(0.80), CGFloat(0.94)] {
                        let norm = abs(t - 0.5) * 2
                        let lowerToothWidth = NaiwaLaughSpec.toothWidth * unit * 0.72 * (1 - 0.30 * norm)
                        let lowerToothHeight = NaiwaLaughSpec.toothHeight * unit * 0.66 * (1 - 0.28 * norm)
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
                            with: .color(NaiwaLaughSpec.toothWhite)
                        )
                    }

                    let span = NaiwaLaughSpec.upperTeethSpan
                    let teethCount = 8
                    for index in 0..<teethCount {
                        let t = span.lowerBound
                            + CGFloat(index) * (span.upperBound - span.lowerBound)
                            / CGFloat(teethCount - 1)
                        let norm = abs(t - 0.5) / ((span.upperBound - span.lowerBound) / 2)
                        let toothWidth = NaiwaLaughSpec.toothWidth * unit * 0.86 * (1 - 0.48 * norm)
                        let toothHeight = NaiwaLaughSpec.toothHeight * unit * (1 - 0.42 * norm)
                        let (position, angle) = topEdge(t)
                        var toothContext = layer
                        toothContext.translateBy(x: position.x, y: position.y)
                        toothContext.rotate(by: Angle(radians: Double(angle)))
                        toothContext.fill(
                            Path(roundedRect: CGRect(
                                x: -toothWidth / 2,
                                y: -unit * 0.008,
                                width: toothWidth,
                                height: toothHeight
                            ), cornerRadius: toothWidth * 0.28),
                            with: .color(NaiwaLaughSpec.toothWhite)
                        )
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

struct NaiwaLivingFaceView: View {
    var pupilOffset: CGPoint = .zero
    var isLeftEyeClosed = false
    var isRightEyeClosed = false
    var isLaughing = false

    var body: some View {
        GeometryReader { geometry in
            let unit = NaiwaFaceSpec.featureUnit(for: geometry.size)
            let eyes = NaiwaFaceSpec.eyeCenters(in: geometry.size)
            let mouth = NaiwaFaceSpec.mouthCenter(in: geometry.size)
            let progress: CGFloat = isLaughing ? 1 : 0
            let cornersY = mouth.y - NaiwaLaughSpec.mouthCornersRaise * unit
            let boxHeight = (NaiwaLaughSpec.mouthMaxDepth + NaiwaLaughSpec.mouthTopSag) * unit + unit * 0.10
            let laughMouthCenterY = cornersY - unit * 0.02 + boxHeight / 2

            ZStack {
                NaiwaReworkSkinView()
                NaiwaReworkBellyView()

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
                            NaiwaReworkEyeView(
                                pupilOffset: pupilOffset,
                                unit: unit,
                                isClosed: isLeftEyeClosed
                            )
                            .position(eyes.left)
                            NaiwaReworkEyeView(
                                pupilOffset: pupilOffset,
                                unit: unit,
                                isClosed: isRightEyeClosed
                            )
                            .position(eyes.right)
                        }
                        .opacity(1 - progress)
                        .scaleEffect(1 - 0.05 * progress, anchor: UnitPoint(x: 0.5, y: 0.38))

                        Group {
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
        }
        .ignoresSafeArea()
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
