class_name BonusData
extends Resource
## Dữ liệu Phúc lợi Đầu trận (7 Phúc lợi random có trọng số ở Giai đoạn 2)

enum BonusKind {
	EXTRA_REROLL,
	STARTING_GOLD,
	EXTRA_AUGMENT,
	MAX_HP_BUFF,
	SHOP_DISCOUNT,
	GIFT_AT_WAVE_3,
	GOLD_MULTIPLIER
}

@export var id: String = "lucky_ticket"
@export var bonus_name: String = "Vé May Mắn"
@export var icon_path: String = "res://assets/sprites/bonuses/bonus_lucky_ticket.png"
@export var description: String = "+2 lượt Reroll Lõi miễn phí."
@export var playstyle_hint: String = "Định hướng: Săn tìm Lõi Kim Cương mạnh."
@export var kind: BonusKind = BonusKind.EXTRA_REROLL
@export var value: float = 2.0
@export var weight: float = 10.0
@export var accent_color: Color = Color(0.95, 0.78, 0.22, 1.0)
