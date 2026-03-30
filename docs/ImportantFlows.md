# ImportantFlows.md — 重要流程文件

> 最後更新：2026-03-30（對話系統改造：樹狀對話、NPC 好感度）

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
  ├─ MonsterTemplateLoader → 載入 monsters.json（6 種怪物）
  ├─ NPCTemplateLoader → 載入 npcs.json（7 個 NPC）
  ├─ ItemTemplateLoader → 載入 items.json（16 種物品）
  ├─ GuildTemplateLoader → 載入 guilds.json（5 種職業）
  └─ LootTableLoader → 載入 loot_tables.json（4 張掉落表）

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
  │   ├─ 有存檔 → 顯示角色名 + 存檔時間 → 可點擊 / 可左滑刪除
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

### 刪除存檔子流程

```
使用者在存檔槽位上左滑（swipeActions）
  │
  ▼
顯示紅色「刪除」按鈕
  │
  ▼
使用者點擊「刪除」
  │
  ├─ slotToDelete = slot
  ├─ showDeleteConfirmation = true
  │
  ▼
顯示確認 Alert（"確定要刪除槽位 N 的存檔「角色名」嗎？"）
  │
  ├─ 使用者點擊「取消」→ 關閉 Alert → 結束
  │
  ├─ 使用者點擊「刪除」
  │   │
  │   ▼
  │   deleteSaveSlot(slot)
  │     ├─ modelContext.delete(slot)
  │     │   └─ cascade → 自動刪除關聯的 PlayerCharacter（含 Skill、GameItem）
  │     ├─ modelContext.save()
  │     └─ slotToDelete = nil
  │
  ▼
@Query 自動更新 → 槽位顯示為「空」
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
  ├─ npcStocks.removeAll()（重置 NPC 庫存）
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
  │   │   ├─ 決定數量 → Int.random(in: minQuantity...maxQuantity)
  │   │   ├─ entry.itemId == "01_16_gold_coin"？
  │   │   │   ├─ 是 → character.gold += quantity
  │   │   │   │   └─ appendMessage("你獲得了 N 金幣。")
  │   │   │   └─ 否 → 一般物品處理：
  │   │   │       ├─ ItemTemplateLoader.template(for: entry.itemId)
  │   │   │       ├─ 逐一加入背包：
  │   │   │       │   ├─ 背包已有相同物品且可堆疊且未滿？
  │   │   │       │   │   ├─ 是 → stackCount += 1
  │   │   │       │   │   └─ 否 → GameItem(from: template) → 加入 inventory
  │   │   │       │   └─ 重複 quantity 次
  │   │   │       └─ appendMessage("你獲得了【物品名】。" 或 "...x數量。")
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
`GameView` → `GameEngine` → `SceneTemplateLoader` → `NPCTemplateLoader` → `NPCTemplate` → `DialogueNode` → `DialogueContext` → `PlayerCharacter`

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
使用者選擇 NPC → 關閉 talkSheet
  │
  ▼
engine.startDialogue(with: npc)
  │
  ├─ 建構 DialogueContext（guild、circle、inventoryItemIds、npcAffinity）
  ├─ npc.availableRootOptions(context:) → 過濾根選項
  │   ├─ evaluateCondition() 判斷每個根節點的 condition
  │   │   ├─ nil → 無條件通過
  │   │   ├─ "guild:05_02_warrior" → 職業匹配
  │   │   ├─ "circle:3" → 等階 >= 3
  │   │   ├─ "item:01_01_iron_sword" → 持有指定物品
  │   │   └─ "affinity:10" → 好感度 >= 10
  │   └─ 回傳符合條件的根選項列表
  │
  ├─ 設定對話狀態：
  │   ├─ currentTalkNPC = npc
  │   ├─ currentDialogueOptions = 過濾後的根選項
  │   └─ currentNPCResponse = nil（初始無回應）
  │
  ├─ appendMessage("你向【NPC名】搭話。")
  │
  ▼
GameView 偵測 engine.isInDialogue == true
  │
  ▼
下半部操作區切換為 dialogueOptionsView
  │
  ├─ 顯示 NPC 回應文字（currentNPCResponse，若有）
  ├─ 列出對話選項按鈕（currentDialogueOptions）
  │   └─ openShop 動作的選項旁顯示商店圖示
  └─ 永遠顯示「結束對話」按鈕
```

### 對話選項處理子流程

```
使用者點擊對話選項
  │
  ▼
engine.selectDialogueOption(option)
  │
  ├─ appendMessage("▸ {option.label}")（玩家選擇）
  ├─ appendMessage("{NPC名}：{option.response}")（NPC 回應）
  ├─ currentNPCResponse = option.response
  ├─ character.changeAffinity(for: npc.id, by: 1)（好感度 +1）
  │
  ├─ 檢查 option.action：
  │   ├─ "endDialogue" → endDialogue() → 結束
  │   ├─ "openShop" → currentShopNPC = npc → endDialogue()
  │   │   └─ GameView onChange(of: isInDialogue) → showShopSheet = true
  │   └─ nil → 繼續處理子選項
  │
  ├─ 檢查 option.goto：
  │   ├─ 有值 → npc.findNode(byId: goto) → 跳轉到目標節點
  │   │   └─ 顯示目標節點的子選項（過濾條件後）
  │   └─ nil → 顯示當前節點的子選項
  │
  ├─ npc.availableOptions(for: targetNode, context:) → 過濾子選項
  │   ├─ 子選項非空 → 更新 currentDialogueOptions
  │   └─ 子選項為空 → 自動 endDialogue()（葉節點）
  │
  ▼
dialogueOptionsView 更新顯示新選項
```

