# DependencyMap.md — 依賴關係圖

> 最後更新：2026-03-27（新增物品交易系統）

---

## 1. 整體依賴概覽

```
TextGameApp
  ├── SwiftData Schema
  │   ├── PlayerCharacter
  │   ├── Skill
  │   ├── GameItem
  │   └── SaveSlot
  └── StartView（根畫面）

StartView
  ├── SwiftData ModelContext
  ├── SaveSlot（@Query）
  ├── PlayerCharacter（建立新角色）
  │   └── GuildTemplateLoader（取得 baseStats）
  └── GameView（導航目標）

GameView
  ├── @Environment(\.modelContext) → 注入 GameEngine
  ├── @Environment(\.scenePhase) → 觸發存檔
  ├── @State GameEngine?（.task 中初始化）
  ├── SkillView(character:)（NavigationLink）
  ├── InventoryView(character:)（NavigationLink）
  ├── StatusView(character:)（NavigationLink）
  └── ShopView(npc:, character:, engine:)（.sheet，talkSheet dismiss 後觸發）

GameEngine（@Observable）
  ├── ModelContext（init 注入）
  ├── SaveSlot（FetchDescriptor 查詢）
  │   └── PlayerCharacter
  │       ├── equippedWeapon / equippedArmor（@Transient）
  │       ├── totalAttackPower / totalDefensePower（@Transient）
  │       ├── skill(for: SkillType) → Skill
  │       └── gainExperience() → performLevelUp() → GuildTemplateLoader（CircleGrowth + StatusFormula）
  ├── SceneTemplateLoader.shared
  ├── MonsterTemplateLoader.shared
  ├── NPCTemplateLoader.shared
  ├── ItemTemplateLoader.shared（掉落物品模板查詢）
  ├── LootTableLoader.shared（掉落表查詢）
  ├── CombatMonster（戰鬥運行時狀態）
  ├── CombatCalculator（戰鬥公式計算）
  ├── TradeCalculator（交易價格計算）
  ├── npcStocks: [String: [String: Int]]（NPC 庫存運行時追蹤）
  └── loadError 檢查 → 6 個 Loader

SkillView
  └── PlayerCharacter.skills → [Skill]

InventoryView
  └── PlayerCharacter.inventory → [GameItem]

ShopView
  ├── NPCTemplate（NPC 商店資料）
  ├── PlayerCharacter（金幣餘額、背包物品）
  └── GameEngine（buyItem / sellItem / shopItemsForNPC / sellableItems）

StatusView
  └── PlayerCharacter（直接讀取屬性，含 gold）
```

---

## 2. 資料模型依賴關係

```
PlayerCharacter（@Model）
  ├── Guild（列舉，透過 guildRawValue）
  ├── GuildTemplateLoader（init 時取得 baseStats + StatusFormula；升級時取得 CircleGrowth）
  ├── gold: Int（金幣，初始 100）
  ├── experience: Int（經驗值）→ gainExperience() → performLevelUp()
  ├── Skill[]（@Relationship, cascade delete）
  │   └── SkillType（列舉）
  │       └── SkillCategory（計算屬性）
  ├── GameItem[]（@Relationship, cascade delete）
  │   ├── ItemType（列舉，透過 itemTypeRawValue）
  │   └── EquipmentSlot（列舉，透過 equipSlotRawValue）
  └── currentSceneId: String

SaveSlot（@Model）
  ├── PlayerCharacter?（@Relationship, cascade delete）
  └── Guild（列舉，透過 characterGuildRawValue）
```

---

## 3. 模板載入器依賴關係

