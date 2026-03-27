# ImportantFlows.md — 重要流程文件

> 最後更新：2026-03-27（JSON ID 流水號前綴化）

---

## 1. App Launch Flow（App 啟動流程）

### 相關 Class
`TextGameApp` → `StartView`

### 流程說明

```
@main TextGameApp.init()
  │
  ├─ 建立 Schema（PlayerCharacter, Skill, GameItem, SaveSlot）
  ├─ 建立 ModelConfiguration
  ├─ 嘗試建立 ModelContainer
  │   ├─ 成功 → 繼續
  │   └─ 失敗（Schema 不相容）
  │       ├─ 刪除舊資料庫檔案（default.store, -wal, -shm）
  │       └─ 重新建立 ModelContainer
  │           ├─ 成功 → 繼續
  │           └─ 失敗 → fatalError 終止
  │
  ▼
WindowGroup
  ├─ StartView()（根畫面）
  └─ .modelContainer(modelContainer)（注入資料庫）
```

### 同時發生：模板載入

```
各 TemplateLoader.shared 首次存取時（lazy init）
  ├─ SceneTemplateLoader → 載入 scenes.json（6 個場景）
  ├─ MonsterTemplateLoader → 載入 monsters.json（4 種怪物）
  ├─ NPCTemplateLoader → 載入 npcs.json（7 個 NPC）
  ├─ ItemTemplateLoader → 載入 items.json（15 種物品）
  ├─ GuildTemplateLoader → 載入 guilds.json（5 種職業）
  └─ LootTableLoader → 載入 loot_tables.json（2 張掉落表）

每個 Loader 載入失敗時會設定 loadError: String?
```

---

## 2. New Game Flow（開始新遊戲流程）

### 相關 Class
`StartView` → `PlayerCharacter` → `GuildTemplateLoader` → `SaveSlot` → `GameView` → `GameEngine`

### 流程說明

```
使用者點擊「開始遊戲」
  │
  ▼
StartView.startNewGame()
  │
  ├─ 查詢現有存檔槽位
  ├─ 找到第一個空槽位（1~5）
  │   └─ 若全滿 → 不做處理（目前未處理此情況）
  │
  ├─ 建立 PlayerCharacter（名稱：路人甲，職業：無業遊民）
  │   ├─ GuildTemplateLoader.shared.template(for: .none) → baseStats
  │   ├─ 設定六大屬性（從 GuildBaseStats 取得）
  │   ├─ StatusFormula.calculate() → 計算狀態值
  │   └─ 設定初始位置（03_01_village）
  │
  ├─ 建立 SaveSlot（關聯角色）
  ├─ 插入 ModelContext
  │
  ▼
navigationDestination 觸發
  │
  ▼
GameView(slotIndex: emptySlot)
  │
  ├─ .task → 初始化 GameEngine(slotIndex:, modelContext:)
  │   ├─ 載入場景資料快取
  │   ├─ 恢復角色位置（currentSceneId）
  │   └─ checkTemplateErrors()（檢查模板載入錯誤）
  │
  └─ GameEngine.onAppear() → 顯示場景描述
```

---

## 3. Load Game Flow（讀取存檔流程）

### 相關 Class
`StartView` → `SaveSlot` → `GameView` → `GameEngine`

### 流程說明

```
使用者點擊「讀取存檔」
  │
  ▼
顯示 loadSaveSheet（.sheet）
  │
  ├─ 列出 5 個槽位
  │   ├─ 有存檔 → 顯示角色名 + 存檔時間 → 可點擊
  │   └─ 空槽位 → 顯示「空」→ 不可點擊
  │
  ▼
使用者選擇存檔槽位
  │
  ├─ 設定 activeSlotIndex
  ├─ 關閉彈窗
  ├─ isGameStarted = true
  │
  ▼
navigationDestination 觸發 → GameView(slotIndex:)
  │
  ▼
GameEngine 初始化
  ├─ FetchDescriptor<SaveSlot> 查詢對應存檔
  └─ 恢復 character.currentSceneId
```

---

## 4. GameEngine 初始化流程

### 相關 Class
`GameView` → `GameEngine`

### 流程說明

