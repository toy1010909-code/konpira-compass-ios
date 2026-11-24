import SwiftUI
import CoreLocation

final class CompassModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    /// 安井金比羅宮
    static let target = CLLocationCoordinate2D(latitude: 34.999917, longitude: 135.775778)

    @Published var ringAngle: Double = 0     // ダイヤルの回転（連続値）
    @Published var arrowAngle: Double = 0    // 矢印の回転（連続値）
    @Published var bearing: Double = 0       // 現在地から見た目的地の方位（真北基準）
    @Published var relative: Double = 0      // 端末の向きから見た角度（-180〜180）
    @Published var distance: Double? = nil   // m
    @Published var hasHeading = false
    @Published var aligned = false
    @Published var status = "位置情報を取得中…"
    @Published var warning: String? = nil    // 位置情報が使えないときの警告
    @Published var hasLocation = false

    private let lm = CLLocationManager()
    private var coord: CLLocationCoordinate2D?
    private var heading: Double = 0
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    override init() {
        super.init()
        lm.delegate = self
        lm.desiredAccuracy = kCLLocationAccuracyBest
        lm.headingFilter = 1
        lm.headingOrientation = .portrait
    }

    func start() {
        lm.requestWhenInUseAuthorization()
        lm.startUpdatingLocation()
        if CLLocationManager.headingAvailable() { lm.startUpdatingHeading() }
    }

    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        coord = l.coordinate
        hasLocation = true
        warning = nil
        status = "現在地を取得（誤差 約\(Int(max(0, l.horizontalAccuracy))) m）"
        recompute()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 一度も取得できていないときだけ警告する（一時的な失敗は直前の位置を使い続ける）
        if coord == nil { setUnavailable() }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted:
            coord = nil
            setUnavailable()
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        hasHeading = true
        recompute()
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }

    // MARK: 計算
    private func setUnavailable() {
        hasLocation = false
        distance = nil
        aligned = false
        warning = "位置情報が取得できません"
        status = "設定で位置情報の使用を許可してください"
    }

    private func recompute() {
        guard let c = coord else { return }
        let b = Self.bearing(from: c, to: Self.target)
        bearing = b
        distance = CLLocation(latitude: c.latitude, longitude: c.longitude)
            .distance(from: CLLocation(latitude: Self.target.latitude, longitude: Self.target.longitude))

        let h = hasHeading ? heading : 0
        ringAngle = Self.unwrap(prev: ringAngle, target: -h)
        arrowAngle = Self.unwrap(prev: arrowAngle, target: b - h)

        let rel = (b - h + 540).truncatingRemainder(dividingBy: 360) - 180
        relative = rel
        let now = hasHeading && abs(rel) < 8
        if now && !aligned { haptic.impactOccurred() }
        aligned = now
    }

    private static func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let f1 = a.latitude * .pi / 180, f2 = b.latitude * .pi / 180
        let dl = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dl) * cos(f2)
        let x = cos(f1) * sin(f2) - sin(f1) * cos(f2) * cos(dl)
        let deg = atan2(y, x) * 180 / .pi
        return (deg + 360).truncatingRemainder(dividingBy: 360)
    }

    /// 359°→0°をまたいでも逆回転しないよう、連続した角度にする
    private static func unwrap(prev: Double, target: Double) -> Double {
        let d = ((target - prev).truncatingRemainder(dividingBy: 360) + 540).truncatingRemainder(dividingBy: 360) - 180
        return prev + d
    }
}
