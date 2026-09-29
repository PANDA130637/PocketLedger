# PocketLedger · 口袋账本

[![iOS Build and Tests](https://github.com/PANDA130637/PocketLedger/actions/workflows/ios.yml/badge.svg)](https://github.com/PANDA130637/PocketLedger/actions/workflows/ios.yml)

一款基于 SwiftUI 的轻量 iOS 记账 App。记录日常收支，在月度统计中了解消费结构。**个人学习作品，用于 iOS 工程师实习求职作品集，偏金融科技方向。**

## 技术栈

- Swift 5 语言模式、SwiftUI，支持 iOS 16+
- Core Data + SQLite 本地持久化；以 Swift 代码定义模型，无需额外生成模型类
- 苹果官方 Swift Charts 绘制分类消费柱状图
- Combine 监听持久化变更，XCTest 单元测试，GitHub Actions 持续集成
- 无第三方 SDK、无账号系统、无后端、无运行时网络请求

## 主要功能

- 首页按时间倒序展示金额、分类、收支类型、时间和备注；支持左滑删除及空状态。
- 新增收入或支出，选择分类与时间，填写最多 100 字备注。
- 金额限定为 0.01～999,999,999.99 元，最多两位小数；零、负数、非法格式不会保存。
- 本月收入、支出、结余及按金额排序的分类支出图表；新增和删除后自动刷新。
- 中文浅色界面、系统图标、金额等宽数字、基本 VoiceOver 描述。
- 加载或保存失败显示错误；不自动删除数据库，也不会悄悄退回临时存储。

## 运行方式

1. 在安装 Xcode 的 Mac 上克隆本仓库：
   ```bash
   git clone https://github.com/PANDA130637/PocketLedger.git
   cd PocketLedger
   open PocketLedger.xcodeproj
   ```
2. 使用 Xcode 14.3 或更新版本，选择共享 Scheme **PocketLedger**。
3. 选择 iOS 16+ iPhone/iPad 模拟器，按 `⌘R`。不需要安装依赖或配置服务器。
4. 如需真机运行，在 Signing & Capabilities 选择你的开发团队；必要时修改 Bundle Identifier。
5. 按 `⌘U` 运行测试。仓库 Actions 也会在 macOS 上自动构建并运行测试。

命令行测试示例（将设备名替换为本机已安装的模拟器）：

```bash
xcodebuild test -project PocketLedger.xcodeproj -scheme PocketLedger   -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

## 核心文件

```text
PocketLedger/
├── PocketLedgerApp.swift                 # App 入口、存储加载错误状态
├── Models/
│   ├── LedgerEntry.swift                 # Core Data 实体、收支和分类枚举
│   ├── Money.swift                       # 金额解析、范围验证与格式化
│   └── StatisticsModel.swift             # 月度查询、分类汇总及刷新
├── Persistence/PersistenceController.swift # SQLite、模型与增删入口
├── Views/
│   ├── ContentView.swift                 # Tab、流水列表及独立行视图
│   ├── AddEntryView.swift                # 新增表单与就地校验
│   ├── StatisticsView.swift              # 月度卡片和柱状图
│   └── Theme.swift                       # 主题及空状态
└── PreviewData.swift                     # 仅 Debug 预览使用的内存示例数据
PocketLedgerTests/LedgerTests.swift
PocketLedger.xcodeproj/
.github/workflows/ios.yml
```

## 设计说明与面试讨论点

**金额精度**：数据库保存 Int64 类型的整数分值。输入通过十进制数字校验后直接转换为分，格式化使用 Decimal；仅图表绘制坐标使用 Double，不参与财务合计。避免 `0.1 + 0.2` 一类二进制浮点误差。当前仅人民币，不提供汇率或多币种支持。

**数据流**：表单 → LedgerStore 再次验证 → Core Data 保存 → `@FetchRequest` 更新列表；统计模型监听 context 保存通知，仅重新计算本月汇总。数据库字段包含 UUID、金额分值、类型、分类、记账时间、备注和创建时间。

**性能处理**：系统 List 按需展示行，使用 Core Data objectID 作为稳定标识，单行独立观察记录；查询设置 40 条 fetchBatchSize 并给日期建索引。统计聚合不放在 View.body 内，使用月份 predicate 缩小查询范围。批量抓取不是分页，也不代表已通过大数据量性能压测；超大月流水可进一步改为后台分组聚合与分页。

**时间边界**：按设备本地日历及时间区间 `[月初, 下月月初)` 统计，避免月末漏计或下月重复计入。回到前台、打开统计页或分钟检查发现月份变化后刷新。

**本地存储**：正式安装从空账本开始；重启后读取 SQLite。预览示例保存在独立内存数据库，测试同样使用隔离内存库。卸载应用会删除本地数据；没有导出或云同步功能。当前是首版代码模型，未来改变 schema 需引入版本化模型并验证迁移，不能仅依赖自动迁移开关。

## 测试与验收

自动测试涵盖正确金额、两位小数、上限、非法字符、负数、零、溢出；记录新增、重取和删除；分类和备注校验；本地月份边界、收入支出合计、分类排序、删除后重算及空月份。

人工验收：

- 新安装显示空账本；新增餐饮 38.50、交通 6、工资 12800 后检查列表与统计。
- 重启 App 检查记录仍在；左滑删除后检查图表与合计更新。
- 输入 0、-1、1.234 或超过 100 字备注，确认提示且不写入数据。
- 切换收入/支出检查分类同步；验证跨月记录、前后台切换和大字号显示。
- 使用 Instruments 检查滚动和月度汇总；本仓库没有宣称性能基准数据。

项目源代码在 Windows 环境创建，本机无法运行 Xcode 或 iOS 模拟器。实际云端编译和 XCTest 结果以顶部 Actions 状态为准；界面和真机检查仍需在 Mac/iPhone 完成。

## 项目截图说明

当前未附真实运行截图，不以设计稿冒充模拟器截图。建议运行后使用 `⌘S` 保存以下三张截图，再加入 `docs/screenshots/`：

| 页面 | 建议文件名 | 展示内容 |
| --- | --- | --- |
| 首页 | home.png | 工资、餐饮、交通、购物记录，含备注和日期 |
| 新增记账 | add-entry.png | 支出 38.50、餐饮、午餐备注 |
| 统计 | statistics.png | 本月收入、支出、结余、分类消费柱状图 |

示例数据只用于 Xcode Canvas 预览；需要模拟器截图时请手动录入示例记录。待截图加入后可在 README 用相对图片路径展示。

## 项目定位与后续方向

这是个人学习与实习求职项目，不是银行客户端或生产级财务系统。首版聚焦原生 UI、金额精度、本地持久化和可测试性；未来可增加账单编辑、导出、预算及迁移测试。当前不包含 App Store 发布配置与正式品牌图标。

参考苹果官方文档：[SwiftUI FetchRequest](https://developer.apple.com/documentation/swiftui/fetchrequest)、[Swift Charts](https://developer.apple.com/documentation/charts)、[Core Data](https://developer.apple.com/documentation/coredata)。
