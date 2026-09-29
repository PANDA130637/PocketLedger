import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model: StatisticsModel
    private let monthClock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init(context: NSManagedObjectContext) {
        _model = StateObject(wrappedValue: StatisticsModel(context: context))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(model.month, format: .dateTime.year().month(.wide))
                        .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    if let error = model.errorMessage {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("统计暂时不可用").font(.headline)
                            Text(error).font(.caption)
                            Button("重新加载") { model.reload() }
                        }.foregroundStyle(.red)
                    } else {
                        balanceCard
                        HStack(spacing: 12) {
                            totalCard("本月收入", cents: model.summary.income,
                                      symbol: "arrow.down.left", color: Theme.income)
                            totalCard("本月支出", cents: model.summary.expense,
                                      symbol: "arrow.up.right", color: Theme.accent)
                        }
                        categoryCard
                    }
                }.padding(20)
            }
            .background(Theme.background)
            .navigationTitle("本月统计")
            .onAppear { model.refreshMonthIfNeeded() }
            .onChange(of: scenePhase) { phase in
                if phase == .active { model.refreshMonthIfNeeded() }
            }
            .onReceive(monthClock) { model.refreshMonthIfNeeded(now: $0) }
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("本月结余", systemImage: "wallet.pass").font(.subheadline)
            Text(Money.formatted(model.summary.balance))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
            Text("收入 − 支出").font(.caption).opacity(0.8)
        }
        .foregroundStyle(.white).padding(24).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.gradient, in: RoundedRectangle(cornerRadius: 24))
    }

    private func totalCard(_ title: String, cents: Int64, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.caption).foregroundStyle(color)
            Text(Money.formatted(cents)).font(.headline).monospacedDigit()
                .minimumScaleFactor(0.6).lineLimit(1)
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("支出花在哪里").font(.headline)
            if model.summary.categories.isEmpty {
                EmptyStateView(symbol: "chart.bar", title: "本月还没有支出",
                               message: "记下第一笔支出后，这里会显示分类统计。")
            } else {
                Chart(model.summary.categories) { item in
                    BarMark(x: .value("金额（元）", Double(item.cents) / 100),
                            y: .value("分类", item.category.title))
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(5)
                        .accessibilityLabel(item.category.title)
                        .accessibilityValue(Money.formatted(item.cents))
                }
                .chartYScale(domain: model.summary.categories.map { $0.category.title })
                .chartXAxisLabel("金额（元）")
                .frame(height: CGFloat(max(model.summary.categories.count, 2)) * 46 + 32)
                ForEach(model.summary.categories) { item in
                    HStack {
                        Label(item.category.title, systemImage: item.category.symbol)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Money.formatted(item.cents)).monospacedDigit()
                    }.font(.subheadline)
                }
            }
        }
        .padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22))
    }
}
