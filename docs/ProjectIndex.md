# TextGame 專案索引

> 最後更新：2026-03-27（新增物品交易系統）

## 文檔導覽

| 優先順序 | 文件 | 內容說明 | 建議閱讀時機 |
|:--------:|------|----------|-------------|
| 1 | [`ProjectOverview.md`](ProjectOverview.md) | 專案總覽、功能列表、技術棧、App 運作方式、主要模組概述 | 初次接觸專案時必讀 |
| 2 | [`Architecture.md`](Architecture.md) | View + Engine + Model 三層架構、目錄結構、核心元件、技術債 | 開發新功能或理解架構時 |
| 3 | [`CombatStats.md`](CombatStats.md) | 數值系統完整說明：角色屬性、狀態值公式、怪物數值、物品數值、技能經驗、戰鬥公式 | 數值調整或戰鬥相關開發時 |
| 4 | [`Modules.md`](Modules.md) | 各模組職責詳述：App 進入點、Engine、Views（5個）、Models（持久化+模板）、Enums、Resources、Tests | 需了解特定模組細節時 |
| 5 | [`ImportantFlows.md`](ImportantFlows.md) | 11 個核心流程圖：啟動、新遊戲、讀檔、Engine 初始化、場景移動、戰鬥、對話、存檔、子頁面導航、技能經驗、模板載入 | 追蹤 bug 或實作跨模組功能時 |
| 6 | [`DependencyMap.md`](DependencyMap.md) | 模組間依賴關係圖：整體依賴、資料模型、模板載入器、View 資料存取路徑、物品/角色建立依賴鏈 | 重構或理解資料流向時 |
| 7 | [`CodeStyle.md`](CodeStyle.md) | 程式碼風格與命名規範：命名規則、View/Engine/Model 結構範本、JSON 載入模式、測試風格、16 條 Coding Rule | 撰寫新程式碼或 code review 時 |
| 8 | [`DebugGuide.md`](DebugGuide.md) | 常見問題與除錯指南：啟動失敗、JSON 載入、各功能問題檢查表、Schema 變更注意、日誌追蹤 | 遇到 bug 或問題排查時 |

### 閱讀建議

- **開發任務**（新功能、修 bug、重構）：至少閱讀本文件 + 優先順序 1~5
- **數值調整或戰鬥相關**：額外閱讀 `CombatStats.md`
- **簡單問答**（如「某個檔案在哪」）：僅需閱讀本文件即可

---

## 專案概述

這是一個以文字為主要輸出的 MUD 風格遊戲 App，參考 DragonRealms 的玩法設計。
遊戲內所有內容皆使用中文呈現。

### 遊戲風格（參考 DragonRealms）
- **純文字互動** — 遊戲內容以文字描述呈現，玩家透過指令與遊戲世界互動
- **技能制系統** — 使用特定技能就會提升該技能熟練度，非傳統等級制
- **公會/職業系統** — 四種職業：戰士、法師、盜賊、牧師
- **技能五大分類** — 武器、防具、生存、知識、魔法
- **場景移動** — 選單式地點選擇（非方向指令）
- **戰鬥系統** — 即時文字描述
- **存檔機制** — 多存檔槽位
- **離線遊戲** — 無需網路連線

### 畫面結構
- **畫面方向**：直立（Portrait）
- **上半部**：訊息輸出區域（遊戲文字、場景描述、戰鬥訊息等）
- **下半部**：使用者操作區域（指令輸入、快捷按鈕等）

## 技術棧
- Swift、SwiftUI、SwiftData
- 最低部署目標：依 Xcode 專案設定為準

## 程式碼風格
- 使用 4 格空白縮排
- 型別名稱使用 PascalCase，屬性與方法使用 camelCase
- SwiftUI 狀態使用 `@State private var`
- 優先使用 Swift async/await，避免使用 Combine
- 使用 Swift Testing 框架撰寫單元測試

## 架構原則
- 遵循 SwiftUI 的資料驅動模式
- **View → Engine → Model 三層架構**
  - View 層（GameView）：純 UI 渲染，將操作轉發給 Engine
  - Engine 層（GameEngine）：`@Observable` 管理遊戲邏輯狀態
  - Model 層：SwiftData（`@Model`）持久化資料
- 子頁面接收 `PlayerCharacter` 參數，不使用 `@Query` 查詢角色
- 模板載入器使用 Singleton + `loadError` 追蹤載入狀態
- Engine 在 `.task` 中初始化（非 View init），因 `@Environment(\.modelContext)` 在 init 中不可用

---

## 檔案用途說明

