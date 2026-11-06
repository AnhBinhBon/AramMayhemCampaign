class_name StatModifier
extends Resource
## Định nghĩa 11 chỉ số cơ bản và cấu trúc cộng/nhân chỉ số động (StatModifier)

enum StatType {
	MAX_HP,
	HP_REGEN,
	LIFESTEAL,
	AD,
	AP,
	ATTACK_SPEED,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	ABILITY_HASTE,
	MOVE_SPEED,
	ARMOR
}

@export var stat: StatType = StatType.AD
@export var add: float = 0.0
@export var mult: float = 0.0


static func create(p_stat: StatType, p_add: float = 0.0, p_mult: float = 0.0) -> StatModifier:
	var mod := StatModifier.new()
	mod.stat = p_stat
	mod.add = p_add
	mod.mult = p_mult
	return mod


static func get_stat_display_name(s: StatType) -> String:
	match s:
		StatType.MAX_HP:
			return "Máu tối đa"
		StatType.HP_REGEN:
			return "Hồi máu/s"
		StatType.LIFESTEAL:
			return "Hút máu"
		StatType.AD:
			return "Sức mạnh công kích (AD)"
		StatType.AP:
			return "Sức mạnh phép thuật (AP)"
		StatType.ATTACK_SPEED:
			return "Tốc độ đánh"
		StatType.CRIT_CHANCE:
			return "Tỉ lệ chí mạng"
		StatType.CRIT_DAMAGE:
			return "Sát thương chí mạng"
		StatType.ABILITY_HASTE:
			return "Điểm hồi kỹ năng"
		StatType.MOVE_SPEED:
			return "Tốc độ di chuyển"
		StatType.ARMOR:
			return "Giáp"
	return "Chỉ số"

