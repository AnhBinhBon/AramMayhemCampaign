# 🎨 TÀI LIỆU THIẾT KẾ & DANH SÁCH ASSETS
**Dự án:** ARAM Mayhem Campaign
**Engine:** Godot 4.x
**Phong cách nghệ thuật:** Tối giản (Minimalist), Hình học cơ bản (Geometric), Góc nhìn Top-down 2D (Tương tự Surviv.io, Brotato).

---

## 1. ĐỊNH HƯỚNG THIẾT KẾ (ART DIRECTION)
- **Hình ảnh thực thể (Nhân vật, Quái, Đạn, Môi trường):** Không dùng Sprite import từ ngoài. Tận dụng 100% `MeshInstance2D` có sẵn của Godot (Cầu, Hộp) kết hợp với thuộc tính `Modulate` (đổi màu) để tạo hình.
- **UI & Icon:** Dùng hình ảnh 2D đơn sắc, rõ nét để dễ nhận diện trong Shop và khi chọn Lõi nâng cấp.
- **Animation:** Dùng `Tween` tạo độ giật lùi (recoil), nảy (bounce), và xoay (rotation) bằng code thay vì làm frame-by-frame.

---

## 2. DANH SÁCH TÀI NGUYÊN TRONG ENGINE (IN-ENGINE ASSETS)
*Tạo trực tiếp trong Scene của Godot bằng `MeshInstance2D`.*

### 2.1. Player (Nhân vật)
- **Thân chính:** `SphereMesh` (Radius 32, Height 32)
- **Tay (2 bên):** `BoxMesh` (Kích thước nhỏ: 16x16)
- **Bảng màu phân loại (Color Palette - Modulate):**
  - Xạ Thủ (AD): Vàng cam (Orange/Yellow)
  - Đấu Sĩ (Bruiser): Đỏ sậm (Dark Red)
  - Đỡ Đòn (Tank): Xanh lá cây (Green)
  - Pháp Sư (AP): Tím/Xanh dương (Purple/Blue)

### 2.2. Vũ khí (Vẽ gắn liền vào WeaponController)
- **Súng trường/Súng ngắn (AD):** `BoxMesh` (Hình chữ nhật dài, màu xám đen).
- **Kiếm (Bruiser):** `BoxMesh` (Dài và nhọn hơn, màu xám nhạt).
- **Rìu (Tank):** Ghép 1 `BoxMesh` (cán) + 1 `PrismMesh` (lưỡi rìu).
- **Gậy phép (AP):** `BoxMesh` (cán ngắn) + `SphereMesh` (ngọc trên đỉnh).

### 2.3. Quái vật (Enemies) & Boss
- **Quái cơ bản (Chạy bộ):** `SphereMesh` (Màu Đỏ nhạt), kích thước tương đương Player.
- **Quái nhanh (Máu giấy):** `SphereMesh` (Màu Vàng), kích thước nhỏ hơn 20%.
- **Quái bắn xa:** `BoxMesh` (Hình vuông, màu Xanh Lục).
- **Final Boss:** `SphereMesh` siêu to (Gấp 3 Player), gắn thêm gai (`PrismMesh`) xung quanh, màu Tím Đen hoặc Đỏ Rực.

### 2.4. Đạn & Vật phẩm rơi (Pickups)
- **Đạn súng:** `BoxMesh` (Chữ nhật nhỏ màu vàng/trắng) hoặc `CapsuleMesh`.
- **Cầu lửa (AP):** `SphereMesh` (Màu cam/đỏ).
- **Đạn của Boss:** `SphereMesh` (Màu đỏ tươi/tím).
- **Vàng (Gold Pickup):** `PrismMesh` (Hình thoi/Lục giác nhỏ) hoặc `SphereMesh` (Màu Vàng chanh, phát sáng bằng vật liệu).

### 2.5. Môi trường (Arena)
- **Nền đất (Floor):** Dùng `TextureRect` lặp (Tile) một hình vuông màu xám nhạt/xanh cỏ úa đơn giản, hoặc `Polygon2D` phủ toàn bản đồ.
- **Tường bao (Walls):** Dùng `StaticBody2D` kết hợp `ColorRect` màu tối để đánh dấu giới hạn bản đồ.