| 檔案 | 用途 |
|------|------|
| `TextGameApp.swift` | App 進入點，啟動時顯示 StartView，設定 SwiftData ModelContainer |
| `Engine/GameEngine.swift` | 遊戲引擎（@Observable），管理訊息、場景、攻擊、對話、商店交易、存檔等邏輯 |
| `Views/StartView.swift` | 遊戲開始頁面，提供「開始遊戲」與「讀取存檔」選項，支援左滑刪除存檔 |
| `Views/GameView.swift` | 遊戲主畫面（純 UI 層），初始化 Engine 並轉發操作，含手動存檔按鈕 |
| `Views/SkillView.swift` | 技能頁面，按 4 大分類顯示角色技能與熟練度進度條 |
| `Views/InventoryView.swift` | 背包頁面，顯示 7 個裝備部位與背包物品列表 |
| `Views/ShopView.swift` | 商店頁面，購買/出售分頁，顯示金幣餘額、商品價格與庫存 |
| `Views/StatusView.swift` | 屬性頁面，顯示角色基本資訊、六大屬性、三大狀態值與金幣 |
| `Models/Enums.swift` | 列舉定義：職業(Guild)、技能分類(SkillCategory)、技能類型(SkillType)、裝備欄位(EquipmentSlot) |
| `Models/PlayerCharacter.swift` | 玩家角色 Model，從 GuildTemplateLoader 取得初始屬性，含技能與背包關聯、經驗值與等階升級 |
| `Models/Skill.swift` | 技能 Model，含技能類型、等級、經驗值與實戰經驗吸收機制 |
| `Models/GameScene.swift` | 場景運行時結構，定義場景描述、出口列表 |
| `Models/GameItem.swift` | 物品 Model，含類型、數值屬性、裝備功能與使用條件判斷 |
| `Models/SaveSlot.swift` | 存檔槽位 Model，支援多存檔，關聯角色資料 |
| `Models/SceneTemplate.swift` | 場景模板與 SceneTemplateLoader（Singleton） |
| `Models/LootTableTemplate.swift` | 掉落表模板與 LootTableLoader（Singleton），定義掉落物品、機率與數量範圍 |
| `Models/MonsterTemplate.swift` | 怪物模板與 MonsterTemplateLoader（Singleton），透過 lootTableId 引用掉落表 |
| `Models/NPCTemplate.swift` | NPC 模板與 NPCTemplateLoader（Singleton），含條件對話過濾 |
| `Models/ItemTemplate.swift` | 物品模板與 ItemTemplateLoader（Singleton） |
| `Models/GuildTemplate.swift` | 職業模板與 GuildTemplateLoader（Singleton），含 StatusFormula、CircleGrowth |

### JSON 資源檔

所有 JSON 資源檔的 ID 採用 **流水號前綴格式**：`{類別碼}_{序號}_{原始名稱}`

| 類別碼 | 對應檔案 | 範例 |
|:------:|----------|------|
| `01_` | items.json | `01_01_iron_sword` |
| `02_` | monsters.json | `02_01_rabbit` |
| `03_` | scenes.json | `03_01_village` |
| `04_` | npcs.json | `04_01_village_elder` |
| `05_` | guilds.json | `05_01_none` |
| `06_` | loot_tables.json | `06_01_loot_rabbit` |

| 檔案 | 內容 | 資料量 |
|------|------|--------|
| `Resources/scenes.json` | 場景定義 | 6 個場景 |
| `Resources/monsters.json` | 怪物定義（透過 lootTableId 引用掉落表） | 6 種怪物 |
| `Resources/loot_tables.json` | 掉落表定義（物品、機率、數量範圍） | 4 張掉落表 |
| `Resources/npcs.json` | NPC 定義 | 7 個 NPC |
| `Resources/items.json` | 物品模板 | 16 種物品 |
| `Resources/guilds.json` | 職業定義 | 5 種職業 |

### 測試檔案

| 檔案 | 測試內容 | 數量 |
|------|----------|------|
| `PlayerCharacterTests.swift` | 初始屬性、狀態值、職業對應、經驗值與升級 | 20 |
| `SkillTests.swift` | 經驗吸收、升級、分類、公式 | 9 |
| `GameItemTests.swift` | 使用條件、堆疊、裝備 | 9 |
| `TemplateLoaderTests.swift` | 6 個 Loader 載入驗證 | 15 |
| `NPCTemplateTests.swift` | 條件對話、商人判定 | 6 |
| `CombatTests.swift` | 戰鬥公式、命中/閃避/傷害計算、CombatMonster、武器技能映射 | 26 |
| `TradeTests.swift` | 交易價格計算（購買價、出售價、交易技能加成、角色初始金幣） | 11 |

---

## 開發進度

