import SwiftUI

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var kind: EntryKind = .expense
    @State private var amount = ""
    @State private var category: LedgerCategory = .food
    @State private var date = Date()
    @State private var note = ""
    @State private var submitted = false
    @State private var saveError: String?
    @State private var saving = false
    @FocusState private var amountFocused: Bool

    private var amountError: String? {
        guard submitted || !amount.isEmpty else { return nil }
        do { _ = try Money.parse(amount); return nil }
        catch { return error.localizedDescription }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("收支类型", selection: $kind) {
                        ForEach(EntryKind.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented)
                    HStack(alignment: .firstTextBaseline) {
                        Text("¥").font(.title2).foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 38, weight: .semibold, design: .rounded))
                            .focused($amountFocused)
                            .accessibilityLabel("记账金额，人民币元")
                    }.padding(.vertical, 18)
                    if let amountError {
                        Text(amountError).font(.caption).foregroundStyle(.red)
                    }
                } header: { Text("\(kind.title)金额") }

                Section("记账详情") {
                    Picker("分类", selection: $category) {
                        ForEach(kind.categories) { item in
                            Label(item.title, systemImage: item.symbol).tag(item)
                        }
                    }
                    DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("备注，例如：午餐 / 地铁", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                    HStack {
                        Spacer()
                        Text("\(note.count)/100")
                            .font(.caption2).foregroundStyle(note.count > 100 ? Color.red : Color.secondary)
                    }
                    if note.count > 100 {
                        Text("备注不能超过 100 个字符。").font(.caption).foregroundStyle(.red)
                    }
                }
                if let saveError {
                    Section { Text(saveError).font(.callout).foregroundStyle(.red) }
                }
                Section {
                    Button(action: save) {
                        Text(saving ? "正在保存…" : "保存这笔记账")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.disabled(saving)
                } footer: { Text("数据仅保存在当前设备，无需注册或联网。") }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("新增记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }.disabled(saving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { amountFocused = false }
                }
            }
            .onChange(of: kind) { newKind in
                if !newKind.categories.contains(category) { category = newKind.categories[0] }
            }
        }
    }

    private func save() {
        guard !saving else { return }
        submitted = true
        saveError = nil
        guard amountError == nil, note.count <= 100 else { return }
        saving = true
        defer { saving = false }
        do {
            try LedgerStore.add(amount: amount, kind: kind, category: category,
                                date: date, note: note, in: context)
            dismiss()
        } catch { saveError = error.localizedDescription }
    }
}