```
GameView.body
  │
  ├─ .task（首次出現）
  │   └─ engine = GameEngine(slotIndex:, modelContext:)
  │
  ▼
GameEngine.init()
  │
  ├─ 快取所有場景 → scenes = SceneTemplateLoader.shared.allGameScenes()
  ├─ 取得 currentSaveSlot（FetchDescriptor）
  ├─ 恢復角色位置 → currentSceneId = character.currentSceneId
  └─ checkTemplateErrors()
      ├─ 檢查 6 個 Loader 的 loadError
      └─ 有錯誤 → appendMessage("[系統錯誤] ...")
```

---

## 5. Scene Movement Flow（場景移動流程）

### 相關 Class
`GameView` → `GameEngine` → `SceneTemplateLoader` → `PlayerCharacter`

### 流程說明

```
使用者點擊「移動」按鈕
  │
  ▼
engine.showMoveSheet = true
  │
  ▼
顯示 moveSheet → 列出 engine.availableExits
  │
  ▼
使用者選擇目的地
  │
  ▼
engine.moveToScene(sceneId)
  │
  ├─ 從 scenes 字典查詢目標場景
  ├─ 更新 engine.currentSceneId
  ├─ 同步更新 character.currentSceneId（持久化）
  ├─ appendMessage("——————————")
  ├─ appendMessage("你來到了【場景名稱】")
  └─ appendMessage(場景描述)
```

---

## 6. Attack & Combat Flow（攻擊與戰鬥流程）

### 相關 Class
`GameView` → `GameEngine` → `MonsterTemplateLoader` → `CombatMonster` → `CombatCalculator` → `LootTableLoader` → `ItemTemplateLoader` → `PlayerCharacter` → `Skill`

### 流程說明

```
使用者點擊「攻擊」按鈕
  │
  ├─ engine.isInCombat == true
  │   └─ appendMessage("你正在戰鬥中！") → 結束
  │
  ├─ engine.availableMonsters 為空
  │   └─ appendMessage("這裡沒有可以攻擊的目標。") → 結束
  │
  ▼
engine.showAttackSheet = true → 列出怪物（名稱 + 等級 + HP）
  │
  ▼
使用者選擇目標
  │
  ▼
engine.attackMonster(monster)
  │
  ├─ combatMonster = CombatMonster(template: monster)
  ├─ isInCombat = true
  ├─ appendMessage("你對{怪物名}發起了攻擊！")
  │
  ▼
Task { @MainActor } → runCombatLoop()
  │
  ├─ while isInCombat（每回合延遲 0.8 秒）
  │   │
  │   ├─ 1. 玩家攻擊
  │   │   ├─ 命中率判定（CombatCalculator.calculateHitChance）
  │   │   ├─ 命中 → 傷害計算 → 武器技能經驗 1.0 + level × 0.5
  │   │   └─ 未命中 → 武器技能經驗 0.5
  │   │
  │   ├─ 2. 怪物死亡判定
  │   │   └─ isDead → handleVictory()
  │   │       ├─ 授予角色經驗值（monster.template.experience）
  │   │       ├─ character.gainExperience() → 升級判定
  │   │       ├─ 升級 → 屬性成長 + 狀態值重算 + 全回復
  │   │       └─ processLoot() → 結束戰鬥
  │   │
  │   ├─ 3. 怪物攻擊
  │   │   ├─ 閃避率判定（CombatCalculator.calculateDodgeChance）
  │   │   ├─ 閃避成功 → 閃避技能經驗 1.5 + level × 0.5
  │   │   └─ 被擊中 → 傷害計算 → 防具技能經驗（每件 0.5 + level × 0.3）
  │   │
  │   ├─ 4. 玩家死亡判定
  │   │   └─ HP <= 0 → handlePlayerDefeat() → 傳送村莊、恢復半血 → 結束戰鬥
  │   │
  │   └─ 5. absorbCombatSkills() → 吸收回合中觸發的技能經驗
  │
  └─ 戰鬥結束：isInCombat = false, combatMonster = nil
```

### 掉落物子流程

