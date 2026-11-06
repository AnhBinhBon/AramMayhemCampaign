class_name AugmentData
extends Resource
## Dữ liệu Lõi Nâng cấp (Bạc / Vàng / Kim Cương ở Giai đoạn 3)

enum Rarity {
	SILVER,
	GOLD,
	PRISMATIC
}

@export var id: String = "silver_hand"
@export var augment_name: String = "Tay Bạc"
@export var icon_path: String = "res://assets/sprites/augments/aug_silver_hand.png"
@export var description: String = "Tăng +20% Sức mạnh công kích (AD)."
@export var rarity: Rarity = Rarity.SILVER
@export var accent_color: Color = Color(0.85, 0.90, 0.95, 1.0)
@export var modifiers: Array[StatModifier] = []
@export var effects: Array[AugmentEffect] = []

