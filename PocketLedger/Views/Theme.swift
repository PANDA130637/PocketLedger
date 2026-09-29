import SwiftUI

enum Theme {
    static let accent = Color(red: 0.16, green: 0.35, blue: 0.88)
    static let income = Color(red: 0.06, green: 0.46, blue: 0.37)
    static let background = Color(red: 0.96, green: 0.97, blue: 0.99)
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 38)).foregroundStyle(Theme.accent)
                .padding(22).background(Theme.accent.opacity(0.08), in: Circle())
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding(24).frame(maxWidth: .infinity)
    }
}
