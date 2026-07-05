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
    static let eyelidTop = Color(red: 1.000, green: 0.815, blue: 0.290)
    static let eyelidBottom = Color(red: 0.985, green: 0.700, blue: 0.190)

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
    var closeAmount: CGFloat = 0
    var isLeft: Bool = true

    var body: some View {
        let eyeW = NaiwaFaceSpec.eyeWidth * unit
        let eyeH = NaiwaFaceSpec.eyeHeight * unit
        let clamped = NaiwaFaceSpec.clampedPupilVector(pupilOffset)
        let drop = NaiwaFaceSpec.pupilRestingDrop * unit * (1 - abs(clamped.y))
        let close = min(max(closeAmount, 0), 1)

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

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [NaiwaFaceSpec.eyelidTop, NaiwaFaceSpec.eyelidBottom],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: eyeW * 1.08, height: eyeH * 1.08)
                .scaleEffect(y: max(close, 0.001), anchor: .top)

            NaiwaCrescentShape(
                unit: unit,
                squeeze: 0,
                innerOnRight: isLeft,
                thickScale: 0.55,
                riseScale: 0.55
            )
            .fill(Color.black.opacity(0.88))
            .frame(
                width: NaiwaLaughSpec.crescentWidth * unit + unit * 0.03,
                height: NaiwaLaughSpec.crescentThick * unit * 3 + unit * 0.03
            )
            .offset(y: eyeH * 0.34)
            .opacity(Double(close * close * close))
        }
        .frame(width: eyeW * 1.8, height: eyeH * 1.7)
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
    let unit: CGFloat
    let squeeze: Double
    let isLeft: Bool

    var body: some View {
        let mound = NaiwaLaughSpec.moundDiameter * unit
        let moundWidth = mound * NaiwaLaughSpec.moundWidthRatio

        ZStack {
            Ellipse()
                .fill(Color(red: 0.55, green: 0.32, blue: 0.05).opacity(0.22))
                .frame(width: moundWidth * 0.58, height: mound * 0.13)
                .offset(y: mound * 0.52)
                .blur(radius: unit * 0.012)

            Ellipse()
                .trim(from: 0.06, to: 0.44)
                .stroke(
                    NaiwaLaughSpec.moundShadow.opacity(0.68),
                    style: StrokeStyle(lineWidth: unit * 0.022, lineCap: .round)
                )
                .frame(width: moundWidth * 0.88, height: mound * 0.88)
                .blur(radius: unit * 0.009)

            Ellipse()
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
                .stroke(NaiwaLaughSpec.rimLight.opacity(0.55), lineWidth: unit * 0.016)
                .blur(radius: unit * 0.010)
                .offset(y: -unit * 0.024)
                .mask(topMask)

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

                    let lowerFractions: [CGFloat] = [0.060, 0.940, 0.186, 0.814, 0.311, 0.689, 0.437, 0.563]
                    for fraction in lowerFractions {
                        let t = tForArcFraction(fraction)
                        let norm = abs(fraction - 0.5) * 2
                        let lowerToothWidth = NaiwaLaughSpec.toothWidth * unit * 0.72 * (1 - 0.30 * norm)
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
                        let toothHeight = upperBaseHeight * (1 - 0.56 * norm)
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
                            with: toothColor(norm)
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

    @State private var blink: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let unit = NaiwaFaceSpec.featureUnit(for: geometry.size)
            let eyes = NaiwaFaceSpec.eyeCenters(in: geometry.size)
            let mouth = NaiwaFaceSpec.mouthCenter(in: geometry.size)
            let progress: CGFloat = isLaughing ? 1 : 0
            let cornersY = mouth.y - NaiwaLaughSpec.mouthCornersRaise * unit
            let boxHeight = (NaiwaLaughSpec.mouthMaxDepth + NaiwaLaughSpec.mouthTopSag) * unit + unit * 0.10
            let laughMouthCenterY = cornersY - unit * 0.02 + boxHeight / 2
            let closeLeft = max(blink, isLeftEyeClosed ? 1 : 0)
            let closeRight = max(blink, isRightEyeClosed ? 1 : 0)

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
                                closeAmount: closeLeft,
                                isLeft: true
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
                                isLeft: false
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
        .task { await autoBlinkLoop() }
    }

    private func autoBlinkLoop() async {
        while !Task.isCancelled {
            let wait = Double.random(in: 2.2...5.8)
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            guard !Task.isCancelled else { return }
            guard !isLaughing, !isLeftEyeClosed, !isRightEyeClosed else { continue }
            await performBlink()
            if Double.random(in: 0...1) < 0.18 {
                try? await Task.sleep(nanoseconds: 160_000_000)
                guard !isLaughing else { continue }
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
