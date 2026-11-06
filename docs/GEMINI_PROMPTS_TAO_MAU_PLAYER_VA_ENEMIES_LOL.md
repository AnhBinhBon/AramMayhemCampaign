# BỘ PROMPT YÊU CẦU GEMINI TẠO MẪU 2 ĐỐI TƯỢNG: PLAYER & ENEMIES (PHONG CÁCH LIÊN MINH HUYỀN THOẠI)

Tài liệu này cung cấp các **Câu lệnh (Prompts) chuẩn hóa** để bạn sao chép (Copy) và dán trực tiếp vào **Google Gemini** nhằm tạo bộ hình ảnh Sprite 2D góc nhìn từ trên xuống (`Top-Down 2D Game Sprite`) cho 2 nhóm đối tượng đã được tách riêng trong dự án:
1. **Nhóm `player` (`scenes/entities/player/`):** 4 Lớp Tướng của Người chơi.
2. **Nhóm `enemies` (`scenes/entities/enemies/`):** 3 Chủng loại Lính LoL (Lính Cận Chiến, Bọ Hư Không Xung Kích, Lính Pháp Sư Đánh Xa) và 1 Trùm Cuối (Sứ Giả Khe Nứt / Baron Hư Không).

> **Đặc biệt — Cơ chế Tự động Nhận diện Sprite đã được lập trình sẵn:**  
> Ngay khi bạn tải ảnh từ Gemini về, xóa nền (PNG trong suốt) và lưu đúng tên tệp vào thư mục `assets/sprites/player/` hoặc `assets/sprites/enemies/`, mã nguồn `player.gd`, `enemy.gd` và `final_boss.gd` sẽ **tự động nạp và hiển thị ngay hình ảnh đó lên nhân vật/quái vật trong game**! (Nếu chưa chép ảnh vào, game vẫn hiển thị mô hình Node đa bộ phận chuẩn kiểu Lính LoL).

---

## PHẦN 1: BỘ PROMPT TẠO ĐỐI TƯỢNG `ENEMIES` (LÍNH & TRÙM KIỂU LOL)

Thư mục lưu ảnh sau khi tạo: `amc-project/assets/sprites/enemies/`

### 1.1. Prompt Tạo Lính Cận Chiến Đỏ (`EnemyBasic.tscn` $\rightarrow$ `lol_melee_minion.png`)
* **Vai trò trong game:** Quái bộ cơ bản đi theo đàn, mặc áo choàng đỏ, đội mũ trùm viền vàng, tay trái cầm khiên tròn/vuông bằng đồng, tay phải cầm kiếm/rìu ngắn (xoay mặt sang phải `Facing Right`).
* **Copy đoạn Prompt sau gửi vào Gemini:**

```text
Hãy tạo cho tôi 1 hình ảnh 2D game sprite góc nhìn từ trên xuống (strict top-down 2D game asset view, nhân vật quay mặt sang hướng bên phải màn hình - facing right) của một con Lính Cận Chiến Đội Đỏ lấy cảm hứng từ Liên Minh Huyền Thoại (League of Legends Red Melee Minion):
- Ngoại hình: Một chiến binh lính nhỏ mặc áo choàng và mũ trùm đầu bằng vải màu đỏ thẫm (crimson red hood and cape) có viền kim loại vàng đồng Hextech, khuôn mặt ẩn trong bóng tối dưới mũ trùm với hai đốm mắt phát sáng vàng.
- Vũ khí & Trang bị: Phía trước bên trái cầm một chiếc khiên chắn bằng vàng đồng dày dặn, phía trước bên phải cầm một thanh đoản kiếm/rìu sắt ngắn sắc bén.
- Phong cách nghệ thuật: Stylized hand-painted 2D MOBA game art (phong cách vẽ tay sắc nét của Riot Games / League of Legends), viền ngoài đậm rõ ràng (clean dark outline), đổ bóng khối nổi bật.
- Phông nền: Nền trắng tinh khiết đồng nhất (pure solid white background #FFFFFF), tuyệt đối không có bóng đổ dưới mặt đất, căn giữa khung hình vuông tỉ lệ 1:1 để dễ tách nền PNG.
```

---

