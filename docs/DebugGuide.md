# DebugGuide.md — 除錯指南

> 最後更新：2026-03-18（技術債修復後）
> 目的：幫助工程師與 AI 快速定位 bug

---

## 1. 常見錯誤位置

### App 啟動失敗

| 症狀 | 檢查位置 | 說明 |
|------|----------|------|
| App 閃退於啟動 | `TextGameApp.swift:24-42` | ModelContainer 建立失敗 |
| Console "ModelContainer 建立失敗" | `TextGameApp.swift:28` | Schema 不相容觸發重建機制 |
| fatalError 終止 | `TextGameApp.swift:40` | 重建也失敗，Schema 定義有誤 |

**處理方式**：刪除 App 資料或檢查 `@Model` 類別的屬性變更。

### JSON 載入失敗

| 症狀 | 檢查位置 | 說明 |
|------|----------|------|
| 遊戲訊息區顯示「[系統錯誤]」 | `GameEngine.swift` → `checkTemplateErrors()` | Loader 的 `loadError` 不為 nil |
| "找不到 *.json" | 各 `*TemplateLoader` | JSON 檔案未加入 Bundle Target |
| "載入 *.json 失敗" | 各 `*TemplateLoader` | JSON 格式錯誤或與 Codable 結構不符 |
| 場景/怪物/NPC 為空 | `GameEngine` 的計算屬性 | Loader 未成功載入資料 |

**處理方式**：
1. 確認 JSON 檔案在 Xcode 的 Target Membership 中已勾選
2. 驗證 JSON 格式正確性
3. 確認 Codable struct 的欄位名與 JSON key 完全對應
4. 檢查各 Loader 的 `loadError` 屬性

### GameEngine 初始化問題

| 症狀 | 檢查位置 | 說明 |
|------|----------|------|
| 畫面一直顯示「載入中…」| `GameView.swift` → `.task` | engine 未成功初始化 |
| 角色位置未恢復 | `GameEngine.swift` → `init` | `currentSaveSlot?.character` 為 nil |
| FetchDescriptor 查不到存檔 | `GameEngine.swift` → `currentSaveSlot` | slotIndex 不匹配 |

---

## 2. 各功能問題檢查指南

### 場景問題

| 症狀 | 檢查檔案 | 檢查重點 |
|------|----------|----------|
| 移動後場景不更新 | `GameEngine.swift` → `moveToScene()` | `currentSceneId` 是否正確更新 |
| 場景描述不顯示 | `GameEngine.swift` → `moveToScene()` | `scenes[sceneId]` 是否為 nil |
| 出口列表為空 | `Resources/scenes.json` | 場景的 `exits` 陣列是否正確 |
| 怪物不出現 | `Resources/monsters.json` | `spawnScenes` 是否包含當前場景 ID |
| NPC 不出現 | `Resources/scenes.json` | 場景的 `npcs` 陣列是否包含對應 NPC ID |

### NPC 對話問題

| 症狀 | 檢查檔案 | 檢查重點 |
|------|----------|----------|
| NPC 不說話 | `NPCTemplate.swift` → `availableDialogues()` | 對話條件是否符合當前角色 |
| 條件對話不觸發 | `Resources/npcs.json` | `condition` 格式是否為 `"guild:warrior"` |
| 顯示空白對話 | `NPCTemplate.swift` | `dialogues` 陣列是否為空 |

### 存檔問題

| 症狀 | 檢查檔案 | 檢查重點 |
|------|----------|----------|
| 存檔未生效 | `GameView.swift` → `onChange(of: scenePhase)` | 是否正確呼叫 `engine.saveGame()` |
| 讀檔後資料錯誤 | `GameEngine.swift` → `currentSaveSlot` | FetchDescriptor 的 `slotIndex` 比對 |
| 角色資料遺失 | `SaveSlot.swift` | `@Relationship` cascade 設定 |
| 新遊戲無法建立 | `StartView.swift` → `startNewGame()` | 5 個槽位是否已滿 |

### 子頁面問題

| 症狀 | 檢查檔案 | 檢查重點 |
|------|----------|----------|
| 技能/物品/屬性按鈕不顯示 | `GameView.swift` → `actionButtonsView` | `engine.currentSaveSlot?.character` 是否為 nil |
| 技能列表全空 | `SkillView.swift` | `character.skills` 是否有資料（新角色預設為空） |
| 背包全空 | `InventoryView.swift` | `character.inventory` 是否有資料（新角色預設為空） |
| 屬性顯示錯誤角色 | `GameView.swift` → NavigationLink | 確認傳入的 `character` 來自正確的 `engine.currentSaveSlot` |

### 物品問題

| 症狀 | 檢查檔案 | 檢查重點 |
|------|----------|----------|
| 物品無法裝備 | `GameItem.swift` → `canBeUsedBy()` | 角色屬性是否滿足需求 |
| 物品類型顯示錯誤 | `GameItem.swift` | `itemTypeRawValue` 與 `ItemType` rawValue 是否一致 |
| 從模板建立失敗 | `GameItem.swift` → `init(from:)` | `ItemTemplate` 欄位是否完整 |

### 角色初始屬性問題

| 症狀 | 檢查檔案 | 檢查重點 |
|------|----------|----------|
| 所有職業屬性都是 10 | `PlayerCharacter.swift` → `init` | `GuildTemplateLoader.shared` 是否載入成功 |
| 狀態值計算不正確 | `GuildTemplate.swift` → `StatusFormula.calculate()` | `guilds.json` 的公式定義是否正確 |

---

## 3. 核心邏輯檔案

