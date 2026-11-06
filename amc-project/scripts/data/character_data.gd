class_name CharacterData
extends Resource
## Dữ liệu cấu hình Lớp Nhân vật (Xạ Thủ, Đấu Sĩ, Đỡ Đòn, Pháp Sư)

@export var id: String = "ad_marksman"
@export var display_name: String = "Xạ Thủ (AD)"
@export var character_scene_path: String = "res://scenes/entities/Player.tscn"
@export var icon_path: String = "res://assets/sprites/classes/class_ad.png"
@export var body_color: Color = Color(0.96, 0.58, 0.14, 1.0)
@export var hand_color: Color = Color(0.85, 0.45, 0.10, 1.0)

@export var buff_text: String = "+15% Tốc độ đánh, +10% Tỉ lệ chí mạng"
@export var debuff_text: String = "-15% Máu tối đa"

@export_group("Base Stats")
@export var base_max_hp: float = 100.0
@export var base_hp_regen: float = 1.0
@export var base_lifesteal: float = 0.0
@export var base_ad: float = 18.0
@export var base_ap: float = 0.0
@export var base_attack_speed: float = 1.85
@export var base_crit_chance: float = 0.15
@export var base_crit_damage: float = 1.75
@export var base_ability_haste: float = 0.0
@export var base_move_speed: float = 240.0
@export var base_armor: float = 5.0

@export_group("Weapon & Main Skill (SPACE)")
@export var starting_weapon: WeaponData
@export var skill_id: String = "ad_dash"
@export var skill_name: String = "Giờ Khắc Cuối Cùng"
@export var skill_icon_path: String = "res://assets/sprites/classes/skill_ad_dash.png"
@export var skill_cooldown: float = 10.0
@export var skill_description: String = "Bước vào trạng thái Thợ Săn Bóng Đêm trong 4.5s: Ẩn thân ngắn 0.8s, +35% AD, +50% Tốc đánh và +25% Tốc chạy."

@export_group("Sub Skills (Q & E)")
@export var skill_q_id: String = "vayne_tumble_q"
@export var skill_q_name: String = "Nhào Lộn & Tên Bạc"
@export var skill_q_icon_path: String = "res://assets/sprites/augments/aug_mystic_punch.png"
@export var skill_q_cooldown: float = 3.5
@export var skill_q_description: String = "Nhào lộn 150px và bắn Mũi Tên Bạc gây 140% AD + 8% Máu tối đa mục tiêu."

@export var skill_e_id: String = "vayne_condemn_e"
@export var skill_e_name: String = "Kết Án"
@export var skill_e_icon_path: String = "res://assets/sprites/augments/aug_supernatural.png"
@export var skill_e_cooldown: float = 7.5
@export var skill_e_description: String = "Bắn tên hạng nặng gây 115% AD, đẩy lùi mạnh và làm choáng 1.2s (+100% AD nếu va tường)."
