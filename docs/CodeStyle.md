# CodeStyle.md — 程式碼風格指南

> 最後更新：2026-03-18（技術債修復後）
> 目的：讓 AI 與人類工程師在修改程式碼時維持原有風格

---

## 1. 命名規則

### 型別命名（PascalCase）
```swift
struct GameScene { }
class PlayerCharacter { }
class GameEngine { }
enum Guild { }
```

### 屬性與方法（camelCase）
```swift
var currentHealth: Int
var guildRawValue: String
func moveToScene(_ sceneId: String)
func appendMessage(_ text: String)
```

### 列舉 case（camelCase）
```swift
case warrior = "warrior"
case lightArmor = "輕甲"
case mainHand = "mainHand"
```

### 常見命名模式

| 模式 | 範例 | 說明 |
|------|------|------|
| `*RawValue` | `guildRawValue`, `itemTypeRawValue` | SwiftData 中儲存列舉的 rawValue |
| `*Template` | `SceneTemplate`, `MonsterTemplate` | JSON 靜態資料模板 |
| `*Loader` | `SceneTemplateLoader`, `ItemTemplateLoader` | Singleton 模板載入器 |
| `display*` | `displayName` | 中文顯示用計算屬性 |
| `req*` | `reqCircle`, `reqStrength` | 使用/裝備需求屬性 |
| `mod*` | `modStrength`, `modMaxHealth` | 素質修正屬性 |
| `current*` | `currentHealth`, `currentSceneId` | 目前狀態值 |
| `max*` | `maxHealth`, `maxStack` | 最大值 |
| `show*` | `showMoveSheet`, `showAttackSheet` | 彈窗顯示控制 |
| `is*` | `isEquipped`, `isRestArea`, `isStackable` | 布林狀態 |
| `available*` | `availableMonsters`, `availableNPCs` | 目前場景可用的資源 |
| `load*` | `loadError`, `loadData`, `loadTemplates` | 載入相關 |

---

## 2. View 結構規範

### GameView 模式（使用 Engine）
```swift
struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    let slotIndex: Int
    @State private var engine: GameEngine?

    var body: some View {
        Group {
            if let engine {
                gameContent(engine: engine)
            } else {
                ProgressView("載入中…")
            }
        }
        .task {
            if engine == nil {
                engine = GameEngine(slotIndex: slotIndex, modelContext: modelContext)
            }
        }
    }
}
```

### 子頁面模式（接收資料參數）
```swift
struct SubPageView: View {
    let character: PlayerCharacter  // 由 GameView 傳入

    var body: some View {
        List { ... }
            .navigationTitle("標題")
    }
}
```

### View 職責
- **GameView**：純 UI 層，將操作轉發給 GameEngine
- **子視圖**透過接收 `GameEngine` 參數的 function 拆分（如 `messageListView(engine:)`、`actionButtonsView(engine:)`）
- **彈窗**使用 `.sheet()` 呈現，透過 Engine 的 `show*` 屬性控制（使用 `Binding(get:set:)` 橋接）

---

## 3. Engine 結構規範

```swift
@Observable
final class GameEngine {
    // 1. 可觀察狀態
    var messages: [String] = [...]
    var currentSceneId: String = "village"
    var showMoveSheet = false

    // 2. 依賴
    let slotIndex: Int
    private let modelContext: ModelContext
    private let sceneLoader = SceneTemplateLoader.shared

    // 3. 快取
    private let scenes: [String: GameScene]

    // 4. 計算屬性
    var currentScene: GameScene { ... }
    var currentSaveSlot: SaveSlot? { ... }  // FetchDescriptor

    // MARK: - 方法
    func moveToScene(_ sceneId: String) { ... }
    func saveGame() { ... }
    func appendMessage(_ text: String) { ... }
}
```

**重要**：`#Predicate` 中不可直接捕獲 self property，需先 let bind：
```swift
var currentSaveSlot: SaveSlot? {
    let targetSlot = slotIndex
    let descriptor = FetchDescriptor<SaveSlot>(
        predicate: #Predicate<SaveSlot> { slot in
            slot.slotIndex == targetSlot
        }
    )
    return try? modelContext.fetch(descriptor).first
}
```

---

## 4. Model 使用方式