```
SceneTemplateLoader.shared
  ├── scenes.json（Bundle 資源）
  ├── SceneTemplate → SceneExitTemplate
  ├── GameScene / SceneExit（運行時結構）
  └── loadError: String?

MonsterTemplateLoader.shared
  ├── monsters.json（Bundle 資源）
  ├── MonsterTemplate → lootTableId: String?（引用掉落表）
  └── loadError: String?

LootTableLoader.shared
  ├── loot_tables.json（Bundle 資源）
  ├── LootTableTemplate → [LootEntry]（itemId / dropRate / minQuantity / maxQuantity）
  └── loadError: String?

NPCTemplateLoader.shared
  ├── npcs.json（Bundle 資源）
  ├── NPCTemplate → NPCDialogue / NPCShopItem
  ├── Guild（對話條件判斷）
  └── loadError: String?

ItemTemplateLoader.shared
  ├── items.json（Bundle 資源）
  ├── ItemTemplate → StatModifiers / ItemRequirements
  └── loadError: String?

GuildTemplateLoader.shared
  ├── guilds.json（Bundle 資源）
  ├── GuildTemplate → GuildBaseStats / StatusFormula / CircleGrowth
  └── loadError: String?
```

---

## 4. View → 資料存取路徑

### StartView
```
StartView
  → @Query SaveSlot（讀取現有存檔列表）
  → GuildTemplateLoader.shared（透過 PlayerCharacter.init）
  → modelContext.insert(PlayerCharacter)（建立角色）
  → modelContext.insert(SaveSlot)（建立存檔）
```

### GameView → GameEngine
```
GameView
  → .task → GameEngine(slotIndex:, modelContext:)

GameEngine
  → FetchDescriptor<SaveSlot>（查詢對應存檔）
  → SaveSlot.character（取得當前角色）
  → SceneTemplateLoader.shared.allGameScenes()（載入所有場景）
  → SceneTemplateLoader.shared.npcIdsInScene()（查詢場景 NPC）
  → MonsterTemplateLoader.shared.monstersInScene()（查詢場景怪物）
  → NPCTemplateLoader.shared.templates(for:)（取得 NPC 模板）
  → NPCTemplate.availableDialogues(playerGuild:)（過濾對話）
  → CombatMonster(template:)（建立戰鬥怪物實例）
  → CombatCalculator.*（戰鬥公式計算）
  → PlayerCharacter.gainExperience()（經驗值授予、升級判定）
  → GuildTemplateLoader.shared.template(for:).circleGrowth（升級屬性成長）
  → LootTableLoader.shared.template(for:)（掉落表查詢）
  → ItemTemplateLoader.shared.template(for:)（掉落物品模板查詢）
  → PlayerCharacter.skill(for:)（技能查詢）
  → Skill.gainFieldExperience() / absorbExperience()（技能經驗）
  → TradeCalculator.buyPrice() / sellPrice()（交易價格計算）
  → NPCTemplate.shopItems（NPC 商品列表）
  → npcStocks（NPC 庫存運行時追蹤）
  → SaveSlot.updateSaveInfo()（存檔）
  → modelContext.save()（持久化）
```

### 子頁面
```
SkillView(character:)
  → character.skills（按 SkillCategory 分組顯示）
  → Skill.displayName / rank / experience / fieldExperience

InventoryView(character:)
  → character.inventory.filter { $0.isEquipped }（裝備欄）
  → character.inventory.filter { !$0.isEquipped }（背包）
  → EquipmentSlot.allCases（7 個部位）

ShopView(npc:, character:, engine:)
  → npc.shopItems（NPC 商品列表）
  → engine.shopItemsForNPC(npc)（可購買商品 + 價格 + 庫存）
  → engine.sellableItems()（可出售物品）
  → engine.buyItem(from:, shopItem:)（購買）
  → engine.sellItem(to:, item:)（出售）
  → character.gold（金幣餘額）

StatusView(character:)
  → character.guild.displayName / circle / strength / ...
  → character.experience / experienceToNextCircle（經驗值進度條）
  → character.currentHealth / maxHealth / ...
  → character.gold（金幣餘額）
```

---

## 5. 物品建立依賴鏈

