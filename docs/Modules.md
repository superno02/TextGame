# Modules.md — 功能模組分析

> 最後更新：2026-03-27（新增物品交易系統）

---

## 模組總覽

```
TextGame
├── App 進入點模組
├── Engine 模組
│   └── GameEngine
├── Views 模組
│   ├── StartView
│   ├── GameView（純 UI 層）
│   ├── SkillView
│   ├── InventoryView
│   ├── ShopView
│   └── StatusView
├── Models 模組
│   ├── 持久化 Model（SwiftData）
│   └── 模板與載入器
├── Enums 模組
├── Resources 模組（JSON 靜態資料）
└── Tests 模組
```

---

## 1. App 進入點模組

| 項目 | 內容 |
|------|------|
| **模組名稱** | App Entry |
| **功能說明** | App 啟動設定，初始化 SwiftData ModelContainer |
| **主要 Class** | `TextGameApp` |
| **主要檔案** | `TextGameApp.swift` |
| **模組責任** | 定義 Schema、建立 ModelContainer、設定根 View |
| **與其他模組的關係** | 依賴所有 `@Model` 類別建立 Schema；將 `StartView` 設為根畫面 |

---

## 2. Engine 模組

| 項目 | 內容 |
|------|------|
| **模組名稱** | 遊戲引擎 |
| **功能說明** | 管理所有遊戲邏輯狀態，與 View 層分離 |
| **主要 Class** | `GameEngine`（`@Observable`） |
| **主要檔案** | `Engine/GameEngine.swift` |
| **模組責任** | 訊息管理、場景移動、戰鬥系統、經驗值授予與升級處理、NPC 對話、商店交易、存檔觸發、模板載入錯誤檢查 |
| **與其他模組的關係** | 持有 `ModelContext`；依賴 `SceneTemplateLoader`、`MonsterTemplateLoader`、`NPCTemplateLoader`、`ItemTemplateLoader`、`LootTableLoader`；操作 `SaveSlot`、`PlayerCharacter`；被 `GameView` 初始化與使用 |

### 主要屬性
- `messages: [String]` — 訊息列表（上限 50 筆）
- `currentSceneId: String` — 當前場景 ID
- `showMoveSheet / showAttackSheet / showTalkSheet: Bool` — 彈窗控制
- `isInCombat: Bool` — 戰鬥狀態標記
- `combatMonster: CombatMonster?` — 當前戰鬥中的怪物實例
- `showShopSheet: Bool` — 商店介面顯示控制
- `currentShopNPC: NPCTemplate?` — 當前商店 NPC
- `npcStocks: [String: [String: Int]]` — NPC 庫存運行時追蹤（場景切換時重置）

### 主要方法
- `moveToScene(_ sceneId:)` — 場景移動
- `attackMonster(_ monster:)` — 發動攻擊，進入戰鬥迴圈
- `runCombatLoop()` — 回合制戰鬥迴圈（async，每回合延遲 0.8 秒）
- `executeCombatRound(character:monster:activeSkills:)` — 執行單一回合
- `executeMonsterAttack(character:monster:activeSkills:)` — 怪物攻擊階段
- `handleVictory(monster:character:)` — 勝利處理（經驗值授予、升級判定、掉落物）
- `handlePlayerDefeat(monster:character:)` — 死亡處理（傳送村莊）
- `processLoot(monster:character:)` — 掉落物處理（查詢 LootTableLoader，支援數量範圍）
- `grantArmorSkillExperience(...)` — 防具技能經驗發放
- `absorbCombatSkills(...)` — 回合結束吸收技能經驗
- `talkToNPC(_ npc:)` — NPC 對話（含條件過濾），商人 NPC 談話後設定 currentShopNPC
- `buyItem(from:shopItem:)` — 購買物品（扣金幣、扣庫存、加背包）
- `sellItem(to:item:)` — 出售物品（加金幣、移除物品、交易技能經驗）
- `shopItemsForNPC(_:)` — 回傳 NPC 可購買商品列表（含價格、庫存）
- `sellableItems()` — 回傳玩家可出售物品（排除裝備中物品）
- `saveGame()` — 存檔
- `appendMessage(_ text:)` — 訊息管理
- `onAppear()` — 初始場景描述