```
handleVictory() → processLoot(monster:, character:)
  │
  ├─ monster.lootTableId 為 nil？ → 結束（無掉落表）
  ├─ LootTableLoader.shared.template(for: lootTableId) → LootTableTemplate
  │   └─ 查無掉落表 → 結束
  │
  ├─ 遍歷 lootTable.entries（LootEntry）
  │   ├─ 擲骰 < entry.dropRate → 掉落成功
  │   │   ├─ ItemTemplateLoader.template(for: entry.itemId)
  │   │   ├─ 決定數量 → Int.random(in: minQuantity...maxQuantity)
  │   │   ├─ 逐一加入背包：
  │   │   │   ├─ 背包已有相同物品且可堆疊且未滿？
  │   │   │   │   ├─ 是 → stackCount += 1
  │   │   │   │   └─ 否 → GameItem(from: template) → 加入 inventory
  │   │   │   └─ 重複 quantity 次
  │   │   └─ appendMessage("你獲得了【物品名】。" 或 "...x數量。")
  │   └─ 擲骰 >= entry.dropRate → 未掉落
  │
  └─ 結束
```

### 死亡子流程

```
handlePlayerDefeat()
  │
  ├─ appendMessage("你被{怪物名}擊敗了...")
  ├─ character.currentHealth = maxHealth / 2（最低 1）
  ├─ character.currentStamina = maxStamina / 2（最低 1）
  ├─ character.currentSceneId = "03_01_village"
  ├─ currentSceneId = "03_01_village"
  └─ appendMessage("你在村莊中醒來，身體還很虛弱...")
```

---

## 7. NPC Talk Flow（NPC 對話流程）

### 相關 Class
`GameView` → `GameEngine` → `SceneTemplateLoader` → `NPCTemplateLoader` → `NPCTemplate`

### 流程說明

```
使用者點擊「談話」按鈕
  │
  ├─ engine.availableNPCs 為空
  │   └─ engine.appendMessage("這裡沒有可以交談的對象。") → 結束
  │
  ▼
engine.showTalkSheet = true → 列出 NPC（名稱 + 頭銜）
  │
  ▼
使用者選擇 NPC
  │
  ▼
engine.talkToNPC(npc)
  │
  ├─ 取得玩家職業（currentSaveSlot?.character?.guild）
  ├─ npc.availableDialogues(playerGuild:) → 過濾條件對話
  │   ├─ condition == nil → 無條件顯示
  │   └─ condition == "guild:05_02_warrior" → 僅戰士可觸發
  │
  ├─ appendMessage("你向【NPC名】搭話。")
  ├─ 若無可用對話 → "沒有說話。"
  └─ 若有對話 → 隨機選擇一段顯示
```

---

## 8. Auto Save Flow（自動存檔流程）

### 相關 Class
`GameView` → `GameEngine` → `SaveSlot` → `PlayerCharacter`

### 流程說明

```
App 進入非活躍狀態
  │
  ▼
GameView.onChange(of: scenePhase)
  │
  ├─ newPhase == .inactive
  │
  ▼
engine.saveGame()
  │
  ├─ FetchDescriptor 取得 currentSaveSlot
  ├─ slot.updateSaveInfo(character:, playTime:)
  │   ├─ 更新角色名稱、職業、等階
  │   └─ 更新存檔時間（Date()）
  └─ modelContext.save()
```

---

## 9. Sub-Page Navigation Flow（子頁面導航流程）

### 相關 Class
`GameView` → `GameEngine` → `SkillView` / `InventoryView` / `StatusView`

### 流程說明

```
GameView.actionButtonsView
  │
  ├─ engine.currentSaveSlot?.character → 取得角色
  │   └─ 若為 nil → 不顯示按鈕
  │
  ▼
NavigationLink（技能 / 物品 / 屬性）
  │
  ├─ SkillView(character: character)
  │   ├─ 按 SkillCategory 分 4 組（戰鬥/生存/知識/魔法）
  │   └─ 每個技能顯示等級 + ProgressView
  │
  ├─ InventoryView(character: character)
  │   ├─ 裝備欄：EquipmentSlot.allCases（7 部位）
  │   └─ 背包：未裝備物品列表
  │
  └─ StatusView(character: character)
      ├─ 基本資訊（名稱、職業、等階、經驗值進度條）
      ├─ 六大屬性
      └─ 三大狀態值
```

---

## 10. Skill Experience Flow（技能經驗流程）

### 相關 Class
`GameEngine` → `PlayerCharacter` → `Skill`

### 流程說明

