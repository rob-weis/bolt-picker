import SwiftUI

struct PopoverView: View {
    let history: HistoryStore
    let onPick: () -> Void
    let onCopy: (String) -> Void
    let onQuit: () -> Void

    @AppStorage(SettingsKey.includeHash) private var includeHash = true
    @AppStorage(SettingsKey.uppercase) private var uppercase = false
    @State private var showingSettings = false

    private var format: HexFormat { HexFormat(includeHash: includeHash, uppercase: uppercase) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if showingSettings {
                SettingsView()
            } else {
                HistoryList(history: history, format: format, onCopy: onCopy)
            }
            Divider()
            footer
        }
        .frame(width: 340)
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let last = history.colors.first {
                Button {
                    onCopy(format.string(last))
                } label: {
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(last.swiftUIColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(.primary.opacity(0.15), lineWidth: 0.5)
                            )
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(format.string(last))
                                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            Text("Last picked · click to copy")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Copy \(format.string(last))")
            } else {
                Text("Pick any pixel on screen.\nIts hex is copied for you.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button(action: onPick) {
                Label("Pick", systemImage: "eyedropper")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(14)
    }

    private var footer: some View {
        HStack {
            Button {
                showingSettings.toggle()
            } label: {
                Image(systemName: showingSettings ? "chevron.backward" : "gearshape")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .help(showingSettings ? "Back to history" : "Settings")

            Spacer()
            Text("Bolt Picker")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
            Spacer()

            Button(action: onQuit) {
                Image(systemName: "power")
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .help("Quit Bolt Picker")
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