### 結束對話子流程

```
使用者點擊「結束對話」按鈕 / 自動結束（葉節點 / endDialogue 動作）
  │
  ▼
engine.endDialogue()
  │
  ├─ currentTalkNPC = nil
  ├─ currentDialogueOptions = []
  ├─ currentNPCResponse = nil
  │
  ▼
GameView 偵測 engine.isInDialogue == false
  │
  ├─ 下半部還原為正常操作按鈕
  │
  ├─ onChange(of: isInDialogue) 觸發：
  │   ├─ engine.currentShopNPC != nil？
  │   │   ├─ 是 → showShopSheet = true（開啟商店）
  │   │   └─ 否 → 結束
```

---

## 8. Save Flow（存檔流程）

### 相關 Class
`GameView` → `GameEngine` → `SaveSlot` → `PlayerCharacter`

### 自動存檔

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

### 手動存檔

```
使用者點擊 toolbar 右上角存檔按鈕（square.and.arrow.down）
  │
  ▼
engine.saveGame()
  │
  ├─ FetchDescriptor 取得 currentSaveSlot
  ├─ slot.updateSaveInfo(character:, playTime:)
  │   ├─ 更新角色名稱、職業、等階
  │   └─ 更新存檔時間（Date()）
  └─ modelContext.save()
  │
  ▼
engine.appendMessage("存檔完成。")
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

---

## 13. Shop Trade Flow（商店交易流程）

### 相關 Class
`GameView` → `GameEngine` → `NPCTemplateLoader` → `ItemTemplateLoader` → `TradeCalculator` → `ShopView` → `PlayerCharacter` → `GameItem` → `Skill`

### 流程說明

```
NPC 對話中選擇 openShop 動作（見 §7）
  │
  ▼
engine.selectDialogueOption() → action == "openShop"
  ├─ currentShopNPC = npc
  └─ endDialogue()
  │
  ▼
GameView onChange(of: isInDialogue) → showShopSheet = true
  │
  ▼
ShopView（.sheet, presentationDetents: [.medium, .large]）
  │
  ├─ 頂部：顯示金幣餘額（character.gold）
  ├─ Segmented Picker（購買 / 出售）
  │
  ├─ 【購買】
  │   ├─ engine.shopItemsForNPC(npc)
  │   │   ├─ 遍歷 npc.shopItems
  │   │   ├─ ItemTemplateLoader.template(for: itemId)
  │   │   └─ TradeCalculator.buyPrice(baseValue:, priceMultiplier:)
  │   │
  │   └─ 使用者點擊購買
  │       ├─ engine.buyItem(from: npc, shopItem:)
  │       │   ├─ 金幣不足？ → appendMessage("金幣不足！") → 結束
  │       │   ├─ 庫存售罄？ → appendMessage("已經賣完了。") → 結束
  │       │   ├─ character.gold -= buyPrice
  │       │   ├─ npcStocks 扣減庫存（有限庫存時）
  │       │   ├─ 加入背包（堆疊判斷同掉落物邏輯）
  │       │   └─ appendMessage("你用 N 金幣購買了【物品名】。")
  │       └─ UI 即時更新
  │
  └─ 【出售】
      ├─ engine.sellableItems()
      │   └─ 背包中未裝備的物品列表
      │
      └─ 使用者點擊出售
          ├─ engine.sellItem(to: npc, item:)
          │   ├─ TradeCalculator.sellPrice(baseValue:, tradingRank:)
          │   ├─ character.gold += sellPrice
          │   ├─ 堆疊物品？ → stackCount -= 1（若為 0 則從背包移除）
          │   ├─ 非堆疊物品？ → 從背包移除
          │   ├─ 交易技能經驗（trading skill）
          │   │   ├─ skill(for: .trading)?.gainFieldExperience(1.0)
          │   │   └─ skill(for: .trading)?.absorbExperience()
          │   └─ appendMessage("你賣給{NPC名}一個【物品名】，獲得 N 金幣。")
          └─ UI 即時更新
```

### 交易價格公式

```
購買價 = ceil(物品 value × NPC priceMultiplier)
出售價 = floor(物品 value × 0.5 × (1 + 交易技能等級 × 0.01))，最低 1
```

### NPC 庫存機制

```
NPC 商品 stock 值：
  ├─ stock == -1 → 無限庫存（顯示 ∞）
  └─ stock > 0 → 有限庫存
      ├─ 首次存取 → 初始化 npcStocks[npcId][itemId] = stock
      ├─ 購買成功 → npcStocks[npcId][itemId] -= 1
      └─ 場景切換 → npcStocks.removeAll()（庫存重置）
```
