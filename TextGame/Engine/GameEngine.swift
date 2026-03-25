//
//  GameEngine.swift
//  TextGame
//
//  Created by ant on 2026/3/18.
//

import Foundation
import SwiftData
import Observation

// MARK: - 戰鬥運行時結構

/// 戰鬥中的怪物運行時實例
struct CombatMonster {
    let template: MonsterTemplate
    var currentHealth: Int

    init(template: MonsterTemplate) {
        self.template = template
        self.currentHealth = template.health
    }

    var isDead: Bool { currentHealth <= 0 }
    var name: String { template.name }
    var attack: Int { template.attack }
    var defense: Int { template.defense }
    var level: Int { template.level }
}

/// 單回合結果
enum RoundResult {
    case continues
    case monsterDefeated
    case playerDefeated
}

/// 戰鬥數值計算器（純函數，方便測試）
enum CombatCalculator {

    /// 命中率：基礎 70%，敏捷 +1%/點，武器技能 +2%/級，怪物等級 -3%/級
    static func calculateHitChance(agility: Int, weaponSkillRank: Int, monsterLevel: Int) -> Double {
        let chance = 0.7 + Double(agility) * 0.01 + Double(weaponSkillRank) * 0.02 - Double(monsterLevel) * 0.03
        return min(max(chance, 0.3), 0.95)
    }

    /// 閃避率：基礎 5%，敏捷 +0.5%/點，閃避技能 +2%/級，怪物等級 -1%/級
    static func calculateDodgeChance(agility: Int, evasionRank: Int, monsterLevel: Int) -> Double {
        let chance = 0.05 + Double(agility) * 0.005 + Double(evasionRank) * 0.02 - Double(monsterLevel) * 0.01
        return min(max(chance, 0.02), 0.50)
    }

    /// 基礎傷害 = 攻擊力 - 防禦力，最低 1
    static func calculateBaseDamage(attackPower: Int, defense: Int) -> Int {
        max(attackPower - defense, 1)
    }

    /// 對基礎傷害套用隨機浮動（±20%）
    static func applyRandomVariance(_ base: Int) -> Int {
        let variance = Double.random(in: 0.8...1.2)
        return max(Int(round(Double(base) * variance)), 1)
    }

    /// 逃跑成功率：基礎 40%，敏捷 +1%/點，怪物等級 -5%/級
    static func calculateFleeChance(agility: Int, monsterLevel: Int) -> Double {
        let chance = 0.4 + Double(agility) * 0.01 - Double(monsterLevel) * 0.05
        return min(max(chance, 0.15), 0.80)
    }
}

/// 遊戲引擎，負責管理遊戲邏輯狀態（場景、訊息、攻擊、對話、存檔）
@Observable
final class GameEngine {

    // MARK: - 訊息列表（上限 50 筆）

    var messages: [String] = ["歡迎來到 TextGame 的世界。"]

    // MARK: - 場景狀態

    var currentSceneId: String = "village"

    // MARK: - 彈窗控制

    var showMoveSheet = false
    var showAttackSheet = false
    var showTalkSheet = false

    // MARK: - 戰鬥狀態

    var isInCombat: Bool = false
    private var combatMonster: CombatMonster?

    // MARK: - 依賴

    let slotIndex: Int
    private let modelContext: ModelContext
    private let sceneLoader = SceneTemplateLoader.shared
    private let monsterLoader = MonsterTemplateLoader.shared
    private let npcLoader = NPCTemplateLoader.shared
    private let itemLoader = ItemTemplateLoader.shared

    // MARK: - 快取

    private let scenes: [String: GameScene]

    // MARK: - 初始化

    init(slotIndex: Int, modelContext: ModelContext) {
        self.slotIndex = slotIndex
        self.modelContext = modelContext
        self.scenes = SceneTemplateLoader.shared.allGameScenes()

        // 恢復角色位置
        if let character = currentSaveSlot?.character {
            self.currentSceneId = character.currentSceneId
        }

        // 檢查模板載入錯誤
        checkTemplateErrors()
    }

    // MARK: - 計算屬性

    var currentScene: GameScene {
        scenes[currentSceneId] ?? scenes["village"]!
    }

