# 專案開發規則

> 此文件僅包含通用開發流程規則，適用於任何專案。
> 專案特定資訊請參閱 `docs/ProjectIndex.md`。

---

## 語言
- 永遠使用繁體中文回答，包含所有提示訊息

---

## 可用指令

以下指令在 Claude Code CLI 與 Xcode Coding Assistant 兩個環境中皆可使用，統一以 `/指令名稱` 觸發：

| 指令 | 用途 |
|------|------|
| `/start` | Session 初始化 — 閱讀專案文檔，建立開發上下文 |
| `/dev` | 進入開發作業模式 — 依指定目標或開發進度執行開發任務 |
| `/end` | Session 結束 — 根據本次變更同步更新受影響的 `docs/` 文件 |

指令定義位於 `.claude/commands/*.md`，兩個環境皆透過 Skill 機制載入執行。

## 開發規範

- 代碼開發規範依照 `ios-developer` skill 的內容執行（位於 `.claude/skills/ios-developer/SKILL.md`）
