# TextGame 專案設定

## 語言
- 永遠使用繁體中文回答，包含所有提示訊息

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

## 開發規範
- 代碼開發規範依照 `ios-developer.md` 的內容執行
- 當指令 `\開發` 時，進入開發作業模式
  - 若有指定 class 或檔案，則僅專注開發該檔案
  - 若無指定，則依照開發進度進行下一項任務

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
- Model 層使用 SwiftData（`@Model`）
- 保持 View 簡潔，複雜邏輯抽取至獨立方法或 ViewModel

---

## 檔案用途說明

| 檔案 | 用途 |
|------|------|
| `TextGameApp.swift` | App 進入點，啟動時顯示 StartView，設定 SwiftData ModelContainer |
| `Views/StartView.swift` | 遊戲開始頁面，提供「開始遊戲」與「讀取存檔」選項 |
| `Views/GameView.swift` | 遊戲主畫面，上半訊息輸出區 + 下半操作區 |
| `Views/SkillView.swift` | 技能頁面，顯示角色技能與熟練度 |
| `Views/InventoryView.swift` | 背包頁面，顯示角色攜帶物品與裝備 |
| `Views/StatusView.swift` | 屬性頁面，顯示角色基本屬性與狀態 |
| `Models/Enums.swift` | 列舉定義：職業(Guild)、技能分類(SkillCategory)、技能類型(SkillType)、裝備欄位(EquipmentSlot) |
| `Models/PlayerCharacter.swift` | 玩家角色 Model，含基本資訊、六大屬性、狀態值、技能與背包關聯 |
| `Models/Skill.swift` | 技能 Model，含技能類型、等級、經驗值與實戰經驗吸收機制 |
| `Models/GameScene.swift` | 場景結構，定義場景描述、出口列表與怪物資訊 |
| `Models/GameItem.swift` | 物品 Model，含類型、數值屬性與裝備功能 |
| `Models/SaveSlot.swift` | 存檔槽位 Model，支援多存檔，關聯角色資料 |

---

## 開發進度

### 已完成
- [x] 專案初始化建立
- [x] 確立遊戲風格（MUD 文字遊戲，參考 DragonRealms）
- [x] 定義畫面結構（直立畫面，上半訊息輸出、下半操作區）
- [x] 建立開始頁面 StartView（開始遊戲 / 讀取存檔）
- [x] 建立遊戲主畫面 GameView（訊息區 + 指令輸入區）
- [x] 建立技能頁面 SkillView（框架）
- [x] 建立背包頁面 InventoryView（框架）
- [x] 建立屬性頁面 StatusView（框架）
- [x] 更新 App 進入點指向 StartView

### 待開發
- [x] 移除範例檔案（ContentView.swift、Item.swift）
- [x] 設計遊戲核心 Model（角色、技能、場景、物品、存檔）
- [x] 實作 GameView 訊息輸出區域（等寬字型、顏色區分、上限 50 筆、自動捲動）
- [x] 實作 GameView 操作按鈕（移動、攻擊、技能、物品、屬性）
- [x] 實作移動彈窗（選單式地點選擇：村莊、後山）
- [x] 實作攻擊彈窗（選擇敵對生物：兔子、雞）
- [x] 實作 StartView 開始遊戲流程（預設角色：路人甲/無業遊民）
- [x] 實作 StartView 讀取存檔彈窗（5 個槽位，顯示角色名與存檔時間）
- [x] 設定 SwiftData ModelContainer
- [ ] 實作遊戲引擎（指令解析、場景管理、戰鬥系統）
- [x] 實作存檔/讀檔功能（離開前景自動存檔、5 槽位各對應一個角色）
- [ ] 各子頁面（技能、背包、屬性）內容填充