---

## 3. DANH SÁCH TÀI NGUYÊN 2D (SPRITES & ICONS)
*Cần chuẩn bị ảnh PNG, kích thước 64x64 hoặc 128x128. Có thể tự vẽ bằng Aseprite hoặc tải miễn phí.*

### 3.1. UI Icons (Hệ thống Shop & Lõi) - Quan trọng nhất!
- **12 Icon Lõi nâng cấp (Augments):** Cần các biểu tượng thể hiện tính chất.
  - VD: Icon Giày (Tốc độ), Icon Trái tim (Máu), Icon Đạn (Xả đạn), Icon Găng tay (Chí mạng), Icon Khiên (Giáp gai).
- **10 Icon Trang bị (Items):** 
  - Kiếm, Dao găm, Áo choàng, Giày, Huyết kiếm, Cung, v.v.
- **7 Icon Phúc lợi đầu game (Bonuses):**
  - Vé, Túi tiền, Hộp quà, Biểu tượng Buff.
- **Khung viền (Borders):** Viền Bạc, Vàng, Kim Cương để phân loại độ hiếm cho Lõi và Trang bị.

### 3.2. Font chữ
- 1 Font hiển thị sát thương nảy lên (Floating Damage) - Dày, viền đen (Outline).
- 1 Font UI chính - Sạch, rõ ràng (Sans-serif hoặc Pixel mượt).

---

## 4. DANH SÁCH ÂM THANH (AUDIO ASSETS)
*Định dạng `.wav` hoặc `.ogg`. Ưu tiên thời lượng rất ngắn (0.1 - 0.5s).*

### 4.1. Sound Effects (SFX) - Gameplay
- [ ] Bắn đạn súng (Pew, Bang).
- [ ] Vung kiếm / Gậy (Swoosh).
- [ ] Đạn trúng địch (Hit - Impact mềm).
- [ ] Quái chết (Pop / Splat).
- [ ] Người chơi nhận sát thương (Oof / Hurt).
- [ ] Nhặt vàng (Coin ching / Ping).
- [ ] Cảnh báo Boss xuất hiện (Warning Siren).

### 4.2. Sound Effects (SFX) - UI
- [ ] Hover nút bấm (Tick nhẹ).
- [ ] Mua / Bán thành công (Ka-ching / Tiền rơi).
- [ ] Bấm Reroll Shop/Lõi (Shuffle / Dice roll).
- [ ] Lỗi (Không đủ tiền, Hết chỗ) (Buzzer / Thud).
- [ ] Lật thẻ phúc lợi (Card flip).

### 4.3. Nhạc nền (BGM)
- [ ] Nhạc Menu (Nhẹ nhàng, chờ đợi).
- [ ] Nhạc Gameplay - Wave thường (Sôi động, dồn dập, tempo 120+).
- [ ] Nhạc Boss (Căng thẳng, Epic 8-bit).

---

## 5. CÔNG CỤ & NGUỒN TẢI MIỄN PHÍ KHUYÊN DÙNG
1. **Đồ họa Icon:** 
   - [game-icons.net](https://game-icons.net/) (Đổi màu trắng đen, tải file PNG - Cực kỳ phù hợp cho game thẻ bài/lõi).
   - *Hoặc tự vẽ bằng Aseprite (chỉ dùng màu phẳng - flat colors).*
2. **Âm thanh SFX:** 
   - [sfxr.me](https://sfxr.me/) hoặc **jsfxr** (Tạo âm thanh 8-bit, giật lùi, nổ, nhảy, nhặt xu chỉ bằng 1 cú click).
   - [Kenney Audio](https://kenney.nl/assets/category:Audio) (Gói UI Audio và Sci-fi Audio).
3. **Font chữ:** Google Fonts (Gợi ý: *Press Start 2P*, *Teko*, hoặc *Roboto Black* cho sát thương).