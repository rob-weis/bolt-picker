import SwiftUI

struct HistoryList: View {
    let history: HistoryStore
    let format: HexFormat
    let onCopy: (String) -> Void

    @State private var flashed: HexColor?
    @State private var flashTask: Task<Void, Never>?

    static let rowHeight: CGFloat = 52
    static let maxListHeight: CGFloat = 420

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Color History")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(history.colors.count)/\(HistoryStore.limit)")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Clear") { history.clear() }
                    .buttonStyle(.borderless)
                    .font(.system(size: 12))
                    .disabled(history.colors.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 4)

            if history.colors.isEmpty {
                Text("Colors you pick will appear here.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(history.colors, id: \.self) { color in
                            HistoryRow(
                                color: color,
                                format: format,
                                isFlashed: flashed == color,
                                onCopy: { copy($0, flashing: color) },
                                onRemove: { history.remove(color) }
                            )
                            .frame(height: Self.rowHeight)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(height: min(CGFloat(history.colors.count) * Self.rowHeight + 6, Self.maxListHeight))
            }
        }
    }

    private func copy(_ text: String, flashing color: HexColor) {
        onCopy(text)
        flashTask?.cancel()
        withAnimation(.easeOut(duration: 0.12)) { flashed = color }
        flashTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) { flashed = nil }
        }
    }
}

private struct HistoryRow: View {
    let color: HexColor
    let format: HexFormat
    let isFlashed: Bool
    let onCopy: (String) -> Void
    let onRemove: () -> Void

    @State private var hovering = false

    var body: some View {
        let hex = format.string(color)
        let cmyk = color.cmyk

        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.swiftUIColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.primary.opacity(0.15), lineWidth: 0.5)
                )
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text(hex)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                ValueLine(label: "RGB", values: [Int(color.r), Int(color.g), Int(color.b)])
                ValueLine(label: "CMYK", values: [cmyk.c, cmyk.m, cmyk.y, cmyk.k])
            }

            Spacer(minLength: 0)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(.green)
                .opacity(isFlashed ? 1 : 0)
                .scaleEffect(isFlashed ? 1 : 0.6)
        }
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.primary.opacity(hovering ? 0.06 : 0))
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { onCopy(hex) }
        .help("Click to copy \(hex)")
        .contextMenu {
            Button("Copy Hex  \(hex)") { onCopy(hex) }
            Button("Copy RGB  \(color.rgbString)") { onCopy(color.rgbString) }
            Button("Copy CMYK  \(color.cmykString)") { onCopy(color.cmykString) }
            Divider()
            Button("Remove", role: .destructive, action: onRemove)
        }
    }
}

/// A label followed by numbers in fixed-width columns, so they line up from row to row.
private struct ValueLine: View {
    let label: String
    let values: [Int]

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .foregroundStyle(.tertiary)
                .frame(width: 38, alignment: .leading)
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text("\(value)")
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .font(.system(size: 11).monospacedDigit())
    }
}