### SwiftData Model（`@Model`）
```swift
@Model
final class SomeName {
    var property: Type

    // 列舉儲存使用 rawValue + @Transient 計算屬性
    var enumRawValue: String

    @Transient
    var enumProperty: EnumType {
        get { EnumType(rawValue: enumRawValue) ?? .default }
        set { enumRawValue = newValue.rawValue }
    }

    @Relationship(deleteRule: .cascade)
    var children: [ChildModel] = []

    init(...) { ... }
}
```

### PlayerCharacter 初始化模式
```swift
init(name: String, guild: Guild) {
    // 從 GuildTemplateLoader 取得 baseStats
    let template = GuildTemplateLoader.shared.template(for: guild)
    let stats = template?.baseStats ?? GuildBaseStats(fallback 值)

    self.strength = stats.strength
    // ...

    // 使用 StatusFormula 計算狀態值
    if let template {
        self.maxHealth = template.healthFormula.calculate(attributeValue: self.constitution)
    } else {
        self.maxHealth = 50 + self.constitution * 5  // fallback
    }
}
```

---

## 5. JSON 資料載入方式

### 載入器模式（統一 Singleton Pattern）
```swift
final class SomeTemplateLoader {
    static let shared = SomeTemplateLoader()

    private(set) var templates: [String: SomeTemplate] = [:]
    private(set) var loadError: String?  // 載入錯誤追蹤

    private init() { loadTemplates() }

    private func loadTemplates() {
        loadError = nil
        guard let url = Bundle.main.url(forResource: "file", withExtension: "json") else {
            loadError = "找不到 file.json"
            print("[SomeTemplateLoader] \(loadError!)")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let container = try JSONDecoder().decode(Container.self, from: data)
            templates = Dictionary(uniqueKeysWithValues: container.items.map { ($0.id, $0) })
        } catch {
            loadError = "載入 file.json 失敗：\(error.localizedDescription)"
            print("[SomeTemplateLoader] \(loadError!)")
        }
    }

    func template(for id: String) -> SomeTemplate? { templates[id] }
    func allTemplates() -> [SomeTemplate] { Array(templates.values).sorted { $0.id < $1.id } }
    func reload() { templates.removeAll(); loadTemplates() }
}
```

---

## 6. Extension 使用方式

本專案目前**未使用 Extension**。所有輔助方法直接定義在型別內部。

---

## 7. 測試風格

使用 **Swift Testing** 框架：

```swift
import Testing
@testable import TextGame

struct SomeTests {
    @Test("中文描述測試目的")
    func testMethodName() {
        let result = someFunction()
        #expect(result == expected)
        #expect(!result.isEmpty)
    }
}
```

---

## 8. 常見 Coding Pattern

### MARK 註解分區
```swift
// MARK: - 訊息列表
// MARK: - 場景狀態
// MARK: - 依賴
// MARK: - 計算屬性
// MARK: - 動作處理
```

### 中文文件註解（DocComment）
```swift
/// 遊戲引擎，負責管理遊戲邏輯狀態（場景、訊息、攻擊、對話、存檔）
/// 添加訊息，超過 50 筆時移除最舊的
```

### 日誌輸出格式
```swift
print("[ClassName] 描述：\(variable)")
```

---

## 9. 建議遵守的 Coding Rule

1. **遊戲邏輯寫在 `GameEngine` 中，View 只做 UI 渲染**
2. **子頁面接收 `PlayerCharacter` 參數，不使用 `@Query` 查詢角色**
3. **所有列舉均需提供 `displayName` 中文計算屬性**
4. **SwiftData 中的列舉欄位使用 `*RawValue` + `@Transient` 模式**
5. **模板載入器使用 Singleton + `private init()` + `loadError` 追蹤**
6. **JSON 容器使用 `private struct`**
7. **彈窗使用 Engine 的 `show*` 屬性控制**
8. **訊息管理統一透過 `appendMessage()`，限制上限 50 筆**
9. **Engine 使用 `@Observable`（非 ObservableObject）**
10. **在 `.task` 中初始化 Engine（而非 View init）**
11. **遊戲內所有文字使用中文**
12. **使用 4 格空白縮排**
13. **型別使用 PascalCase，屬性與方法使用 camelCase**
14. **優先使用 Swift async/await，避免 Combine**
15. **測試使用 Swift Testing framework（`@Test`、`#expect`）**
16. **Preview 使用 `inMemory: true` 的 ModelContainer**