```
ItemTemplate（JSON 模板定義）
  │
  ▼
GameItem(from: ItemTemplate)（convenience init）
  │
  ├─ itemType ← ItemTemplate.type
  ├─ equipSlot ← ItemTemplate.equipSlot
  ├─ 數值屬性 ← ItemTemplate 各欄位
  ├─ statModifiers ← ItemTemplate.statModifiers
  └─ requirements ← ItemTemplate.requirements
  │
  ▼
PlayerCharacter.inventory（@Relationship）
  │
  ▼
GameItem.canBeUsedBy(character)（條件檢查）
  ├─ reqCircle vs character.circle
  ├─ reqGuilds vs character.guild
  └─ req* vs character.* 屬性
```

---

## 6. 角色建立依賴鏈

```
StartView.startNewGame()
  │
  ▼
PlayerCharacter(name:, guild:)
  │
  ├─ GuildTemplateLoader.shared.template(for: guild)
  │   └─ GuildTemplate.baseStats → GuildBaseStats
  │       ├─ strength, agility, constitution
  │       └─ intelligence, wisdom, charisma
  │
  ├─ GuildTemplate.healthFormula → StatusFormula
  │   └─ .calculate(attributeValue: constitution) → maxHealth
  ├─ GuildTemplate.manaFormula → StatusFormula
  │   └─ .calculate(attributeValue: intelligence) → maxMana
  └─ GuildTemplate.staminaFormula → StatusFormula
      └─ .calculate(attributeValue: strength) → maxStamina
```

---

## 7. 主要 Dependency Chain 總結

### 遊戲啟動鏈
```
TextGameApp → ModelContainer → StartView → GameView → GameEngine
```

### 場景互動鏈
```
GameView → GameEngine → SceneTemplateLoader → GameScene
```

### 戰鬥鏈
```
GameView → GameEngine → MonsterTemplateLoader → MonsterTemplate
                      → CombatMonster（運行時狀態）
                      → CombatCalculator（命中/閃避/傷害公式）
                      → PlayerCharacter.totalAttackPower / totalDefensePower
                      → PlayerCharacter.skill(for:) → Skill.gainFieldExperience()
                      → PlayerCharacter.gainExperience() → performLevelUp()
                      → GuildTemplateLoader（CircleGrowth + StatusFormula）
                      → LootTableLoader（monster.lootTableId → 掉落表查詢）
                      → ItemTemplateLoader（掉落物品模板查詢）
                      → GameItem(from: ItemTemplate)（加入背包）
```

### NPC 對話鏈
```
GameView → GameEngine → SceneTemplateLoader（場景 NPC IDs）
                      → NPCTemplateLoader（NPC 模板）
                      → NPCTemplate.availableDialogues（條件過濾）
                      → 商人 NPC → currentShopNPC 設定
```

### 商店交易鏈
```
GameView talkSheet.onDismiss → engine.showShopSheet = true
  → ShopView(npc:, character:, engine:)
    → engine.shopItemsForNPC(npc) → NPCTemplate.shopItems → ItemTemplateLoader → TradeCalculator.buyPrice()
    → engine.buyItem() → character.gold -= price, npcStocks 扣減, GameItem 加入背包
    → engine.sellableItems() → character.inventory（未裝備物品）
    → engine.sellItem() → TradeCalculator.sellPrice(), character.gold += price, Skill.trading 經驗
```

### 存檔鏈
```
GameView.scenePhase(.inactive) → engine.saveGame()
  → FetchDescriptor<SaveSlot> → slot.updateSaveInfo() → modelContext.save()
```

### 子頁面鏈
```
GameView → engine.currentSaveSlot?.character
  → SkillView(character:) / InventoryView(character:) / StatusView(character:)
  → ShopView(npc:, character:, engine:)（由 talkSheet dismiss 觸發）
```

### 角色建立鏈
```
StartView → PlayerCharacter(name:, guild:) → GuildTemplateLoader → GuildTemplate.baseStats + StatusFormula
```

### 角色升級鏈
```
handleVictory() → character.gainExperience(exp)
  → performLevelUp() → GuildTemplateLoader → CircleGrowth（屬性成長）+ StatusFormula（狀態值重算）
```
