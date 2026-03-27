# Architecture.md — 專案架構文件

> 最後更新：2026-03-27（JSON ID 流水號前綴化）

---

## 1. 專案概述

### App 功能

TextGame 是一款 **MUD（Multi-User Dungeon）風格的純文字角色扮演遊戲**，參考經典遊戲 DragonRealms 的玩法設計。遊戲以中文呈現所有內容，玩家透過選單式操作與遊戲世界互動。

### 主要用途

- 單機離線文字冒險遊戲
- 玩家可建立角色、探索場景、與 NPC 互動、戰鬥怪物
- 支援多存檔槽位（5 個）
- 技能制成長系統（使用即提升）

---

## 2. 架構模式

本專案採用 **SwiftUI + SwiftData + @Observable Engine** 的架構，整體設計為 **View + Engine + Model** 三層分離：

| Layer | 說明 |
|-------|------|
| **View** | SwiftUI View，負責 UI 渲染與使用者互動 |
| **Engine** | `@Observable` 遊戲引擎，管理遊戲邏輯狀態 |
| **Model** | SwiftData `@Model` 類別，負責資料持久化 |
| **Template / Loader** | JSON 靜態資料模板與 Singleton 載入器，提供遊戲內容定義 |

### 各 Layer 的角色

- **View Layer**：接收使用者輸入（按鈕點擊）、顯示遊戲訊息、管理導航。View 不直接處理遊戲邏輯，而是轉發給 Engine。
- **Engine Layer**：`GameEngine`（`@Observable`）管理場景移動、攻擊、NPC 對話、存檔、訊息管理等遊戲核心邏輯。持有 `ModelContext` 進行資料操作。
- **Model Layer**：定義持久化資料結構（角色、技能、物品、存檔）
- **Template Layer**：從 JSON 載入遊戲靜態內容（場景、怪物、NPC、物品、職業定義），每個 Loader 具備 `loadError` 錯誤狀態追蹤

---

## 3. Layer 說明

### UI Layer

- 使用 SwiftUI 構建，所有畫面均為 `View` struct
- 直立（Portrait）方向顯示
- 主要結構：上半部訊息輸出區 + 下半部操作按鈕區
- 使用 `NavigationStack` 管理畫面導航
- 使用 `.sheet()` 呈現彈窗選單（移動、攻擊、談話）
- 子頁面（SkillView、InventoryView、StatusView）接收 `PlayerCharacter` 參數，確保多存檔時顯示正確角色

### Engine Layer

- `GameEngine`（`@Observable`）為遊戲邏輯核心
- 在 GameView 的 `.task` 中以 `ModelContext` 注入方式初始化
- 管理：訊息列表、場景狀態、彈窗控制、戰鬥狀態
- 提供方法：moveToScene、attackMonster（完整戰鬥迴圈）、talkToNPC、saveGame
- 內含 `CombatCalculator`（純函數）與 `CombatMonster`（運行時怪物狀態）
- 戰鬥使用 `Task` + `async/await` 實現回合制延遲效果
- 啟動時自動檢查所有 TemplateLoader 的載入錯誤

### Network Layer

- **本專案無網路功能**，為純離線遊戲
- 所有資料均來自本地 Bundle JSON 與 SwiftData 持久化儲存

### Data Layer

- **SwiftData**：角色（`PlayerCharacter`）、技能（`Skill`）、物品（`GameItem`）、存檔（`SaveSlot`）
- **Bundle JSON**：場景（`scenes.json`）、怪物（`monsters.json`）、NPC（`npcs.json`）、物品模板（`items.json`）、職業定義（`guilds.json`）、掉落表（`loot_tables.json`）

### ID 命名規範

所有 JSON 資源檔的 ID 採用 **流水號前綴格式**：`{類別碼}_{序號}_{原始名稱}`

| 類別碼 | 類別 | 範例 |
|:------:|------|------|
| `01_` | 物品（items） | `01_01_iron_sword` |
| `02_` | 怪物（monsters） | `02_01_rabbit` |
| `03_` | 場景（scenes） | `03_01_village` |
| `04_` | NPC | `04_01_village_elder` |
| `05_` | 職業（guilds） | `05_01_none` |
| `06_` | 掉落表（loot_tables） | `06_01_loot_rabbit` |

