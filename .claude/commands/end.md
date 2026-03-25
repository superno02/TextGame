根據本次 session 的所有程式碼變更，同步更新受影響的 `docs/` 文件。

## 更新範圍判斷

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

## 更新規則

1. 先用 `git diff` 檢視本次 session 的所有變更
2. 根據上表判斷哪些 `docs/` 文件需要更新
3. 逐一更新受影響的文件，更新「最後更新」時間戳
4. 若變更範圍小（如單行 bug fix），僅更新 `ProjectIndex.md` 開發進度即可
5. 完成後列出已更新的文件清單