```
戰鬥中觸發技能使用
  │
  ├─ 玩家攻擊命中 → weaponSkill.gainFieldExperience(1.0 + level × 0.5)
  ├─ 玩家攻擊未命中 → weaponSkill.gainFieldExperience(0.5)
  ├─ 閃避成功 → evasion.gainFieldExperience(1.5 + level × 0.5)
  └─ 被擊中 → 每件防具對應技能.gainFieldExperience(0.5 + level × 0.3)
  │
  ▼
Skill.gainFieldExperience(amount)
  │
  ├─ fieldExperience += amount
  │
  ▼
每回合結束時 → absorbCombatSkills()
  │
  ├─ 遍歷回合中觸發的技能類型（activeSkills: Set<SkillType>）
  │
  ▼
Skill.absorbExperience()
  │
  ├─ 每次最多吸收 10 點 fieldExperience
  ├─ experience += absorbed
  │
  ├─ while experience >= experienceToNextRank
  │   ├─ experience -= experienceToNextRank
  │   └─ rank += 1
  │
  └─ experienceToNextRank = rank * 100.0 + 50.0
```

---

## 11. Character Level Up Flow（角色升級流程）

### 相關 Class
`GameEngine` → `PlayerCharacter` → `GuildTemplateLoader` → `CircleGrowth` → `StatusFormula`

### 流程說明

```
handleVictory() 中授予經驗值
  │
  ▼
character.gainExperience(monster.template.experience)
  │
  ├─ experience += amount
  │
  ├─ while experience >= experienceToNextCircle（= circle × 50 + 50）
  │   │
  │   ▼
  │   performLevelUp()
  │     │
  │     ├─ experience -= experienceToNextCircle（扣除已用經驗值）
  │     ├─ circle += 1
  │     │
  │     ├─ GuildTemplateLoader.shared.template(for: guild)
  │     │   └─ circleGrowth → CircleGrowth
  │     │       ├─ strength += growth.strength
  │     │       ├─ agility += growth.agility
  │     │       ├─ constitution += growth.constitution
  │     │       ├─ intelligence += growth.intelligence
  │     │       ├─ wisdom += growth.wisdom
  │     │       └─ charisma += growth.charisma
  │     │
  │     ├─ 重算狀態值（StatusFormula.calculate）
  │     │   ├─ maxHealth = healthFormula.calculate(constitution)
  │     │   ├─ maxMana = manaFormula.calculate(intelligence)
  │     │   └─ maxStamina = staminaFormula.calculate(strength)
  │     │
  │     └─ 全回復（currentHealth/Mana/Stamina = max）
  │
  ├─ 回傳是否升級（Bool）
  │
  ▼
GameEngine（升級訊息輸出）
  ├─ appendMessage("你獲得了 {N} 點經驗值。")
  ├─ 若升級：
  │   ├─ appendMessage("你的等階提升到了 {circle}！")
  │   ├─ appendMessage("屬性成長：力量+N、敏捷+N、...")
  │   └─ appendMessage("HP/MP/SP 已完全回復！")
  └─ processLoot()
```

### 升級門檻公式

| Circle | 所需經驗值 |
|:------:|:----------:|
| 1 → 2 | 100 |
| 2 → 3 | 150 |
| 3 → 4 | 200 |
| N → N+1 | N × 50 + 50 |

### 各職業每次升級屬性成長（合計皆 +6）

| 職業 | STR | AGI | CON | INT | WIS | CHA |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| 無業遊民 | +1 | +1 | +1 | +1 | +1 | +1 |
| 戰士 | +2 | +1 | +2 | +0 | +0 | +1 |
| 法師 | +0 | +1 | +0 | +3 | +2 | +0 |
| 盜賊 | +1 | +3 | +1 | +1 | +0 | +0 |
| 牧師 | +1 | +0 | +1 | +1 | +2 | +1 |

---

## 12. Template Loading Flow（模板載入流程）

### 相關 Class
所有 `*TemplateLoader`

### 通用流程

```
*TemplateLoader.shared（Singleton，首次存取觸發）
  │
  ▼
init() → loadTemplates() / loadData()
  │
  ├─ loadError = nil（重置）
  ├─ Bundle.main.url(forResource:, withExtension: "json")
  │   └─ 失敗 → loadError = "找不到 *.json" → return
  │
  ├─ Data(contentsOf: url)
  ├─ JSONDecoder().decode(Container.self, from: data)
  │   └─ 失敗 → loadError = "載入失敗：..." → return
  │
  ├─ 轉換為 [String: Template] 字典
  └─ print 載入數量

GameEngine.init() 中統一檢查所有 loadError
  └─ 有錯誤 → appendMessage("[系統錯誤] ...")
```