- 類別碼 2 位數、序號 2 位數，按各 JSON 檔案中現有順序編號
- 所有交叉引用（如 `spawnScenes`、`lootTableId`、`shopItems[].itemId`、`condition` 中的職業 ID）均使用完整前綴格式
- `Guild` enum 的 `rawValue` 與 JSON 中的職業 ID 保持一致（如 `case warrior = "05_02_warrior"`）
- NPC 對話條件格式：`"guild:05_02_warrior"`（`guild:` 前綴 + 完整職業 ID）

---

## 4. 專案目錄結構

```
TextGame/
├── TextGame/
│   ├── TextGameApp.swift          # App 進入點
│   ├── Engine/                    # 遊戲引擎
│   │   └── GameEngine.swift       # @Observable 遊戲邏輯核心
│   ├── Views/                     # SwiftUI 畫面
│   │   ├── StartView.swift        # 遊戲開始頁面
│   │   ├── GameView.swift         # 遊戲主畫面（純 UI 層）
│   │   ├── SkillView.swift        # 技能頁面（按分類顯示技能與熟練度）
│   │   ├── InventoryView.swift    # 背包頁面（裝備欄 + 背包物品）
│   │   └── StatusView.swift       # 屬性頁面（基本資訊、屬性、狀態）
│   ├── Models/                    # 資料模型
│   │   ├── Enums.swift            # 列舉定義
│   │   ├── PlayerCharacter.swift  # 玩家角色 Model（使用 GuildTemplate 初始化）
│   │   ├── Skill.swift            # 技能 Model
│   │   ├── GameItem.swift         # 物品 Model
│   │   ├── GameScene.swift        # 場景結構
│   │   ├── SaveSlot.swift         # 存檔槽位 Model
│   │   ├── GuildTemplate.swift    # 職業模板與載入器
│   │   ├── ItemTemplate.swift     # 物品模板與載入器
│   │   ├── LootTableTemplate.swift # 掉落表模板與載入器
│   │   ├── MonsterTemplate.swift  # 怪物模板與載入器
│   │   ├── NPCTemplate.swift      # NPC 模板與載入器
│   │   └── SceneTemplate.swift    # 場景模板與載入器
│   ├── Resources/                 # 靜態資料檔案
│   │   ├── guilds.json            # 職業定義
│   │   ├── items.json             # 物品定義
│   │   ├── loot_tables.json       # 掉落表定義
│   │   ├── monsters.json          # 怪物定義
│   │   ├── npcs.json              # NPC 定義
│   │   └── scenes.json            # 場景定義
│   └── Assets.xcassets            # 資源檔案
├── TextGameTests/                 # 單元測試（Swift Testing）
│   ├── PlayerCharacterTests.swift # 角色初始化測試
│   ├── SkillTests.swift           # 技能經驗與升級測試
│   ├── GameItemTests.swift        # 物品條件判斷測試
│   ├── TemplateLoaderTests.swift  # 模板載入驗證測試
│   └── NPCTemplateTests.swift     # NPC 對話條件測試
└── TextGameUITests/               # UI 測試
```

---

## 5. 核心元件

### GameEngine（@Observable）

| Class | 責任 |
|-------|------|
| `GameEngine` | 遊戲邏輯核心，管理訊息、場景、戰鬥系統、對話、存檔；持有 ModelContext 與所有 TemplateLoader 引用 |

### SwiftData Model

| Class | 責任 |
|-------|------|
| `PlayerCharacter` | 玩家角色持久化資料，初始屬性從 GuildTemplate 載入，含技能與背包關聯 |
| `Skill` | 角色技能，記錄類型、等級、經驗值與實戰經驗吸收機制 |
| `GameItem` | 遊戲物品，支援裝備、堆疊、屬性修正與使用條件 |
| `SaveSlot` | 存檔槽位，關聯角色資料，記錄存檔時間與遊戲時間 |

### Template Loader（Singleton）

