extends Node
## Hệ thống Event Bus trung tâm (Autoload: CombatEvents)
## Giúp tách biệt hoàn toàn logic chiến đấu của Nhân vật/Vũ khí khỏi hệ thống Lõi (Augments) và Trang bị (Items).

signal attack(weapon: Node, projectile: Node)
signal hit(target: Node, damage: float, is_crit: bool)
signal crit(target: Node, damage: float)
signal kill(enemy: Node)
signal take_damage(amount: float, attacker: Node)
signal skill_cast(skill_id: String)

signal gold_changed(total_gold: int)
signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)

signal boss_spawned(boss: Node)
signal boss_hp_changed(current_hp: float, max_hp: float, is_phase_2: bool)
signal boss_defeated()