### 已完成
- [x] 專案初始化建立
- [x] 確立遊戲風格（MUD 文字遊戲，參考 DragonRealms）
- [x] 定義畫面結構（直立畫面，上半訊息輸出、下半操作區）
- [x] 建立開始頁面 StartView（開始遊戲 / 讀取存檔）
- [x] 建立遊戲主畫面 GameView（訊息區 + 指令輸入區）
- [x] 更新 App 進入點指向 StartView
- [x] 移除範例檔案（ContentView.swift、Item.swift）
- [x] 設計遊戲核心 Model（角色、技能、場景、物品、存檔）
- [x] 實作 GameView 訊息輸出區域（等寬字型、顏色區分、上限 50 筆、自動捲動）
- [x] 實作 GameView 操作按鈕（移動、攻擊、談話、技能、物品、屬性）
- [x] 實作移動彈窗（選單式地點選擇）
- [x] 實作攻擊彈窗（選擇敵對生物）
- [x] 實作 StartView 開始遊戲流程（預設角色：路人甲/無業遊民）
- [x] 實作 StartView 讀取存檔彈窗（5 個槽位，顯示角色名與存檔時間）
- [x] 設定 SwiftData ModelContainer（含 Schema 不相容重建機制）
- [x] 實作存檔/讀檔功能（離開前景自動存檔、5 槽位各對應一個角色）
- [x] 抽取 GameEngine（@Observable），GameView 瘦身為純 UI 層
- [x] PlayerCharacter 初始屬性改由 GuildTemplateLoader 驅動（移除硬編碼）
- [x] 子頁面改為接收 `PlayerCharacter` 參數（移除 StatusView 的 @Query）
- [x] SkillView 完整實作（按戰鬥/生存/知識/魔法分類，顯示等級與進度條）
- [x] InventoryView 完整實作（7 個裝備部位 + 背包物品列表）
- [x] StatusView 完整實作（基本資訊、六大屬性、三大狀態值）
- [x] 6 個 TemplateLoader 新增 loadError 追蹤，GameEngine 啟動時統一檢查
- [x] NPC 談話功能（條件式對話過濾）
- [x] 單元測試 97 個（Swift Testing 框架）
- [x] 技術文件 7 份（docs/ 資料夾）
- [x] 戰鬥系統實作（回合制自動戰鬥、命中/閃避/傷害公式、掉落物、死亡處理）
- [x] 技能使用與經驗值獲取（戰鬥中自動觸發武器/防具/閃避技能經驗）
- [x] PlayerCharacter 戰鬥輔助屬性（totalAttackPower、totalDefensePower、equippedWeapon 等）
- [x] SkillType 武器技能映射（weaponSkillType(for:) 靜態方法）
- [x] CombatCalculator 純函數（命中/閃避/傷害/逃跑公式）
- [x] GameView 戰鬥狀態 UI（戰鬥中禁用移動/攻擊、訊息顏色新增、攻擊彈窗顯示怪物資訊）
- [x] 戰鬥系統單元測試 26 個（CombatTests.swift）
- [x] 經驗值系統（擊殺怪物獲得 EXP、等階升級、職業屬性自動成長、狀態值重算與全回復）
- [x] GuildTemplate 新增 CircleGrowth（每職業升級 +6 點，分佈依核心屬性）
- [x] StatusView 新增經驗值進度條顯示
- [x] GameView 升級訊息金色高亮
- [x] 移除戰鬥體力消耗限制（移除每攻擊 -5 SP、體力不足自動逃跑）
- [x] 經驗值系統單元測試 7 個（PlayerCharacterTests.swift）
- [x] 掉落表系統獨立化（loot_tables.json + LootTableLoader，怪物透過 lootTableId 引用掉落表）
- [x] 掉落物支援數量範圍（minQuantity~maxQuantity）
- [x] 掉落表系統單元測試 3 個（TemplateLoaderTests.swift）
- [x] JSON ID 流水號前綴化（所有資源檔 ID 格式統一為 `{類別碼}_{序號}_{原始名稱}`）
- [x] Guild enum rawValue 同步更新（如 `warrior` → `05_02_warrior`）
- [x] 所有 Swift 原始碼與測試檔中的硬編碼 ID 同步更新
- [x] 存檔刪除功能（讀取存檔彈窗中左滑刪除，含二次確認，cascade 刪除角色資料）
- [x] GameView 手動存檔按鈕（toolbar 右上角，點擊觸發 saveGame() 並顯示「存檔完成。」訊息）
- [x] 物品交易系統（商店購買/出售、金幣系統、TradeCalculator 價格公式）
- [x] PlayerCharacter 新增 gold 欄位（初始 100 金幣）
- [x] ShopView 商店介面（購買/出售分頁、金幣餘額、庫存顯示）
- [x] NPC 商人談話後自動開啟商店（talkSheet dismiss → shopSheet open 時序處理）
- [x] 金幣掉落系統（人形怪物掉落金幣，processLoot 特殊處理 gold_coin）
- [x] NPC 有限庫存管理（運行時追蹤，場景切換時重置）
- [x] 出售物品交易技能經驗（每級 +1% 售價加成）
- [x] 新增人形怪物（哥布林、山賊）與對應掉落表
- [x] StatusView 顯示金幣
- [x] 交易系統單元測試 11 個（TradeTests.swift）

### 待開發
- [ ] 物品裝備/使用互動（背包內操作）
- [ ] 角色職業選擇流程（目前預設無業遊民）
- [ ] 存檔槽位已滿處理
- [ ] 戰鬥中使用消耗品（目前戰鬥為全自動）