| Class | 責任 |
|-------|------|
| `SceneTemplateLoader.shared` | 載入場景 JSON，提供場景查詢、NPC 查詢 |
| `MonsterTemplateLoader.shared` | 載入怪物 JSON，支援按場景、等級範圍篩選 |
| `NPCTemplateLoader.shared` | 載入 NPC JSON，支援商人篩選、對話條件過濾 |
| `ItemTemplateLoader.shared` | 載入物品模板 JSON，支援按類型篩選 |
| `GuildTemplateLoader.shared` | 載入職業定義 JSON，提供屬性公式計算 |
| `LootTableLoader.shared` | 載入掉落表 JSON，怪物透過 lootTableId 查詢掉落物品、機率與數量範圍 |

所有 Loader 均具備 `loadError: String?` 屬性，載入失敗時記錄錯誤訊息。

### 資料結構（Value Type）

| Struct | 責任 |
|--------|------|
| `GameScene` / `SceneExit` | 運行時場景結構 |
| `GuildBaseStats` / `StatusFormula` | 職業屬性與狀態值計算公式 |
| `StatModifiers` / `ItemRequirements` | 物品素質修正與使用條件 |
| `LootEntry` | 掉落表項目定義（物品 ID、機率、數量範圍） |
| `LootTableTemplate` | 掉落表模板（ID、名稱、掉落項目列表） |
| `NPCDialogue` / `NPCShopItem` | NPC 對話與商店定義 |
| `CombatMonster` | 戰鬥中怪物運行時狀態（可變 HP） |
| `CombatCalculator` | 戰鬥數值計算純函數（命中/閃避/傷害/逃跑公式） |
| `RoundResult` | 戰鬥回合結果列舉（繼續/怪物死亡/玩家死亡/逃跑） |

---

## 6. Network Layer

**本專案無 Network Layer。**

所有遊戲資料均來自：
- Bundle 內的 JSON 檔案（靜態遊戲內容）
- SwiftData 本地儲存（玩家進度資料）

---

## 7. Data Storage

| 儲存方式 | 用途 |
|----------|------|
| **SwiftData** | 角色資料、技能、物品、存檔槽位的持久化 |
| **Bundle JSON** | 遊戲靜態內容定義（場景、怪物、NPC、物品模板、職業、掉落表） |
| UserDefaults | 未使用 |
| Keychain | 未使用 |
| CoreData | 未使用（使用 SwiftData 取代） |

### SwiftData Schema

在 `TextGameApp.init()` 中定義：

```swift
Schema([
    PlayerCharacter.self,
    Skill.self,
    GameItem.self,
    SaveSlot.self
])
```

具備 Schema 不相容時自動刪除舊資料庫並重建的容錯機制。

---

## 8. 第三方套件

**本專案未使用任何第三方套件。**

完全使用 Apple 原生框架：
- SwiftUI
- SwiftData
- Foundation
- Observation（`@Observable` macro）

---

## 9. 技術債

### 已解決

1. ~~GameView 職責過重~~ → 已抽取 `GameEngine`（`@Observable`）管理遊戲邏輯
2. ~~缺少遊戲引擎層~~ → 已建立 `Engine/GameEngine.swift`
3. ~~子頁面未填充~~ → SkillView 已實作技能分類顯示，InventoryView 已實作裝備欄與背包列表
4. ~~PlayerCharacter 初始屬性硬編碼~~ → 已改用 `GuildTemplateLoader` 的 `baseStats` 與 `StatusFormula`
5. ~~StatusView 角色查詢方式~~ → 所有子頁面改為接收 `PlayerCharacter` 參數
6. ~~測試覆蓋率為零~~ → 已新增 50 個 Swift Testing 測試案例
7. ~~缺少錯誤處理機制~~ → 所有 TemplateLoader 加入 `loadError`，GameEngine 啟動時檢查並顯示

### 尚待開發

1. ~~**戰鬥系統**~~ → 已實作完整回合制戰鬥（命中/閃避/傷害/掉落物/死亡處理/逃跑/技能經驗）

2. **商店系統**
   - NPC 商店資料已在 JSON 中定義（`NPCShopItem`），但尚未實作購買/販售 UI 與邏輯

3. **角色建立選擇**
   - 目前新遊戲一律建立「路人甲/無業遊民」，應提供職業選擇介面

4. **存檔槽位已滿處理**
   - StartView 中 5 個槽位全滿時無提示