    var currentSaveSlot: SaveSlot? {
        let targetSlot = slotIndex
        let descriptor = FetchDescriptor<SaveSlot>(
            predicate: #Predicate<SaveSlot> { slot in
                slot.slotIndex == targetSlot
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// 目前場景中可攻擊的怪物列表
    var availableMonsters: [MonsterTemplate] {
        monsterLoader.monstersInScene(currentSceneId)
    }

    /// 目前場景可前往的地點
    var availableExits: [SceneExit] {
        currentScene.exits
    }

    /// 目前場景中可談話的 NPC 列表
    var availableNPCs: [NPCTemplate] {
        let npcIds = sceneLoader.npcIdsInScene(currentSceneId)
        return npcLoader.templates(for: npcIds)
    }

    // MARK: - 生命週期

    /// GameView 出現時呼叫
    func onAppear() {
        appendMessage(currentScene.description)
    }

    // MARK: - 場景移動

    func moveToScene(_ sceneId: String) {
        guard let scene = scenes[sceneId] else { return }
        currentSceneId = sceneId
        // 同步更新角色位置
        if let character = currentSaveSlot?.character {
            character.currentSceneId = sceneId
        }
        appendMessage("——————————")
        appendMessage("你來到了【\(scene.name)】")
        appendMessage(scene.description)
    }

    // MARK: - 戰鬥系統

    /// 發動攻擊，進入戰鬥
    func attackMonster(_ monster: MonsterTemplate) {
        guard !isInCombat else {
            appendMessage("你正在戰鬥中！")
            return
        }

        guard let character = currentSaveSlot?.character else { return }

        combatMonster = CombatMonster(template: monster)
        isInCombat = true

        appendMessage("——————————")
        appendMessage("你對\(monster.name)發起了攻擊！")

        Task { @MainActor in
            await runCombatLoop()
        }
    }

    /// 戰鬥迴圈（async，使用 Task.sleep 產生逐行文字效果）
    @MainActor
    private func runCombatLoop() async {
        guard let character = currentSaveSlot?.character else {
            isInCombat = false
            combatMonster = nil
            return
        }

        var activeSkills: Set<SkillType> = []

        while isInCombat {
            guard var monster = combatMonster else { break }

            try? await Task.sleep(for: .milliseconds(800))

            let result = executeCombatRound(
                character: character,
                monster: &monster,
                activeSkills: &activeSkills
            )
            combatMonster = monster

            switch result {
            case .monsterDefeated:
                handleVictory(monster: monster, character: character)
            case .playerDefeated:
                handlePlayerDefeat(monster: monster, character: character)
            case .continues:
                absorbCombatSkills(character: character, skillTypes: activeSkills)
                continue
            }
            break
        }
    }

    /// 執行單一回合
    private func executeCombatRound(
        character: PlayerCharacter,
        monster: inout CombatMonster,
        activeSkills: inout Set<SkillType>
    ) -> RoundResult {
        // 1. 玩家攻擊
        let weaponSkill = character.weaponSkillType
        let weaponSkillRank = weaponSkill.flatMap { character.skill(for: $0)?.rank } ?? 0

        let hitChance = CombatCalculator.calculateHitChance(
            agility: character.agility,
            weaponSkillRank: weaponSkillRank,
            monsterLevel: monster.level
        )
        let hitRoll = Double.random(in: 0.0..<1.0)

        if hitRoll < hitChance {
            // 命中
            let baseDamage = CombatCalculator.calculateBaseDamage(
                attackPower: character.totalAttackPower,
                defense: monster.defense
            )
            let damage = CombatCalculator.applyRandomVariance(baseDamage)
            monster.currentHealth -= damage

            let weaponDesc = character.equippedWeapon != nil ? "揮動武器攻擊" : "揮拳攻擊"
            let hpDisplay = max(monster.currentHealth, 0)
            appendMessage("你\(weaponDesc)\(monster.name)，造成了 \(damage) 點傷害！[\(hpDisplay)/\(monster.template.health)]")

            // 武器技能經驗
            if let ws = weaponSkill {
                let expGain = 1.0 + Double(monster.level) * 0.5
                character.skill(for: ws)?.gainFieldExperience(expGain)
                activeSkills.insert(ws)
            }
        } else {
            // 未命中
            appendMessage("你的攻擊被\(monster.name)閃開了！")

            if let ws = weaponSkill {
                character.skill(for: ws)?.gainFieldExperience(0.5)
                activeSkills.insert(ws)
            }
        }

        // 3. 怪物死亡判定
        if monster.isDead { return .monsterDefeated }

        // 4. 怪物攻擊
        let _ = executeMonsterAttack(
            character: character,
            monster: monster,
            activeSkills: &activeSkills
        )

        // 5. 玩家死亡判定
        if character.currentHealth <= 0 { return .playerDefeated }

        return .continues
    }

    /// 怪物攻擊結果
    private enum MonsterAttackResult {
        case dodged
        case hit
    }

    /// 執行怪物攻擊階段
    private func executeMonsterAttack(
        character: PlayerCharacter,
        monster: CombatMonster,
        activeSkills: inout Set<SkillType>
    ) -> MonsterAttackResult {
        let evasionRank = character.skill(for: .evasion)?.rank ?? 0
        let dodgeChance = CombatCalculator.calculateDodgeChance(
            agility: character.agility,
            evasionRank: evasionRank,
            monsterLevel: monster.level
        )
        let dodgeRoll = Double.random(in: 0.0..<1.0)

        if dodgeRoll < dodgeChance {
            // 閃避成功
            appendMessage("\(monster.name)向你撲來，你靈巧地閃開了！")
            let expGain = 1.5 + Double(monster.level) * 0.5
            character.skill(for: .evasion)?.gainFieldExperience(expGain)
            activeSkills.insert(.evasion)
            return .dodged
        } else {
            // 被擊中
            let baseDamage = CombatCalculator.calculateBaseDamage(
                attackPower: monster.attack,
                defense: character.totalDefensePower
            )
            let damage = CombatCalculator.applyRandomVariance(baseDamage)
            character.currentHealth -= damage
            let hpDisplay = max(character.currentHealth, 0)
            appendMessage("\(monster.name)向你發動攻擊，造成了 \(damage) 點傷害！[HP: \(hpDisplay)/\(character.maxHealth)]")

            // 防具技能經驗
            grantArmorSkillExperience(character: character, monsterLevel: monster.level, activeSkills: &activeSkills)
            return .hit
        }
    }

    /// 勝利處理
    private func handleVictory(monster: CombatMonster, character: PlayerCharacter) {
        appendMessage("——————————")
        appendMessage("\(monster.name)倒下了！")

        // 授予角色經驗值
        let exp = monster.template.experience
        let previousCircle = character.circle
        let didLevelUp = character.gainExperience(exp)
        appendMessage("你獲得了 \(exp) 點經驗值。")

        if didLevelUp {
            appendMessage("——————————")
            appendMessage("你的等階提升到了 \(character.circle)！")

            // 顯示屬性成長
            let template = GuildTemplateLoader.shared.template(for: character.guild)
            if let growth = template?.circleGrowth {
                let circlesGained = character.circle - previousCircle
                var growthParts: [String] = []
                if growth.strength > 0 { growthParts.append("力量+\(growth.strength * circlesGained)") }
                if growth.agility > 0 { growthParts.append("敏捷+\(growth.agility * circlesGained)") }
                if growth.constitution > 0 { growthParts.append("體質+\(growth.constitution * circlesGained)") }
                if growth.intelligence > 0 { growthParts.append("智力+\(growth.intelligence * circlesGained)") }
                if growth.wisdom > 0 { growthParts.append("智慧+\(growth.wisdom * circlesGained)") }
                if growth.charisma > 0 { growthParts.append("魅力+\(growth.charisma * circlesGained)") }
                if !growthParts.isEmpty {
                    appendMessage("屬性成長：\(growthParts.joined(separator: "、"))")
                }
            }
            appendMessage("HP/MP/SP 已完全回復！")
        }

        // 處理掉落物
        processLoot(monster: monster.template, character: character)

        isInCombat = false
        combatMonster = nil
    }

    /// 掉落物處理
    private func processLoot(monster: MonsterTemplate, character: PlayerCharacter) {
        for loot in monster.loot {
            let roll = Double.random(in: 0.0..<1.0)
            guard roll < loot.dropRate else { continue }
            guard let template = itemLoader.template(for: loot.itemId) else { continue }

            // 檢查是否已有相同物品且可堆疊
            if let existingItem = character.inventory.first(where: {
                $0.itemId == loot.itemId && $0.isStackable && !$0.isStackFull
            }) {
                existingItem.stackCount += 1
                appendMessage("你獲得了【\(template.name)】。(共 \(existingItem.stackCount) 個)")
            } else {
                let newItem = GameItem(from: template)
                character.inventory.append(newItem)
                appendMessage("你獲得了【\(template.name)】。")
            }
        }
    }

    /// 玩家死亡處理
    private func handlePlayerDefeat(monster: CombatMonster, character: PlayerCharacter) {
        appendMessage("——————————")
        appendMessage("你被\(monster.name)擊敗了...")
        appendMessage("你的意識逐漸模糊...")

        // 恢復至村莊，回復一半狀態
        character.currentHealth = max(character.maxHealth / 2, 1)
        character.currentStamina = max(character.maxStamina / 2, 1)

        let safeSceneId = "village"
        character.currentSceneId = safeSceneId
        currentSceneId = safeSceneId

        appendMessage("你在村莊中醒來，身體還很虛弱...")
        if let scene = scenes[safeSceneId] {
            appendMessage(scene.description)
        }

        isInCombat = false
        combatMonster = nil
    }

    /// 給予防具技能經驗
    private func grantArmorSkillExperience(
        character: PlayerCharacter,
        monsterLevel: Int,
        activeSkills: inout Set<SkillType>
    ) {
        let expGain = 0.5 + Double(monsterLevel) * 0.3
        for armor in character.equippedArmor {
            let skillType: SkillType
            if armor.equipSlot == .offHand {
                skillType = .shield
            } else if armor.defensePower >= 5 {
                skillType = .heavyArmor
            } else {
                skillType = .lightArmor
            }
            character.skill(for: skillType)?.gainFieldExperience(expGain)
            activeSkills.insert(skillType)
        }
    }

    /// 吸收戰鬥中觸發的技能經驗
    private func absorbCombatSkills(character: PlayerCharacter, skillTypes: Set<SkillType>) {
        for skillType in skillTypes {
            character.skill(for: skillType)?.absorbExperience()
        }
    }

    // MARK: - NPC 對話

    func talkToNPC(_ npc: NPCTemplate) {
        let playerGuild = currentSaveSlot?.character?.guild
        let dialogues = npc.availableDialogues(playerGuild: playerGuild)

        appendMessage("——————————")
        appendMessage("你向【\(npc.name)】搭話。")

        if dialogues.isEmpty {
            appendMessage("\(npc.name)看了你一眼，沒有說話。")
        } else {
            if let dialogue = dialogues.randomElement() {
                appendMessage("「\(dialogue.text)」")
            }
        }
    }

    // MARK: - 存檔

    func saveGame() {
        guard let slot = currentSaveSlot, let character = slot.character else { return }
        slot.updateSaveInfo(character: character, playTime: slot.playTime)
        try? modelContext.save()
    }

    // MARK: - 訊息管理

    /// 添加訊息，超過 50 筆時移除最舊的
    func appendMessage(_ text: String) {
        messages.append(text)
        if messages.count > 50 {
            messages.removeFirst(messages.count - 50)
        }
    }

    // MARK: - 模板錯誤檢查

    private func checkTemplateErrors() {
        let loaders: [(String, String?)] = [
            ("場景", SceneTemplateLoader.shared.loadError),
            ("怪物", MonsterTemplateLoader.shared.loadError),
            ("NPC", NPCTemplateLoader.shared.loadError),
            ("物品", ItemTemplateLoader.shared.loadError),
            ("職業", GuildTemplateLoader.shared.loadError),
        ]
        for (name, error) in loaders {
            if let error {
                appendMessage("[系統錯誤] \(name)資料載入失敗：\(error)")
            }
        }
    }
}
