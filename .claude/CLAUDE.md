# 專案開發規則

> 此文件僅包含通用開發流程規則，適用於任何專案。
> 專案特定資訊請參閱 `docs/ProjectIndex.md`。

---

## 語言
- 永遠使用繁體中文回答，包含所有提示訊息

---

## Session 初始化（每次對話開始時必讀）

每次新對話開始時，**在進行任何開發或回答之前**，必須先閱讀以下文件以建立專案上下文：

1. **`docs/ProjectIndex.md`** — 專案概述、檔案索引、開發進度
2. **`docs/` 目錄中的技術文件** — 依任務類型選擇性閱讀

| 優先順序 | 文件 | 內容 |
|:--------:|------|------|
| 1 | `docs/ProjectOverview.md` | 專案總覽、技術棧、目錄結構 |
| 2 | `docs/Architecture.md` | 架構設計、資料流、關鍵設計決策 |
| 3 | `docs/CombatStats.md` | 數值系統（屬性、怪物、物品、技能公式） |
| 4 | `docs/Modules.md` | 各模組職責與檔案說明 |
| 5 | `docs/ImportantFlows.md` | 核心流程（啟動、存檔、場景移動、戰鬥、對話） |
| 6 | `docs/DependencyMap.md` | 模組間依賴關係 |
| 7 | `docs/CodeStyle.md` | 程式碼風格與命名規範 |
| 8 | `docs/DebugGuide.md` | 常見問題與除錯指南 |

**閱讀規則：**
- 若為**開發任務**（新功能、修 bug、重構）：至少閱讀 `ProjectIndex.md` + 優先順序 1~5
- 若為**數值調整或戰鬥相關**：必須額外閱讀 `docs/CombatStats.md`
- 若為**簡單問答**（如「某個檔案在哪」）：可僅閱讀此 CLAUDE.md 與 `ProjectIndex.md`
- 閱讀完畢後不需要向使用者報告，直接開始處理任務即可

---

## 開發規範

- 代碼開發規範依照 `ios-developer.md` 的內容執行
- 當指令 `\開發` 時，進入開發作業模式
  - 若有指定 class 或檔案，則僅專注開發該檔案
  - 若無指定，則依照 `docs/ProjectIndex.md` 中的開發進度進行下一項任務

---

## 文件同步更新（強制）

**每當完成一個需求開發或修改後，必須同步更新受影響的 `docs/` 文件。** 此為強制規則，不可跳過。

### 更新範圍判斷

| 變更類型 | 必須更新的文件 |
|----------|---------------|
| 新增/修改功能 | `ProjectOverview.md`（功能列表）、`ProjectIndex.md`（開發進度） |
| 新增/修改檔案 | `ProjectIndex.md`（檔案用途說明）、`Modules.md`（模組說明） |
| 新增/修改流程 | `ImportantFlows.md`（流程圖） |
| 新增/修改依賴 | `DependencyMap.md`（依賴關係） |
| 新增/修改架構 | `Architecture.md`（架構說明） |
| 新增/修改數值公式 | `CombatStats.md`（數值系統） |
| 新增/修改測試 | `ProjectIndex.md`（測試檔案表）、`Modules.md`（Tests 模組） |
| 修 bug | `DebugGuide.md`（若為常見問題）、`ProjectIndex.md`（開發進度） |

### 更新規則
- 程式碼變更完成且通過建置/測試後，立即更新文件
- 更新文件中的「最後更新」時間戳
- 不需要使用者提醒，開發完成後自動執行
- 若變更範圍小（如單行 bug fix），僅更新 `ProjectIndex.md` 開發進度即可
