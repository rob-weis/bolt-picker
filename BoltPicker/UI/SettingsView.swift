import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.includeHash) private var includeHash = true
    @AppStorage(SettingsKey.uppercase) private var uppercase = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    private static let sample = HexColor(r: 0xEB, g: 0x52, b: 0x44)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 10) {
                Toggle("Include # when copying", isOn: $includeHash)
                Toggle("Uppercase letters", isOn: $uppercase)
                HStack(spacing: 6) {
                    Text("Copies as")
                        .foregroundStyle(.secondary)
                    Text(HexFormat(includeHash: includeHash, uppercase: uppercase).string(Self.sample))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
                }
                .font(.system(size: 12))
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let loginError {
                    Text(loginError)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                }
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .font(.system(size: 13))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        let isEnabled = service.status == .enabled
        guard enabled != isEnabled else { return }
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            launchAtLogin = service.status == .enabled
        }
    }
}
