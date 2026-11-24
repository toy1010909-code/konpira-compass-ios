import SwiftUI

private let accent = Color(red: 1.0, green: 0.35, blue: 0.24)

struct ContentView: View {
    @StateObject private var m = CompassModel()

    private var distanceText: String {
        guard let d = m.distance else { return "--" }
        return d < 1000 ? "約 \(Int(d.rounded())) m" : String(format: "約 %.1f km", d / 1000)
    }

    private var hint: String {
        guard m.distance != nil else { return "" }
        if !m.hasHeading { return "真北から\(Int(m.bearing.rounded()))°の方向" }
        if m.aligned { return "この方向です" }
        return (m.relative > 0 ? "右へ " : "左へ ") + "\(Int(abs(m.relative).rounded()))° 回してください"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 6) {
                Text("安井金比羅宮").font(.headline)
                if let w = m.warning {
                    Text(w)
                        .font(.headline)
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    Text(m.status).font(.caption).foregroundStyle(Color.green.opacity(0.85))
                        .multilineTextAlignment(.center)
                } else {
                    Text(m.status).font(.caption).foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                Dial(m: m)
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                Text(m.hasLocation ? "\(Int(m.bearing.rounded()))°" : "--°")
                    .font(.system(size: 56, weight: .ultraLight))
                Text(distanceText).font(.title3)
                Text(hint)
                    .font(.subheadline)
                    .foregroundStyle(m.aligned ? Color.green : Color.gray)
                Spacer(minLength: 0)
            }
            .padding()
            .foregroundStyle(.white)
        }
        .preferredColorScheme(.dark)
        .onAppear { m.start() }
    }
}

struct Dial: View {
    @ObservedObject var m: CompassModel

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            let r = s / 2
            ZStack {
                // 回転するダイヤル
                ZStack {
                    ForEach(0..<72, id: \.self) { i in
                        let major = i % 6 == 0
                        Rectangle()
                            .fill(major ? Color.white : Color.gray)
                            .frame(width: major ? 2.5 : 1, height: major ? 14 : 7)
                            .offset(y: -(r - (major ? 7 : 3.5)))
                            .rotationEffect(.degrees(Double(i) * 5))
                    }
                    ForEach(Array(["北", "東", "南", "西"].enumerated()), id: \.offset) { i, t in
                        Text(t)
                            .font(.title2.bold())
                            .foregroundStyle(i == 0 ? Color.red : Color.white)
                            .offset(y: -(r - 42))
                            .rotationEffect(.degrees(Double(i) * 90))
                    }
                    ZStack {
                        Circle().fill(accent).frame(width: 28, height: 28)
                        Text("金").font(.caption.bold()).foregroundStyle(.white)
                    }
                    .offset(y: -(r - 4))
                    .rotationEffect(.degrees(m.bearing))
                    .opacity(m.hasLocation ? 1 : 0)
                }
                .rotationEffect(.degrees(m.ringAngle))

                // 固定の指標（端末の正面）
                Triangle()
                    .fill(Color.white)
                    .frame(width: 16, height: 12)
                    .offset(y: -(r + 10))

                // 目的地を指す矢印
                ArrowShape()
                    .fill(m.aligned ? Color.green : accent)
                    .frame(width: s * 0.6, height: s * 0.6)
                    .rotationEffect(.degrees(m.arrowAngle))
                    .opacity(m.hasLocation ? 1 : 0.15)

                Circle().fill(Color.black).frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            }
            .frame(width: s, height: s)
            .animation(.easeOut(duration: 0.15), value: m.ringAngle)
            .animation(.easeOut(duration: 0.15), value: m.arrowAngle)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let l = rect.height * 0.5
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - l))
        p.addLine(to: CGPoint(x: c.x + l * 0.24, y: c.y + l * 0.16))
        p.addLine(to: c)
        p.addLine(to: CGPoint(x: c.x - l * 0.24, y: c.y + l * 0.16))
        p.closeSubpath()
        return p
    }
}
