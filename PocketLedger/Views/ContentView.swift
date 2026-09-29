import SwiftUI
import CoreData

struct ContentView: View {
    let context: NSManagedObjectContext
    var body: some View {
        TabView {
            LedgerListView()
                .tabItem { Label("账本", systemImage: "list.bullet.rectangle") }
            StatisticsView(context: context)
                .tabItem { Label("统计", systemImage: "chart.bar.xaxis") }
        }
    }
}

private struct LedgerListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(fetchRequest: LedgerEntry.allEntriesRequest(), animation: .default)
    private var entries: FetchedResults<LedgerEntry>
    @State private var showingAdd = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "wallet.pass.fill").font(.title).foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("让每一笔，都有迹可循").font(.headline)
                            Text("记录日常，慢慢积累财务好习惯")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 12)
                }
                Section("全部流水 · \(entries.count) 笔") {
                    if entries.isEmpty {
                        EmptyStateView(symbol: "tray", title: "从第一笔开始",
                                       message: "点击右上角加号，记录一笔收入或支出。")
                    }
                    ForEach(entries, id: \.objectID) { entry in
                        LedgerRow(entry: entry)
                    }
                    .onDelete(perform: delete)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("口袋账本")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }.accessibilityLabel("新增记账")
                }
            }
            .sheet(isPresented: $showingAdd) { AddEntryView() }
            .alert("删除失败", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("知道了", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "请重试") }
        }
    }

    private func delete(at offsets: IndexSet) {
        let selected = offsets.map { entries[$0] }
        do { try LedgerStore.delete(selected, in: context) }
        catch { errorMessage = error.localizedDescription }
    }
}

private struct LedgerRow: View {
    @ObservedObject var entry: LedgerEntry
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.category.symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(entry.kind == .income ? Theme.income : Theme.accent)
                .frame(width: 42, height: 42)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.category.title).font(.body.weight(.medium))
                if !entry.note.isEmpty {
                    Text(entry.note).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Text(entry.date, format: .dateTime.month().day().hour().minute())
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(entry.kind == .income ? "+" : "−")\(Money.formatted(entry.amountCents))")
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                    .foregroundStyle(entry.kind == .income ? Theme.income : Color.primary)
                    .minimumScaleFactor(0.75).lineLimit(1)
                Text(entry.kind.title).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(context: PreviewData.persistence.container.viewContext)
            .environment(\.managedObjectContext, PreviewData.persistence.container.viewContext)
            .preferredColorScheme(.light)
    }
}
#endif