### 1.2. Prompt Tạo Bọ Hư Không / Lính Xung Kích Nhanh (`EnemyFast.tscn` $\rightarrow$ `lol_voidling_fast.png`)
* **Vai trò trong game:** Quái tốc độ cao lao nhanh áp sát người chơi, lấy cảm hứng từ Bọ Hư Không (Malzahar Voidling / Bel'Veth Remora / Krug nhỏ) trong Liên Minh Huyền Thoại.
* **Copy đoạn Prompt sau gửi vào Gemini:**

```text
Hãy tạo cho tôi 1 hình ảnh 2D game sprite góc nhìn từ trên xuống (strict top-down 2D game asset view, đầu quay sang hướng bên phải màn hình - facing right) của một con Bọ Hư Không Xung Kích tốc độ cao lấy cảm hứng từ Liên Minh Huyền Thoại (League of Legends Voidling / Fast Chitin Swarmer):
- Ngoại hình: Sinh vật giáp xác Hư Không nhỏ gọn, khí động học, vỏ giáp lưng màu vàng hổ phách pha tím sẫm (golden-amber and dark violet chitin carapace), phần đuôi nhọn phía sau.
- Chi tiết nổi bật: Phía trước đầu có cặp càng/ngà sắc nhọn màu vàng sáng chĩa về phía bên phải (sharp glowing golden mandibles/scythes), chính giữa lưng có một lõi mắt năng lượng Hư Không màu hồng tím phát sáng (glowing magenta Void core eye).
- Phong cách nghệ thuật: Stylized hand-painted 2D MOBA game sprite (League of Legends art style), viền ngoài sắc nét (bold dark outline), màu sắc tương phản cao.
- Phông nền: Nền trắng tinh khiết đồng nhất (pure solid white background #FFFFFF), không vẽ mặt đất hay bóng đổ ngoài thân, tỉ lệ khung hình vuông 1:1.
```

---

### 1.3. Prompt Tạo Lính Đánh Xa Pháp Sư (`EnemyRanged.tscn` $\rightarrow$ `lol_caster_minion.png`)
* **Vai trò trong game:** Lính đánh xa giữ khoảng cách và bắn đạn phép về phía người chơi, lấy cảm hứng từ Lính Pháp Sư (Caster Minion) trong Liên Minh Huyền Thoại.
* **Copy đoạn Prompt sau gửi vào Gemini:**

```text
Hãy tạo cho tôi 1 hình ảnh 2D game sprite góc nhìn từ trên xuống (strict top-down 2D game asset view, nhân vật quay mặt sang hướng bên phải màn hình - facing right) của một con Lính Đánh Xa Pháp Sư lấy cảm hứng từ Liên Minh Huyền Thoại (League of Legends Caster Minion):
- Ngoại hình: Một pháp sư lính nhỏ mặc áo choàng xanh lam pha lục ngọc và đội mũ phù thủy chóp nhọn có vành viền vàng kim (arcane blue wizard robe and golden-trimmed pointed hood).
- Vũ khí: Đưa về phía trước (bên phải) một cây trượng gỗ cổ ngữ ngắn có gắn viên ngọc năng lượng phép thuật phát sáng rực rỡ ở đỉnh trượng.
- Phong cách nghệ thuật: Stylized hand-painted 2D MOBA game sprite (League of Legends / ARAM art style), đường viền đậm rõ nét (clean dark outline), chi tiết gọn gàng dễ nhìn ở kích thước nhỏ.
- Phông nền: Nền trắng tinh khiết đồng nhất (pure solid white background #FFFFFF), không có hiệu ứng khói lan ra nền, căn giữa khung hình vuông 1:1.
```

---

### 1.4. Prompt Tạo Trùm Cuối — Sứ Giả Khe Nứt / Chiến Hạm Hư Không (`FinalBoss.tscn` $\rightarrow$ `lol_rift_herald_boss.png`)
* **Vai trò trong game:** Trùm Cuối Đợt 7 (`100,000 Máu`), có kỹ năng lao húc (`Charge`), bắn vòng đạn năng lượng (`Ring Shot`) và triệu hồi lính, lấy cảm hứng trực tiếp từ **Sứ Giả Khe Nứt (Rift Herald)** kết hợp **Baron Nashor** trong Liên Minh Huyền Thoại.
* **Copy đoạn Prompt sau gửi vào Gemini:**

```text
Hãy tạo cho tôi 1 hình ảnh 2D Boss game sprite góc nhìn từ trên xuống (strict top-down 2D game boss asset view, đối xứng tâm hoặc hướng về bên phải) của Trùm Cuối Sứ Giả Khe Nứt Hư Không lấy cảm hứng từ Liên Minh Huyền Thoại (League of Legends Rift Herald / Void Leviathan Boss):
- Ngoại hình: Quái vật khổng lồ bọc giáp xác Hư Không màu tím đen và hồng sẫm (massive dark purple and obsidian Void carapace armor), xung quanh rìa thân có 8 chiếc gai tinh thể năng lượng sắc nhọn tỏa ra đối xứng như bánh răng hủy diệt.
- Tâm điểm: Ngay chính giữa lưng là một Con Mắt Hư Không khổng lồ phát sáng màu hồng đỏ rực lửa (giant glowing crimson-magenta Void Eye core at the center).
- Phong cách nghệ thuật: Stylized hand-painted 2D MOBA Boss sprite (League of Legends Void / Rift Herald aesthetic), viền đậm sắc nét, uy nghi và cực kỳ nguy hiểm.
- Phông nền: Nền trắng tinh khiết đồng nhất (pure solid white background #FFFFFF), không vẽ nền cảnh vật, căn giữa khung hình vuông 1:1.
```

---

## PHẦN 2: BỘ PROMPT TẠO ĐỐI TƯỢNG `PLAYER` & `WEAPON` (4 TƯỚNG BIỂU TƯỢNG: VAYNE, XIN ZHAO, GAREN, LUX)

Thư mục lưu ảnh sau khi tạo:
- Ảnh thân tướng: `amc-project/assets/sprites/player/`
- Ảnh vũ khí rời: `amc-project/assets/sprites/weapons/`

*(Lưu ý: Nhân vật và Vũ khí được tách thành 2 ảnh riêng biệt để hệ thống `WeaponController` tự động cầm và xoay vũ khí 360 độ theo hướng ngắm bắn!)*

### 2.1. Vayne — Xạ Thủ Bóng Đêm (`lol_ad_marksman.png` & `weapon_ad_crossbow.png`) — *[ĐÃ TÍCH HỢP]*
* Đã được tách nền và nạp vào `PlayerAD.tscn` & `WeaponCrossbowAD.tscn`.

---

### 2.2. Xin Zhao — Đấu Sĩ Tể Tướng Demacia (`PlayerBruiser.tscn` $\rightarrow$ `lol_bruiser.png` & `weapon_bruiser_sword.png`) — *[ĐÃ TÍCH HỢP]*
* Đã được tách nền PNG trong suốt và nạp vào `PlayerBruiser.tscn` & `WeaponSpearBruiser.tscn`.
* **Prompt 1 — Tạo Thân Nhân vật Xin Zhao (`lol_bruiser.png`):**
```text
Hãy tạo cho tôi 1 hình ảnh 2D character sprite góc nhìn thẳng từ đỉnh đầu xuống (strict top-down 2D game character token/sprite, quay mặt sang bên phải - facing right, KHÔNG vẽ tay và KHÔNG vẽ vũ khí) của tướng Xin Zhao Tể Tướng Demacia trong Liên Minh Huyền Thoại:
- Ngoại hình nhìn từ đỉnh đầu xuống: Tóc đen buộc đuôi ngựa dài bay nhẹ về phía sau (bên trái), khoác giáp vai bạc viền vàng Demacia và áo choàng chiến bào màu xanh lam pha đỏ rượu (Demacian silver-gold shoulder pauldrons and royal blue/crimson cape).
- Phong cách: Minimalist clean 2D MOBA top-down token (giống phong cách token Vayne 2D), viền đậm sắc nét, nền trắng tinh khiết đồng nhất (#FFFFFF), tỉ lệ 1:1.
```
* **Prompt 2 — Tạo Vũ khí Trường Thương Xin Zhao (`weapon_bruiser_sword.png`):**
```text
Hãy tạo cho tôi 1 hình ảnh 2D weapon sprite góc nhìn từ trên xuống (top-down 2D game weapon asset, mũi thương chĩa thẳng sang bên phải màn hình - pointing right) của cây Trường Thương Bán Nguyệt của Xin Zhao (League of Legends Xin Zhao Spear):
- Ngoại hình: Cán thương dài bằng kim loại trầm và gỗ quý, phần cổ thương có tua rua đỏ (red tassel) và hai ngạnh bán nguyệt mạ vàng, mũi thương bằng thép bạc sắc bén sáng loáng.
- Phong cách: Clean 2D vector/hand-painted game asset, viền đen đậm rõ nét, nền trắng tinh khiết đồng nhất (#FFFFFF), tỉ lệ 1:1.
```

---

### 2.3. Garen — Đỡ Đòn Sức Mạnh Demacia (`PlayerTank.tscn` $\rightarrow$ `lol_tank.png` & `weapon_tank_axe.png`) — *[ĐÃ TÍCH HỢP]*
* Đã được tách nền PNG trong suốt và nạp vào `PlayerTank.tscn` & `WeaponGreatswordTank.tscn`.
* **Prompt 1 — Tạo Thân Nhân vật Garen (`lol_tank.png`):**
```text
Hãy tạo cho tôi 1 hình ảnh 2D character sprite góc nhìn thẳng từ đỉnh đầu xuống (strict top-down 2D game character token/sprite, quay mặt sang bên phải - facing right, KHÔNG vẽ tay và KHÔNG vẽ vũ khí) của tướng Garen Sức Mạnh Demacia trong Liên Minh Huyền Thoại:
- Ngoại hình nhìn từ đỉnh đầu xuống: Mái tóc ngắn màu nâu sẫm ở giữa, bao quanh bởi cặp giáp vai khổng lồ đặc trưng của Demacia màu bạc trắng viền vàng kim rực rỡ và khăn choàng cổ màu xanh lam (massive iconic silver and gold Demacian pauldrons with royal blue scarf/cape).
- Phong cách: Minimalist clean 2D MOBA top-down token, viền đậm sắc nét, nền trắng tinh khiết đồng nhất (#FFFFFF), tỉ lệ 1:1.
```
* **Prompt 2 — Tạo Vũ khí Đại Kiếm Demacia của Garen (`weapon_tank_axe.png`):**
```text
Hãy tạo cho tôi 1 hình ảnh 2D weapon sprite góc nhìn từ trên xuống (top-down 2D game weapon asset, mũi kiếm chĩa thẳng sang bên phải màn hình - pointing right) của thanh Đại Kiếm Công Lý Demacia của Garen (League of Legends Garen Greatsword):
- Ngoại hình: Thanh trọng kiếm bản cực rộng và uy lực, chuôi kiếm và chắn tay (crossguard) bằng vàng kim hình cánh chim Demacia, lưỡi kiếm bằng thép bạc sáng có rãnh phát sáng vàng ở giữa.
- Phong cách: Clean 2D vector/hand-painted game asset, viền đen đậm rõ nét, nền trắng tinh khiết đồng nhất (#FFFFFF), tỉ lệ 1:1.
```

---

### 2.4. Lux — Pháp Sư Tiểu Thư Ánh Sáng (`PlayerMage.tscn` $\rightarrow$ `lol_mage_ap.png` & `weapon_mage_staff.png`) — *[ĐÃ TÍCH HỢP]*
* Đã được tách nền PNG trong suốt và nạp vào `PlayerMage.tscn` & `WeaponStaffMage.tscn`.
* **Prompt 1 — Tạo Thân Nhân vật Lux (`lol_mage_ap.png`):**
```text
Hãy tạo cho tôi 1 hình ảnh 2D character sprite góc nhìn thẳng từ đỉnh đầu xuống (strict top-down 2D game character token/sprite, quay mặt sang bên phải - facing right, KHÔNG vẽ tay và KHÔNG vẽ vũ khí) của tướng Lux Tiểu Thư Ánh Sáng trong Liên Minh Huyền Thoại:
- Ngoại hình nhìn từ đỉnh đầu xuống: Mái tóc vàng óng (golden blonde hair) đeo băng đô vương miện bạc Demacia phía trước trán, khoác giáp nhẹ màu trắng bạc viền vàng và áo choàng lụa xanh lam sáng (white-silver and gold Demacian mage armor with bright blue cape).
- Phong cách: Minimalist clean 2D MOBA top-down token, viền đậm sắc nét, nền trắng tinh khiết đồng nhất (#FFFFFF), tỉ lệ 1:1.
```
* **Prompt 2 — Tạo Vũ khí Trượng Ánh Sáng của Lux (`weapon_mage_staff.png`):**
```text
Hãy tạo cho tôi 1 hình ảnh 2D weapon sprite góc nhìn từ trên xuống (top-down 2D game weapon asset, đầu trượng chĩa thẳng sang bên phải màn hình - pointing right) của cây Trượng Ánh Sáng của Lux (League of Legends Lux Wand/Staff of Light):
- Ngoại hình: Cây quyền trượng phép thuật bằng vàng kim thanh thoát, hai đầu có vòng cung kim loại vàng đối xứng ôm lấy lõi tinh thể ánh sáng lấp lánh ở đỉnh trượng (bên phải).
- Phong cách: Clean 2D vector/hand-painted game asset, viền đen đậm rõ nét, nền trắng tinh khiết đồng nhất (#FFFFFF), tỉ lệ 1:1.
```

---

## PHẦN 3: BẢNG TỔNG HỢP CẤU TRÚC 2 ĐỐI TƯỢNG TRONG DỰ ÁN

| Phân nhóm Đối tượng | Tệp Node Scene (`.tscn`) | Đường dẫn Ảnh Sprite Tự động Nhận diện (`.png`) | Thiết kế Hình học Hiện có trong Node |
| :--- | :--- | :--- | :--- |
| **1. PLAYER (Người chơi)** | `scenes/entities/player/PlayerAD.tscn` | `assets/sprites/player/lol_ad_marksman.png` | Thân Cam + Áo choàng `TacticalCape` + Kính ngắm `HextechVisor` |
| **1. PLAYER (Người chơi)** | `scenes/entities/player/PlayerBruiser.tscn` | `assets/sprites/player/lol_bruiser.png` | Thân Đỏ + 2 Giáp vai `Left/RightPauldron` + Sừng vàng `WarCrest` |
| **1. PLAYER (Người chơi)** | `scenes/entities/player/PlayerTank.tscn` | `assets/sprites/player/lol_tank.png` | Thân Lục bảo + Khung giáp 8 cạnh `HeavyArmorPlate` + Lõi `AegisCore` |
| **1. PLAYER (Người chơi)** | `scenes/entities/player/PlayerMage.tscn` | `assets/sprites/player/lol_mage_ap.png` | Thân Tím + Vương miện `ArcaneCrown` + 3 Ngọc xoay `FloatingOrbs` |
| **2. ENEMIES (Quái LoL)** | `scenes/entities/enemies/EnemyBasic.tscn` | `assets/sprites/enemies/lol_melee_minion.png` | **Lính Cận Chiến Đỏ LoL:** Áo choàng + Mũ trùm vàng + Khiên đồng + Đoản kiếm |
| **2. ENEMIES (Quái LoL)** | `scenes/entities/enemies/EnemyFast.tscn` | `assets/sprites/enemies/lol_voidling_fast.png` | **Bọ Hư Không LoL:** Gai đuôi tím + 2 Càng vàng sắc nhọn + Mắt Hư Không |
| **2. ENEMIES (Quái LoL)** | `scenes/entities/enemies/EnemyRanged.tscn` | `assets/sprites/enemies/lol_caster_minion.png` | **Lính Đánh Xa Pháp Sư LoL:** Áo choàng lam + Mũ phù thủy + Trượng Ngọc Phép |
| **2. ENEMIES (Trùm LoL)** | `scenes/entities/enemies/FinalBoss.tscn` | `assets/sprites/enemies/lol_rift_herald_boss.png` | **Sứ Giả Khe Nứt / Baron (`100k HP`):** Giáp xác Hư Không + Mắt Đỏ + 8 Gai xoay |

