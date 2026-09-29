import SwiftUI

@main
struct PocketLedgerApp: App {
    private let persistence: PersistenceController?
    private let startupError: String?

    init() {
        do {
            persistence = try PersistenceController()
            startupError = nil
        } catch {
            persistence = nil
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let persistence {
                    ContentView(context: persistence.container.viewContext)
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "externaldrive.badge.exclamationmark")
                            .font(.largeTitle).foregroundStyle(.orange)
                        Text("暂时无法打开账本").font(.title2.bold())
                        Text(startupError ?? "本地存储不可用")
                            .font(.footnote).foregroundStyle(.secondary)
                        Text("请检查设备存储空间后重新打开 App。原有数据不会被自动删除。")
                            .font(.callout)
                    }
                    .padding(28)
                }
            }
            .tint(Theme.accent)
            .preferredColorScheme(.light)
        }
    }
}