### 戰鬥相關結構（定義於 `GameEngine.swift`）
- `CombatMonster` — 戰鬥中怪物運行時狀態（包裝 `MonsterTemplate` + 可變 `currentHealth`）
- `RoundResult` — 回合結果列舉（continues / monsterDefeated / playerDefeated）
- `CombatCalculator` — 純函數戰鬥計算器（命中/閃避/傷害公式）
- `TradeCalculator` — 純函數交易計算器（購買價/出售價公式）

---

## 3. Views 模組

### 3.1 StartView

| 項目 | 內容 |
|------|------|
| **模組名稱** | 開始頁面 |
| **功能說明** | 遊戲入口，提供「開始遊戲」與「讀取存檔」兩個選項 |
| **主要 Class** | `StartView` |
| **主要檔案** | `Views/StartView.swift` |
| **模組責任** | 新角色建立、存檔槽位選擇、導航至 GameView |
| **與其他模組的關係** | 建立 `PlayerCharacter` 與 `SaveSlot`；導航至 `GameView` |

### 3.2 GameView（純 UI 層）

| 項目 | 內容 |
|------|------|
| **模組名稱** | 遊戲主畫面 |
| **功能說明** | 遊戲核心互動畫面，包含訊息輸出與操作按鈕 |
| **主要 Class** | `GameView` |
| **主要檔案** | `Views/GameView.swift` |
| **模組責任** | UI 渲染、將使用者操作轉發給 GameEngine、訊息顏色判斷 |
| **與其他模組的關係** | 初始化並持有 `GameEngine`（`@State`）；導航至 SkillView / InventoryView / StatusView（傳入 character）；掛載 ShopView（`.sheet`） |

### 3.3 SkillView

| 項目 | 內容 |
|------|------|
| **模組名稱** | 技能頁面 |
| **功能說明** | 按 4 大分類顯示角色技能與熟練度 |
| **主要 Class** | `SkillView` |
| **主要檔案** | `Views/SkillView.swift` |
| **模組責任** | 接收 `PlayerCharacter`，按戰鬥/生存/知識/魔法分類顯示技能等級與經驗值進度條 |
| **與其他模組的關係** | 依賴 `PlayerCharacter.skills`、`Skill`、`SkillCategory` |

### 3.4 InventoryView

| 項目 | 內容 |
|------|------|
| **模組名稱** | 背包頁面 |
| **功能說明** | 顯示角色裝備欄與背包物品 |
| **主要 Class** | `InventoryView` |
| **主要檔案** | `Views/InventoryView.swift` |
| **模組責任** | 接收 `PlayerCharacter`，按 7 個裝備部位顯示裝備狀態，列出背包中未裝備物品 |
| **與其他模組的關係** | 依賴 `PlayerCharacter.inventory`、`GameItem`、`EquipmentSlot` |

### 3.5 ShopView

| 項目 | 內容 |
|------|------|
| **模組名稱** | 商店頁面 |
| **功能說明** | NPC 商店購買/出售介面 |
| **主要 Class** | `ShopView` |
| **主要檔案** | `Views/ShopView.swift` |
| **模組責任** | 以 `.sheet` 呈現，顯示金幣餘額、購買/出售分頁（Segmented Picker）、商品價格與庫存、出售價格 |
| **與其他模組的關係** | 接收 `NPCTemplate`、`PlayerCharacter`、`GameEngine`；呼叫 `engine.buyItem()` / `engine.sellItem()` |

### 3.6 StatusView

| 項目 | 內容 |
|------|------|
| **模組名稱** | 屬性頁面 |
| **功能說明** | 顯示角色基本資訊、六大屬性、三大狀態值與金幣 |
| **主要 Class** | `StatusView` |
| **主要檔案** | `Views/StatusView.swift` |
| **模組責任** | 接收 `PlayerCharacter`，顯示名稱/職業/等階/經驗值進度條、六大屬性、生命/魔力/體力、金幣餘額 |
| **與其他模組的關係** | 依賴 `PlayerCharacter`（含 `experience`、`experienceToNextCircle`、`gold`）、`Guild.displayName` |

---

## 4. Models 模組 — 持久化 Model

### 4.1 PlayerCharacter

