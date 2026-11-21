import Testing
@testable import BoltPicker

struct HexColorTests {
    let red = HexColor(r: 0xEB, g: 0x52, b: 0x44)

    @Test func formatsWithAndWithoutHash() {
        #expect(HexFormat(includeHash: true, uppercase: false).string(red) == "#eb5244")
        #expect(HexFormat(includeHash: false, uppercase: false).string(red) == "eb5244")
    }

    @Test func formatsCase() {
        #expect(HexFormat(includeHash: true, uppercase: true).string(red) == "#EB5244")
        #expect(HexFormat(includeHash: false, uppercase: true).string(red) == "EB5244")
    }

    @Test func padsSmallChannels() {
        let c = HexColor(r: 0, g: 0x0A, b: 0x01)
        #expect(c.canonical == "000A01")
    }

    @Test(arguments: ["eb5244", "#EB5244", "  #eB5244\n"])
    func parsesValidHex(_ input: String) {
        #expect(HexColor(hex: input) == red)
    }

    @Test(arguments: ["", "#", "eb524", "eb52440", "gg5244", "#eb 244", "+b5244"])
    func rejectsInvalidHex(_ input: String) {
        #expect(HexColor(hex: input) == nil)
    }

    @Test func rgbString() {
        #expect(red.rgbString == "rgb(235, 82, 68)")
    }

    @Test func cmykOfKnownColors() {
        #expect(red.cmyk == .init(c: 0, m: 65, y: 71, k: 8))
        #expect(HexColor(r: 255, g: 255, b: 255).cmyk == .init(c: 0, m: 0, y: 0, k: 0))
        #expect(HexColor(r: 0, g: 0, b: 0).cmyk == .init(c: 0, m: 0, y: 0, k: 100))
        #expect(HexColor(r: 0, g: 255, b: 255).cmyk == .init(c: 100, m: 0, y: 0, k: 0))
        #expect(HexColor(r: 128, g: 128, b: 128).cmyk == .init(c: 0, m: 0, y: 0, k: 50))
        #expect(HexColor(r: 0x12, g: 0x34, b: 0x56).cmyk == .init(c: 79, m: 40, y: 0, k: 66))
    }

    @Test func cmykString() {
        #expect(red.cmykString == "cmyk(0%, 65%, 71%, 8%)")
    }
}
