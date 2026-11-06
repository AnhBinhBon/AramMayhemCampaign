class_name ItemData
extends Resource
## Dữ liệu Trang bị trong Cửa hàng (Thường / Hiếm / Huyền Thoại ở Giai đoạn 3)

enum ItemTier {
	COMMON,
	RARE,
	LEGENDARY
}

@export var id: String = "long_sword"
@export var item_name: String = "Kiếm Dài"
@export var icon_path: String = "res://assets/sprites/items/item_long_sword.png"
@export var description: String = "+10 Sức mạnh công kích (AD)"
@export var tier: ItemTier = ItemTier.COMMON
@export var price: int = 30
@export var modifiers: Array[StatModifier] = []
@export var passive_effect: AugmentEffect = null