| 項目 | 內容 |
|------|------|
| **功能說明** | 玩家角色核心資料 |
| **主要檔案** | `Models/PlayerCharacter.swift` |
| **責任** | 儲存角色基本資訊（名稱、職業、等階）、六大屬性、三大狀態值、經驗值、金幣、目前位置；提供戰鬥輔助計算屬性與升級機制 |
| **初始化** | 從 `GuildTemplateLoader` 取得 `baseStats` 設定屬性，使用 `StatusFormula` 計算狀態值，具備 fallback |
| **關聯** | `@Relationship` → `[Skill]`（技能列表）、`[GameItem]`（背包物品） |
| **經驗值屬性** | `experience: Int`（持久化）、`experienceToNextCircle: Int`（`@Transient`，公式：circle × 50 + 50） |
| **經驗值方法** | `gainExperience(_ amount:) -> Bool` — 累加經驗值並觸發升級；`performLevelUp()` — 等階 +1、職業屬性成長、狀態值重算、全回復 |
| **戰鬥輔助屬性** | `equippedWeapon`、`equippedArmor`、`totalAttackPower`、`totalDefensePower`、`weaponSkillType`（皆為 `@Transient` 計算屬性） |
| **戰鬥輔助方法** | `skill(for: SkillType) -> Skill?` — 查找角色指定類型的技能 |

### 4.2 Skill

| 項目 | 內容 |
|------|------|
| **功能說明** | 角色技能資料 |
| **主要檔案** | `Models/Skill.swift` |
| **責任** | 記錄技能類型、等級、經驗值；實作實戰經驗吸收與升級機制 |
| **關聯** | 屬於 `PlayerCharacter` 的子物件 |

### 4.3 GameItem

| 項目 | 內容 |
|------|------|
| **功能說明** | 遊戲物品資料 |
| **主要檔案** | `Models/GameItem.swift` |
| **責任** | 儲存物品屬性（攻擊/防禦/回復）、裝備狀態、堆疊、素質修正、使用條件判斷 |
| **關聯** | 屬於 `PlayerCharacter` 的子物件；可從 `ItemTemplate` 建立實例 |

### 4.4 SaveSlot

| 項目 | 內容 |
|------|------|
| **功能說明** | 存檔槽位 |
| **主要檔案** | `Models/SaveSlot.swift` |
| **責任** | 記錄存檔編號、角色摘要資訊、存檔時間、累計遊戲時間 |
| **關聯** | `@Relationship` → `PlayerCharacter?` |

---

## 5. Models 模組 — 模板與載入器

所有 Loader 均為 Singleton，具備 `loadError: String?` 追蹤載入狀態。

### 5.1 SceneTemplate / SceneTemplateLoader

| 項目 | 內容 |
|------|------|
| **功能說明** | 場景定義與載入 |
| **主要檔案** | `Models/SceneTemplate.swift`、`Models/GameScene.swift` |
| **責任** | 從 `scenes.json` 載入場景資料；提供場景查詢、NPC 查詢；轉換為運行時 `GameScene` |
| **JSON 資料** | 6 個場景：村莊、市集、村口、後山、深山、林間小路 |

### 5.2 MonsterTemplate / MonsterTemplateLoader

| 項目 | 內容 |
|------|------|
| **功能說明** | 怪物定義與載入 |
| **主要檔案** | `Models/MonsterTemplate.swift` |
| **責任** | 從 `monsters.json` 載入怪物資料；支援按場景/等級篩選；透過 `lootTableId` 引用掉落表 |
| **JSON 資料** | 6 種怪物：兔子、雞、野豬、灰狼、哥布林、山賊 |

### 5.3 NPCTemplate / NPCTemplateLoader

| 項目 | 內容 |
|------|------|
| **功能說明** | NPC 定義與載入 |
| **主要檔案** | `Models/NPCTemplate.swift` |
| **責任** | 從 `npcs.json` 載入 NPC 資料；支援條件式對話過濾、商人篩選 |
| **JSON 資料** | 7 個 NPC：村長老伯、旅行商人、鐵匠老張、藥婆、皮匠阿福、守衛阿強、隱居老者 |

### 5.4 ItemTemplate / ItemTemplateLoader

| 項目 | 內容 |
|------|------|
| **功能說明** | 物品模板定義與載入 |
| **主要檔案** | `Models/ItemTemplate.swift` |
| **責任** | 從 `items.json` 載入物品模板；作為建立 `GameItem` 實例的藍圖 |
| **JSON 資料** | 16 種物品：武器（4）、防具（5）、消耗品（3）、素材（2）、雜物（1）、職業專用（1） |

### 5.5 GuildTemplate / GuildTemplateLoader

