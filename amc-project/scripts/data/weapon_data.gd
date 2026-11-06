class_name WeaponData
extends Resource
## Dữ liệu cấu hình Vũ khí (Súng AD, Kiếm Bruiser, Rìu Tank, Gậy phép AP)

enum WeaponType {
	PROJECTILE,
	MELEE,
	AOE
}

@export var weapon_id: String = "gun_ad"
@export var weapon_name: String = "Nỏ Bạc Bóng Đêm"
@export var weapon_type: WeaponType = WeaponType.PROJECTILE
@export var weapon_sprite_path: String = ""
@export var weapon_scene_path: String = ""
@export var hold_offset: Vector2 = Vector2(24.0, 0.0)
@export var muzzle_offset: Vector2 = Vector2(44.0, 0.0)
@export var visual_size: float = 40.0
@export var damage_scale: float = 1.0
@export var uses_ap: bool = false
@export var base_range: float = 360.0
@export var projectile_speed: float = 640.0
@export var pierce_count: int = 0
@export var bounce_count: int = 0
@export var aoe_radius: float = 0.0
@export var knockback_force: float = 0.0
@export var projectile_color: Color = Color(1.0, 0.92, 0.25, 1.0)
@export var gun_color: Color = Color(0.28, 0.32, 0.38, 1.0)