| 優先級 | 檔案 | 理由 |
|--------|------|------|
| 🔴 高 | `Engine/GameEngine.swift` | 遊戲邏輯核心，管理所有遊戲狀態 |
| 🔴 高 | `Views/GameView.swift` | UI 層入口，初始化 Engine |
| 🔴 高 | `Models/PlayerCharacter.swift` | 角色核心資料，SwiftData Schema |
| 🔴 高 | `TextGameApp.swift` | ModelContainer 與 Schema 定義 |
| 🟡 中 | `Models/SaveSlot.swift` | 存檔機制核心 |
| 🟡 中 | `Models/GameItem.swift` | 物品系統核心，條件判斷邏輯 |
| 🟡 中 | `Models/Skill.swift` | 技能成長系統核心 |
| 🟡 中 | `Models/SceneTemplate.swift` | 場景資料載入與轉換 |
| 🟡 中 | `Models/GuildTemplate.swift` | 職業屬性公式，角色初始化依賴 |
| 🟢 低 | `Models/Enums.swift` | 列舉定義，修改需同步更新 JSON |

---

## 4. SwiftData Schema 變更注意事項

⚠️ 修改 `@Model` 類別時特別注意：

1. **新增屬性**：必須提供預設值，否則現有資料庫無法遷移
2. **刪除屬性**：`TextGameApp.init()` 會嘗試刪除舊資料庫重建
3. **修改屬性型別**：會導致 Schema 不相容
4. **修改 `@Relationship`**：需要同時更新關聯雙方

### 受影響的 Model

```
PlayerCharacter → Skill[]、GameItem[]
SaveSlot → PlayerCharacter?
```

---

## 5. 可能的記憶體管理風險

### 目前風險較低

1. **訊息列表**
   - 位置：`GameEngine.messages`
   - 風險：已設定上限 50 筆，風險低

2. **Template Loader Singleton**
   - 位置：各 `*TemplateLoader.shared`
   - 風險：Singleton 生命週期等同 App，資料量小，風險低

3. **SwiftData 關聯物件**
   - 位置：`PlayerCharacter.skills`、`PlayerCharacter.inventory`
   - 風險：使用 `@Relationship(deleteRule: .cascade)`，自動清除

4. **GameEngine 生命週期**
   - 位置：`GameView` 的 `@State private var engine: GameEngine?`
   - 風險：`@State` 管理生命週期，View 消失時自動釋放。Engine 持有 ModelContext 參考但不造成循環引用。

---

## 6. 日誌追蹤指南

### 關鍵日誌位置

| 日誌前綴 | 檔案 | 用途 |
|----------|------|------|
| `[TextGameApp]` | `TextGameApp.swift` | ModelContainer 建立狀態 |
| `[SceneTemplateLoader]` | `SceneTemplate.swift` | 場景載入結果 |
| `[MonsterTemplateLoader]` | `MonsterTemplate.swift` | 怪物載入結果 |
| `[NPCTemplateLoader]` | `NPCTemplate.swift` | NPC 載入結果 |
| `[ItemTemplateLoader]` | `ItemTemplate.swift` | 物品載入結果 |
| `[GuildTemplateLoader]` | `GuildTemplate.swift` | 職業載入結果 |

### 正常啟動 Console 輸出
```
[GuildTemplateLoader] 已載入 5 個職業模板
[SceneTemplateLoader] 已載入 6 個場景
[MonsterTemplateLoader] 已載入 4 個怪物模板
[NPCTemplateLoader] 已載入 7 個 NPC 模板
[ItemTemplateLoader] 已載入 15 個物品模板
```

### 遊戲內錯誤訊息
若任何 Loader 載入失敗，遊戲訊息區會顯示紅色文字：
```
[系統錯誤] 場景資料載入失敗：找不到 scenes.json
```

---

## 7. 測試相關除錯

### 測試檔案結構

| 檔案 | 測試內容 | 數量 |
|------|----------|------|
| `PlayerCharacterTests.swift` | 初始屬性、狀態值、職業對應 | 13 |
| `SkillTests.swift` | 經驗吸收、升級、分類、公式 | 9 |
| `GameItemTests.swift` | 使用條件、堆疊、裝備 | 9 |
| `TemplateLoaderTests.swift` | 5 個 Loader 載入驗證 | 12 |
| `NPCTemplateTests.swift` | 條件對話、商人判定 | 6 |

### 測試環境注意事項

- TemplateLoader 使用 `Bundle.main`，在測試環境中指向 test bundle
- JSON 檔案需在 test target 的 Copy Bundle Resources 中
- SwiftData `@Model` 物件在測試中可直接建立，無需 ModelContainer（除非測試持久化行為）

---

## 8. 常見除錯情境

### 情境 A：新增 JSON 怪物但遊戲中未出現

1. 確認 `monsters.json` 格式正確
2. 確認新怪物的 `spawnScenes` 包含期望場景 ID
3. 確認場景 ID 與 `scenes.json` 一致
4. 重新啟動 App，檢查 Console 日誌
5. 確認遊戲內無「[系統錯誤]」訊息

### 情境 B：修改 PlayerCharacter 欄位後 App 閃退

1. Schema 不相容觸發重建
2. 檢查新欄位是否有提供預設值
3. 清除 App 資料或解除安裝重裝

### 情境 C：子頁面按鈕不顯示

1. 檢查 `engine.currentSaveSlot?.character` 是否為 nil
2. 確認 `GameEngine.currentSaveSlot` 的 FetchDescriptor 能找到對應存檔
3. 確認 `slotIndex` 在 StartView 中正確傳遞

### 情境 D：角色初始屬性全為 10

1. 確認 `guilds.json` 已加入 app bundle
2. 確認 `GuildTemplateLoader.shared.loadError` 為 nil
3. 若 Loader 載入失敗，PlayerCharacter 會 fallback 為全 10