| 項目 | 內容 |
|------|------|
| **功能說明** | 職業定義與載入 |
| **主要檔案** | `Models/GuildTemplate.swift` |
| **責任** | 從 `guilds.json` 載入職業資料；提供基礎屬性、技能分類、狀態值計算公式、升級屬性成長（`CircleGrowth`）；供 `PlayerCharacter` 初始化與升級使用 |
| **資料結構** | `GuildTemplate` → `GuildBaseStats`、`StatusFormula`、`CircleGrowth`（每次升級六大屬性成長值，合計 +6） |
| **JSON 資料** | 5 種職業：無業遊民、戰士、法師、盜賊、牧師 |

### 5.6 LootTableTemplate / LootTableLoader

| 項目 | 內容 |
|------|------|
| **功能說明** | 掉落表定義與載入 |
| **主要檔案** | `Models/LootTableTemplate.swift` |
| **責任** | 從 `loot_tables.json` 載入掉落表資料；定義每個掉落項目的物品 ID、掉落機率與數量範圍（minQuantity~maxQuantity） |
| **資料結構** | `LootTableTemplate` → `LootEntry`（itemId、dropRate、minQuantity、maxQuantity） |
| **JSON 資料** | 4 張掉落表：兔子掉落表、雞掉落表、哥布林掉落表（金幣）、山賊掉落表（金幣+藥水） |
| **與其他模組的關係** | 被 `GameEngine.processLoot()` 查詢使用；`MonsterTemplate.lootTableId` 引用掉落表 ID |

---

## 6. Enums 模組

| 項目 | 內容 |
|------|------|
| **功能說明** | 集中定義所有列舉型別 |
| **主要檔案** | `Models/Enums.swift`、`Models/GameItem.swift`（`ItemType`） |
| **包含列舉** | `Guild`（5 種職業）、`SkillCategory`（5 大分類）、`SkillType`（21 種技能）、`EquipmentSlot`（7 個部位）、`ItemType`（6 種物品類型） |
| **特色** | 所有列舉均提供中文 `displayName` 計算屬性 |
| **戰鬥相關** | `SkillType.weaponSkillType(for: String) -> SkillType?` — 將武器物品 ID（含流水號前綴，如 `01_01_iron_sword`）映射到對應的武器技能類型 |

---

## 7. Resources 模組

所有 JSON 資源檔的 ID 採用 **流水號前綴格式**：`{類別碼}_{序號}_{原始名稱}`（類別碼 2 位、序號 2 位）。

| 檔案 | 類別碼 | 內容 | 資料量 |
|------|:------:|------|--------|
| `items.json` | `01_` | 物品模板（屬性、修正、條件） | 16 種物品 |
| `monsters.json` | `02_` | 怪物定義（屬性、lootTableId、出沒場景） | 6 種怪物 |
| `scenes.json` | `03_` | 場景定義（名稱、描述、出口、怪物、NPC） | 6 個場景 |
| `npcs.json` | `04_` | NPC 定義（對話、商店、服務類型） | 7 個 NPC |
| `guilds.json` | `05_` | 職業定義（屬性、技能、公式） | 5 種職業 |
| `loot_tables.json` | `06_` | 掉落表定義（物品、機率、數量範圍） | 4 張掉落表 |

---

## 8. Tests 模組

使用 **Swift Testing** 框架（`import Testing`、`@Test`、`#expect`）。

| 檔案 | 測試項目 | 數量 |
|------|----------|------|
| `PlayerCharacterTests.swift` | 角色初始屬性、狀態值、職業對應、經驗值與升級 | 20 |
| `SkillTests.swift` | 經驗吸收、升級、技能分類、顯示名稱 | 9 |
| `GameItemTests.swift` | 使用條件、堆疊判斷、裝備部位 | 9 |
| `TemplateLoaderTests.swift` | 6 個 Loader 載入驗證、資料查詢 | 15 |
| `NPCTemplateTests.swift` | 條件對話過濾、商人判定 | 6 |
| `CombatTests.swift` | 戰鬥公式（命中/閃避/傷害 clamping）、CombatMonster 狀態、角色戰鬥屬性、武器技能映射 | 26 |
| `TradeTests.swift` | 交易價格計算（購買價、出售價、交易技能加成、角色初始金幣） | 11 |
| **合計** | | **97（不含 UI 測試）** |
