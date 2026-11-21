import Foundation

/// An 8-bit-per-channel sRGB color: exactly what gets copied as hex.
struct HexColor: Hashable, Sendable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }

    /// Parses `eb5244`, `#EB5244`, or the same with surrounding whitespace.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6,
              s.allSatisfy(\.isHexDigit),
              let value = UInt32(s, radix: 16) else { return nil }
        self.init(
            r: UInt8((value >> 16) & 0xFF),
            g: UInt8((value >> 8) & 0xFF),
            b: UInt8(value & 0xFF)
        )
    }

    /// Canonical storage form: six uppercase hex digits, no `#`.
    var canonical: String {
        String(format: "%02X%02X%02X", r, g, b)
    }

    // MARK: - RGB

    var rgbString: String { "rgb(\(r), \(g), \(b))" }

    // MARK: - CMYK

    struct CMYK: Equatable, Sendable {
        let c: Int
        let m: Int
        let y: Int
        let k: Int
    }

    /// Standard screen-to-CMYK conversion, as whole percentages.
    /// It doesn't use an ICC print profile.
    var cmyk: CMYK {
        let rf = Double(r) / 255
        let gf = Double(g) / 255
        let bf = Double(b) / 255
        let k = 1 - max(rf, gf, bf)
        guard k < 1 else { return CMYK(c: 0, m: 0, y: 0, k: 100) }
        func pct(_ x: Double) -> Int { Int((x * 100).rounded()) }
        return CMYK(
            c: pct((1 - rf - k) / (1 - k)),
            m: pct((1 - gf - k) / (1 - k)),
            y: pct((1 - bf - k) / (1 - k)),
            k: pct(k)
        )
    }

    var cmykString: String {
        let v = cmyk
        return "cmyk(\(v.c)%, \(v.m)%, \(v.y)%, \(v.k)%)"
    }
}

/// How hex values are written when copied or shown.
struct HexFormat: Equatable, Sendable {
    var includeHash: Bool
    var uppercase: Bool

    func string(_ color: HexColor) -> String {
        let digits = uppercase ? color.canonical : color.canonical.lowercased()
        return includeHash ? "#" + digits : digits
    }

    /// The format currently chosen in Settings.
    static var current: HexFormat {
        let d = UserDefaults.standard
        return HexFormat(
            includeHash: d.bool(forKey: SettingsKey.includeHash),
            uppercase: d.bool(forKey: SettingsKey.uppercase)
        )
    }
}
