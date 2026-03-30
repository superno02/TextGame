# ProjectOverview.md — 專案快速理解指南

> 最後更新：2026-03-30（對話系統改造：樹狀對話、NPC 好感度）
> 目標：讓新工程師在 5 分鐘內理解此專案

---

## 1. 專案用途

TextGame 是一款 **iOS 平台的純文字 MUD 風格角色扮演遊戲**，參考經典線上文字遊戲 DragonRealms 的設計理念。玩家透過選單式操作在虛擬世界中探索場景、與 NPC 互動、戰鬥怪物，並透過使用技能來提升角色能力。

- **平台**：iOS（SwiftUI）
- **語言**：遊戲內所有文字內容皆為中文
- **連線需求**：完全離線，無需網路

---

## 2. 主要功能列表

| 功能 | 狀態 | 說明 |
|------|------|------|
| 遊戲開始頁面 | ✅ 已完成 | 開始新遊戲 / 讀取存檔 |
| 角色建立 | ✅ 已完成 | 預設角色「路人甲 / 無業遊民」，屬性從 GuildTemplate 載入 |
| 場景移動 | ✅ 已完成 | 選單式地點選擇（11 個場景，含山村區域與河谷→沼澤→廢墟區域） |
| NPC 談話 | ✅ 已完成 | 樹狀多輪對話（玩家選擇選項），支援條件觸發（guild/circle/item/affinity）、goto 跳轉、NPC 好感度 |
| 攻擊選擇 | ✅ 已完成 | 選擇場景中的怪物目標 |
| 角色屬性顯示 | ✅ 已完成 | 六大屬性 + 三大狀態值，正確對應當前存檔角色 |
| 技能頁面 | ✅ 已完成 | 按 4 大分類顯示技能、等級、經驗值進度條 |
| 背包頁面 | ✅ 已完成 | 裝備欄（7 部位）+ 背包物品列表 |
| 存檔 / 讀檔 | ✅ 已完成 | 5 個槽位，離開前景自動存檔 + 手動存檔按鈕，支援左滑刪除存檔（含確認） |
| 遊戲引擎 | ✅ 已完成 | GameEngine（@Observable）管理場景、對話、攻擊、存檔 |
| 錯誤處理 | ✅ 已完成 | JSON 載入錯誤於訊息區顯示 |
| 單元測試 | ✅ 已完成 | 106 個 Swift Testing 測試案例（全通過），含 UI 測試共 110 個 |
| 戰鬥系統 | ✅ 已完成 | 回合制自動戰鬥（命中/閃避/傷害/掉落物/死亡/逃跑/技能經驗） |
| 商店系統 | ✅ 已完成 | NPC 商人談話後自動開啟商店，支援購買/出售、金幣系統、NPC 庫存管理 |
| NPC 好感度 | ✅ 已完成 | 每次對話 +1 好感度，好感度影響可見的對話選項 |
| 職業選擇 | ⬜ 待開發 | 目前固定為無業遊民 |

---

## 3. 主要技術

| 技術 | 用途 |
|------|------|
| **Swift** | 主要程式語言 |
| **SwiftUI** | 使用者介面框架 |
| **SwiftData** | 資料持久化（角色、技能、物品、存檔） |
| **Observation** | `@Observable` macro，用於 GameEngine 狀態管理 |
| **Foundation** | JSON 解碼、基礎資料處理 |
| **Bundle JSON** | 遊戲靜態資料定義（11 場景、13 怪物、10 NPC、30 物品、5 職業、11 掉落表） |
| **Swift Testing** | 單元測試框架（`@Test`、`#expect`） |

無使用任何第三方套件。

---

## 4. App 整體運作方式

```
App 啟動
    │
    ▼
TextGameApp（設定 SwiftData ModelContainer）
    │
    ▼
StartView（開始頁面）
    ├── 「開始遊戲」→ 建立新角色 + 存檔 → 進入 GameView
    └── 「讀取存檔」→ 選擇存檔槽位 → 進入 GameView
         │
         ▼
    GameView（遊戲主畫面）
    ├── .task 初始化 GameEngine（注入 ModelContext）
    │
    ┌─────────────────────────────┐
    │  上半部：訊息輸出區          │ ← 等寬字型、顏色區分、上限 50 筆
    │  （場景描述、戰鬥訊息等）      │
    ├─────────────────────────────┤
    │  下半部：操作按鈕區          │
    │  [移動] [攻擊] [談話]       │ ← 彈窗選單 → GameEngine 處理
    │  [技能] [物品] [屬性]       │ ← NavigationLink 子頁面（傳入 character）
    └─────────────────────────────┘
```

### 資料流向

1. **靜態資料**：JSON 檔案 → `*TemplateLoader`（Singleton，App 啟動時自動載入，具備 loadError）→ GameEngine / View 查詢使用。掉落物定義獨立於 `loot_tables.json`，怪物透過 `lootTableId` 引用
2. **動態資料**：SwiftData `@Model` ↔ GameEngine（透過 ModelContext / FetchDescriptor）↔ View
3. **存檔機制**：`scenePhase` 變為 `.inactive` 時自動存檔 + toolbar 手動存檔按鈕 → GameEngine.saveGame()

---

## 5. 專案主要模組

### Engine 模組
`GameEngine`（`@Observable`）為遊戲邏輯核心，管理訊息列表、場景移動、攻擊、樹狀 NPC 對話（多輪互動）、商店交易、存檔，並在啟動時檢查所有模板載入狀態。

### Views 模組
負責所有使用者介面。GameView 為純 UI 層，將操作轉發給 GameEngine，下半部操作區支援動態切換（正常模式 ↔ 對話模式）。子頁面（SkillView、InventoryView、StatusView、ShopView）接收 `PlayerCharacter` 參數顯示資料。ShopView 以 `.sheet` 呈現商店介面。

### Models 模組
分為兩類：
- **持久化 Model**（`@Model`）：`PlayerCharacter`、`Skill`、`GameItem`、`SaveSlot`
- **模板 / 載入器**：`SceneTemplate`、`MonsterTemplate`、`NPCTemplate`、`ItemTemplate`、`GuildTemplate`、`LootTableTemplate` 及其對應 Loader（均具備 `loadError` 追蹤）

### Resources 模組
6 個 JSON 檔案定義了遊戲世界的所有靜態內容（11 場景、13 怪物、30 物品、10 NPC、5 職業、11 掉落表），是遊戲設計師的主要編輯對象。世界分為「山村區域」（村莊→後山→深山）和「河谷區域」（河邊渡口→沼澤→廢墟），怪物等級涵蓋 1~8。所有 ID 採用流水號前綴格式（`{類別碼}_{序號}_{原始名稱}`），確保資料可追蹤性。

### Tests 模組
7 個測試檔涵蓋：角色初始化（20 項）、技能經驗與升級（9 項）、物品條件判斷（9 項）、模板載入驗證（15 項）、NPC 對話與條件評估（15 項）、戰鬥公式與邏輯（26 項）、交易價格計算（11 項），共 106 個測試案例（不含 UI 測試）。
