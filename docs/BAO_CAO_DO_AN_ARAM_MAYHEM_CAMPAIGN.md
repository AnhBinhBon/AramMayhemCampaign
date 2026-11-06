# BÁO CÁO ĐỒ ÁN MÔN HỌC
# ĐỀ TÀI: THIẾT KẾ VÀ PHÁT TRIỂN TRÒ CHƠI CHIẾN DỊCH ĐẤU TRƯỜNG SINH TỒN THEO KIẾN TRÚC HƯỚNG DỮ LIỆU TRÊN NỀN TẢNG GODOT ENGINE

---

## THÔNG TIN CHUNG

- **Tên Đề tài:** Thiết kế và Phát triển Trò chơi Chiến dịch Đấu trường Sinh tồn "ARAM Mayhem Campaign"
- **Nền tảng Công nghệ:** Godot Engine (Phiên bản 4.x)
- **Ngôn ngữ Lập trình:** GDScript 2.0
- **Thể loại:** Roguelite Survivor, Hành động Nhập vai Top-down 2D
- **Thời gian Thực hiện:** Năm học 2025 - 2026

---

## TỔNG QUAN ĐỀ TÀI & LÝ DO CHỌN ĐỀ TÀI

### 1. Bối cảnh Nghiên cứu
Trong những năm gần đây, thể loại trò chơi điện tử sinh tồn chiến thuật kết hợp yếu tố Roguelite (Survivor Roguelite) đã thu hút sự quan tâm sâu rộng của cả cộng đồng phát triển game chuyên nghiệp và người chơi toàn cầu. Đặc trưng nổi bật của dòng game này là vòng lặp lối chơi cô đọng, hệ thống nâng cấp chỉ số phân nhánh sâu rộng, mật độ thực thể dày đặc và nhịp độ chiến đấu dồn dập.

Tuy nhiên, việc phát triển các trò chơi thuộc thể loại này thường gặp phải các thách thức kỹ thuật lớn:
- Sự phụ thuộc quá mức vào tài nguyên đồ họa phức tạp từ bên thứ ba làm chậm tiến độ kiểm thử lối chơi cốt lõi.
- Sự phụ thuộc chéo chặt chẽ (tight-coupling) giữa các lớp nhân vật, vũ khí và hiệu ứng nâng cấp khiến mã nguồn trở nên khó mở rộng và dễ xảy ra tình trạng mất đồng bộ chỉ số.
- Vấn đề hiệu năng khi khởi tạo động hàng trăm viên đạn và quái vật trong các đợt đấu cao trào, dẫn đến nghẽn chu kỳ cập nhật vật lý.

### 2. Mục tiêu Đề tài
Đề tài **ARAM Mayhem Campaign** được xây dựng nhằm giải quyết triệt để các thách thức trên thông qua 4 mục tiêu cốt lõi:
1. Xây dựng trò chơi sinh tồn hoàn chỉnh gồm 7 đợt đấu chiến dịch, tích hợp Đợt Chuẩn bị tích lũy kinh tế và Trận Đấu Trùm Cuối điều khiển bằng Máy trạng thái hữu hạn.
2. Triển khai kiến trúc **Hướng Dữ liệu (Data-Driven)** kết hợp **Bus Sự kiện Bất đồng bộ (Event-Driven)**, tách biệt hoàn toàn dữ liệu cấu hình chỉ số khỏi mã nguồn điều phối thực thể.
3. Hiện thực hóa triết lý **Đồ họa Hình học Nội sinh (In-Engine Geometry)** và **Bộ Quản trị Âm thanh Số Tự sinh (Procedural Audio Synthesis)**, đảm bảo dự án tự chủ 100% tài nguyên và chạy độc lập mượt mà.
4. Mở rộng trọn vẹn 4 Lớp nhân vật (Xạ Thủ, Đấu Sĩ, Đỡ Đòn, Pháp Sư) với 3 hình thái vũ khí (Đạn tầm xa, Chém quét Cận chiến, Nổ diện rộng AoE) cùng 7 Phúc lợi, 12 Lõi nâng cấp và Cửa hàng kinh tế 6 ô.

---

## CHƯƠNG 1: KIẾN TRÚC HỆ THỐNG & NGUYÊN TẮC THIẾT KẾ KỸ THUẬT

### 1.1. Mô hình Hướng Dữ liệu (Data-Driven Architecture)
Mọi thông số của trò chơi đều được mô hình hóa thành các lớp tài nguyên độc lập kế thừa từ lớp `Resource` của công cụ phát triển:
- `CharacterData`: Định nghĩa chỉ số cơ bản, màu sắc nhận diện, định danh kỹ năng và vũ khí khởi đầu của từng lớp tướng.
- `WeaponData`: Định nghĩa hình thái vũ khí (`PROJECTILE`, `MELEE`, `AOE`), hệ số sát thương, tầm tác chiến, độ giật và lực đẩy lùi.
- `ItemData`: Định nghĩa 10 trang bị chia thành 3 bậc chất lượng (Thường, Hiếm, Truyền Thuyết) với giá mua, hệ số hoàn tiền và danh sách biến đổi chỉ số.
- `AugmentData`: Định nghĩa 12 Lõi nâng cấp chia thành 3 bậc (Bạc, Vàng, Kim Cương) kết hợp các đối tượng hành vi chuyên biệt kế thừa `AugmentEffect`.
- `WaveData`: Cấu hình chi tiết tần suất sinh quái, hệ số máu, hệ số nhân vàng và các cờ phân loại chiến thuật cho từng đợt đấu.

### 1.2. Bus Sự kiện Trung tâm (Event-Driven Bus)
Để triệt tiêu sự phụ thuộc trực tiếp giữa các đối tượng trong không gian trò chơi, hệ thống sử dụng một điểm nút phát tín hiệu trung tâm `CombatEvents`:
- Các sự kiện tác chiến cốt lõi: `attack`, `hit`, `crit`, `kill`, `take_damage`, `skill_cast`.
- Các sự kiện kinh tế và chu trình màn chơi: `gold_changed`, `wave_started`, `wave_ended`.
- Các sự kiện đối đầu trùm: `boss_spawned`, `boss_hp_changed`, `boss_defeated`.

Nhờ cơ chế này, các thành phần như Lõi nâng cấp (Giáp Gai, Đạn Nảy, Cú Đấm Thần Bí), Giao diện người dùng và Bộ phát âm thanh có thể tự động lắng nghe và phản hồi sự kiện mà không cần truy vấn trực tiếp thực thể Người chơi hay Quái vật.

### 1.3. Hệ thống Quản lý Chỉ số Động (Dynamic Stat System)
Chỉ số của thực thể nhân vật được điều phối bởi lớp `PlayerStats` theo công thức tính toán toán học hai bậc chuẩn hóa:

$$\text{Chỉ số Thực tế} = \left(\text{Chỉ số Gốc} + \sum \text{Chỉ số Cộng Thẳng}\right) \times \max\left(0.1, 1.0 + \sum \text{Hệ số Nhân}\right)$$

Điểm đột phá kỹ thuật nằm ở cơ chế **Khóa nguồn Biến đổi (Source Tracking)**: Mỗi sửa đổi chỉ số được gắn với một định danh nguồn gốc (`source`). Khi bán một trang bị trong Cửa hàng hoặc khi hiệu ứng kỹ năng tạm thời kết thúc, hệ thống chỉ thu hồi chính xác các biến đổi thuộc nguồn đó mà không gây ảnh hưởng đến các trang bị và bùa lợi khác.

### 1.4. Kỹ thuật Thu hồi và Tái sử dụng Thực thể (Object Pooling & Prewarm)
Để triệt tiêu hiện tượng sụt giảm khung hình do việc cấp phát bộ nhớ động liên tục trong lúc diễn ra giao tranh, lớp `ObjectPool` được thiết lập nhằm quản lý các nhóm thực thể:
- Đạn người chơi (`player_projectile`)
- Đạn quái vật (`enemy_projectile`)
- Quái cơ bản, Quái nhanh, Quái bắn xa (`enemy_basic`, `enemy_fast`, `enemy_ranged`)
- Khối vàng rơi (`gold_pickup`)

Các đối tượng được khởi tạo sẵn (Prewarm) ngay trong giai đoạn chuẩn bị của màn chơi, chuyển sang trạng thái chờ và chỉ được kích hoạt lại khi cần sử dụng, loại bỏ hoàn toàn các xung đột trong chu trình quét vật lý.

---

## CHƯƠNG 2: THIẾT KẾ CÁC PHÂN HỆ CỐT LÕI

### 2.1. Phân hệ 4 Lớp Nhân vật & Vũ khí Đa hình thái
Trò chơi cung cấp 4 lớp chiến binh với lối chơi và chiến thuật hoàn toàn khác biệt:

| Lớp Nhân vật | Màu sắc Nhận diện | Hình thái Vũ khí | Chỉ số Nổi bật | Kỹ năng Chủ động [Space] |
| :--- | :--- | :--- | :--- | :--- |
| **Xạ Thủ (AD)** | Vàng Cam | Súng bắn tầm xa | +15% Tốc đánh, +10% Chí mạng | **Lướt Chiến Thuật:** Lướt né đòn và nhận +50% Tốc đánh trong 3.0s |
| **Đấu Sĩ (Bruiser)** | Đỏ Sậm | Kiếm chém hình nón | +15% Máu, +8% Hút máu, 22 AD | **Tiếng Hú Cuồng Chiến:** +35% Tốc chạy và +20% Hút máu trong 4.0s |
| **Đỡ Đòn (Tank)** | Xanh Lục | Rìu chém đẩy lùi quái | +35% Máu tối đa, 18 Giáp | **Khiên Phản Chấn:** Giảm 50% sát thương nhận vào và phản đòn diện rộng |
| **Pháp Sư (AP)** | Tím Ánh Dương | Gậy năng lượng nổ AoE | +25% AP, +20 Điểm hồi chiêu | **Bão Lửa Cổ Ngữ:** Vòng lửa xoay quanh thiêu đốt quái mỗi 0.25s theo AP |

### 2.2. Phân hệ 7 Phúc lợi Khởi đầu Ngẫu nhiên
Mỗi chiến dịch bắt đầu với một thẻ Phúc lợi được phát ngẫu nhiên thông qua giải thuật bốc theo trọng số xác suất:
1. **Vé May Mắn:** Cộng thêm lượt đổi Lõi miễn phí và 10% Tỉ lệ chí mạng.
2. **Túi Tiền Khởi Đầu:** Cộng ngay 100 Vàng đầu ván đấu.
3. **Lõi Tiên Phong:** Cho phép chọn ngay 1 Lõi Bạc trước khi bắt đầu Đợt 1.
4. **Trái Tim Dũng Sĩ:** Cường hóa +30% Máu tối đa và hồi phục tự nhiên 2 HP/giây.
5. **Khách Quen Cửa Hàng:** Giảm 15% giá mua toàn bộ trang bị trong Cửa hàng.
6. **Quà Tặng Đợt 3:** Tự động phát thưởng 100 Vàng và một trang bị ngẫu nhiên sau khi vượt qua Đợt 3.
7. **Thợ Săn Tiền Thưởng:** Tăng 20% lượng vàng thu được khi tiêu diệt quái vật.

### 2.3. Phân hệ 12 Lõi Nâng cấp (Augment System)
Hệ thống Lõi nâng cấp phân bổ theo 3 mốc quan trọng của chiến dịch:
- **Mốc sau Đợt 1 — 4 Lõi Bạc (Cường hóa Chỉ số Nền):**
  - *Tay Bạc:* Tăng 20% Sức mạnh công kích (AD).
  - *Giày Thần Tốc:* Tăng 15% Tốc độ di chuyển.
  - *Da Trâu:* Tăng 25% Máu tối đa.
  - *Pháp Lực Dồi Dào:* Tăng 20% Sức mạnh phép thuật (AP) và 15 Điểm hồi chiêu.
- **Mốc sau Đợt 3 — 4 Lõi Vàng (Cơ chế Chiến thuật Đặc thù):**
  - *Giáp Gai (`ThornsEffect`):* Phản sát thương diện rộng khi nhận đòn.
  - *Đạn Nảy (`BounceEffect`):* Cho phép đòn tấn công nảy thêm sang mục tiêu kế cận.
  - *Xả Đạn Hàng Loạt (`MultishotEffect`):* Phóng thêm 2 tia đạn phụ góc lệch khi khai hỏa.
  - *Hút Máu Cuồng Loạn (`LowHpBerserkEffect`):* Khi máu dưới 30%, nhận ngay +100% Tốc đánh và +20% Hút máu.
- **Mốc sau Đợt 5 — 4 Lõi Kim Cương (Đột phá Lối chơi):**
  - *Găng Bảo Thạch:* Tăng 20% Tỉ lệ chí mạng và cho phép sát thương kỹ năng gây chí mạng.
  - *Cú Đấm Thần Bí (`MysticPunchEffect`):* Mỗi đòn bắn trúng giảm 0.3s hồi chiêu kỹ năng [Space].
  - *Săn Đầu Người (`HeadhunterEffect`):* Mỗi 10 quái hạ gục cộng vĩnh viễn 2% AD và 2% Tốc đánh.
  - *Vũ Khí Siêu Nhiên (`SupernaturalWeaponEffect`):* Kích hoạt kỹ năng [Space] đồng thời phóng 8 tia đạn cường hóa tỏa tròn 360 độ.

### 2.4. Phân hệ Cửa hàng & Quản lý Túi đồ 6 Ô
- **Cửa hàng Giữa đợt (`ShopManager.gd`):** Bày bán 4 vật phẩm ngẫu nhiên với tỷ lệ bậc phẩm được điều chỉnh theo số thứ tự đợt đấu.
- **Công thức Chi phí Đổi mới (Reroll Cost):**

$$\text{Chi phí Reroll} = 5 + 5n \quad (n \text{ là số lần đã đổi trong đợt})$$

- **Ưu đãi Shop Cuối:** Riêng sau Đợt 6 (Đợt Chuẩn bị), chi phí Reroll được giảm $50\%$ để người chơi tối ưu hóa bộ trang bị trước khi đấu Trùm.
- **Quy tắc Túi đồ 6 Ô:** Ràng buộc nghiêm ngặt số lượng tối đa 6 trang bị; tính năng bán đồ hoàn tiền chuẩn xác $50\%$ giá gốc và hoàn trả chính xác các chỉ số đã cộng thêm.

### 2.5. Phân hệ Đợt Chuẩn bị (Wave 6) & Trùm Cuối Chiến Hạm FSM (Wave 7)
- **Đợt Chuẩn bị (Wave 6):** Kéo dài 35 giây với lượng quái xuất hiện dày đặc gấp đôi nhưng lượng máu chỉ bằng 65%, hệ số vàng rơi nhân đôi (`gold_multiplier = 2.0`) giúp người chơi tích lũy tài nguyên tối đa.
- **Trùm Cuối (`FinalBoss.gd`):** Thiết kế theo Máy trạng thái hữu hạn với 7 trạng thái hoạt động:
  - `ENTERING`: Xuất hiện tại trung tâm đấu trường, phát tín hiệu cảnh báo và kích hoạt thanh máu trùm `BossHPBar`.
  - `IDLE`: Di chuyển lượn vòng duy trì khoảng cách tác chiến và đếm ngược thời gian ra chiêu.
  - `RING_SHOT`: Bắn loạt 14 - 18 viên đạn tỏa đều 360 độ quanh thân.
  - `CHARGE_TELEGRAPH` $\rightarrow$ `CHARGE`: Bật dải cảnh báo định hướng trước 1.0 giây, sau đó phóng nhanh với vận tốc 600 - 720 px/s gây chấn động camera.
  - `SUMMON`: Triệu hồi 4 đệ tử hỗ trợ vây ráp.
  - `PHASE_2` (Kích hoạt khi Máu trùm $\le 50\%$): Chuyển sang sắc đỏ rực, tăng 35% tốc độ di chuyển, tăng tần suất hành động và bắn 2 vòng đạn kép sole.
  - `DEAD`: Triệt tiêu toàn bộ đạn phụ, kích nổ nhiều giai đoạn, rung chấn diện rộng và chuyển tiếp sang màn hình Chiến thắng.

### 2.6. Phân hệ Âm thanh Số Tự sinh (Procedural Sound Synthesizer)
Hệ thống âm thanh được xây dựng trực tiếp trong mã nguồn thông qua lớp tài nguyên `AudioStreamWAV` với định dạng 8-bit PCM không phụ thuộc vào tệp âm thanh bên ngoài:
- Âm thanh bắn súng: Điều tần trượt dốc tuyến tính từ 650Hz xuống 180Hz trong 0.08 giây.
- Âm thanh va chạm: Xung nhiễu trắng thời lượng 0.05 giây.
- Âm thanh chí mạng: Hợp âm ba nốt tăng tiến 587Hz, 880Hz, 1174Hz.
- Âm thanh nhặt vàng: Hợp âm hai nốt leng keng 987Hz và 1318Hz.
- Âm thanh còi báo trùm: Sóng xung vuông điều tần hình sin kép 320Hz - 680Hz.
- Âm thanh nổ tung: Xung nhiễu qua bộ lọc thông thấp thời lượng 0.55 giây.

---

## CHƯƠNG 3: THIẾT KẾ GIAO DIỆN & TRẢI NGHIỆM NGƯỜI DÙNG

### 3.1. Sơ đồ Luồng Chuyển tiếp Màn chơi (State Flow Diagram)

```
[ Menu Chính (MainMenu) ]
          |
          v
[ Chọn Tướng 4 Class (CharacterSelect) ]
          |
          v
[ Lật Thẻ Phúc Lợi Đầu Trận (BonusRevealUI) ]
          |
          v
[ Chiến Đấu Đợt 1..5 (Combat Arena + HUD) ]
          |
          +---> Sau Đợt 1, 3, 5: [ Chọn Lõi Nâng Cấp (AugmentUI) ] ---> [ Cửa Hàng Shop 6 Ô (ShopUI) ]
          |
          +---> Sau Đợt 2, 4:   [ Cửa Hàng Shop 6 Ô (ShopUI) ]
          |
          v
[ Đợt Chuẩn Bị Wave 6 (Vàng x2) ]
          |
          v
[ Cửa Hàng Cuối (Final Shop - Giảm 50% Reroll) ]
          |
          v
[ Trận Đấu Trùm Cuối Wave 7 (FinalBoss FSM) ]
          |
          v
[ Màn Hình Tổng Kết & Điểm Số Kỷ Lục (ResultUI) ]
```

### 3.2. Công thức Đánh giá Hiệu năng & Tính điểm Kỷ lục
Hệ thống tính điểm cuối ván chơi được thiết kế nhằm đánh giá toàn diện kỹ năng người chơi:

$$\text{Tổng Điểm} = (\text{Quái diệt} \times 10) + \text{Thời gian sống (giây)} + (\text{Máu còn lại} \times 5) + \text{Thưởng Trùm } (1000) + \text{Vàng dư}$$

Dữ liệu điểm cao nhất (`high_score`) được tự động mã hóa và lưu trữ lâu dài vào tệp cấu hình máy tính `highscore.cfg`.

---

## CHƯƠNG 4: HÌNH ẢNH TRIỂN KHAI THỰC TẾ TRÊN ENGINE

Dưới đây là các hình ảnh ghi nhận quá trình vận hành thực tế của trò chơi trên Godot Engine:

### 4.1. Giao diện Menu Khởi đầu
![Màn hình Menu Chính của trò chơi](img/hinh_1_menu_chinh.png)
*Hình 4.1: Giao diện Menu Chính với tiêu đề, bảng kỷ lục điểm cao và các nút xuất kích.*

### 4.2. Màn hình Lựa chọn 4 Lớp Nhân vật
![Màn hình Chọn Lớp Nhân vật](img/hinh_2_chon_nhan_vat.png)
*Hình 4.2: Hệ thống lựa chọn đầy đủ 4 Lớp nhân vật với màu sắc và đặc tính chiến thuật riêng biệt.*

### 4.3. Cơ chế Lật Thẻ Phúc lợi Ngẫu nhiên Đầu trận
![Màn hình Lật Thẻ Phúc lợi](img/hinh_3_phuc_loi_dau_tran.png)
*Hình 4.3: Hoạt họa lật mở thẻ Phúc lợi ngẫu nhiên định hình phong cách chiến thuật đầu ván đấu.*

### 4.4. Không gian Đấu trường & Giao diện Tác chiến Thời gian thực
![Giao diện Chiến đấu Thời gian thực](img/hinh_4_chien_dau_wave1.png)
*Hình 4.4: Đấu trường Arena với thanh máu người chơi, vũ khí tự động ngắm và các thực thể quái vật.*

### 4.5. Giao diện Chọn Lõi Nâng cấp Đa bậc
![Giao diện Chọn Lõi Nâng cấp](img/hinh_5_chon_loi_nang_cap.png)
*Hình 4.5: Bảng chọn 3 Lõi nâng cấp hiển thị trực quan theo cấp độ hiếm kèm tính năng Reroll Lõi.*

### 4.6. Phân hệ Cửa hàng Kinh tế & Quản lý Túi đồ 6 Ô
![Giao diện Cửa hàng Trang bị](img/hinh_6_cua_hang_trang_bi.png)
*Hình 4.6: Cửa hàng trang bị giữa đợt với 4 vật phẩm bày bán, Túi đồ 6 ô và bảng tổng hợp chỉ số động.*

### 4.7. Đợt Chuẩn bị Tích lũy Kinh tế (Wave 6)
![Đợt Chuẩn bị Wave 6](img/hinh_7_dot_chuan_bi_wave6.png)
*Hình 4.7: Đợt Chuẩn bị với mật độ quái đông và thông báo nhân đôi lượng vàng rơi trước trận Boss.*

### 4.8. Trận Đấu Trùm Cuối Chiến Hạm FSM (Wave 7)
![Trận Đấu Trùm Cuối Wave 7](img/hinh_8_trum_cuoi_wave7.png)
*Hình 4.8: Thực thể Trùm Cuối với vòng 8 gai xoay tròn, dải ngắm cảnh báo đỏ và thanh máu BossHPBar.*

### 4.9. Màn hình Tổng kết Ván đấu & Kỷ lục Chiến dịch
![Màn hình Tổng kết Kết quả](img/hinh_9_tong_ket_chien_thang.png)
*Hình 4.9: Màn hình Tổng kết ván đấu chi tiết điểm số, các Lõi nâng cấp và bộ 6 trang bị đã sử dụng.*

---

## CHƯƠNG 5: KIỂM THỬ TỰ ĐỘNG, ĐÁNH GIÁ HIỆU NĂNG & KẾT LUẬN

### 5.1. Kết quả Bộ Kiểm thử Tự động (Automated Test Suites)
Để đảm bảo tính toàn vẹn của mã nguồn và độ tin cậy của phần mềm, toàn bộ các kịch bản kiểm thử tích hợp tự động đã được thực thi độc lập trên môi trường dòng lệnh không giao diện (Headless Engine):

```text
======================================================================
   KẾT QUẢ KIỂM THỬ TỰ ĐỘNG TỔNG THỂ DỰ ÁN ARAM MAYHEM CAMPAIGN
======================================================================
1. Bộ Kiểm thử Giai đoạn 3 (TestPhase3.tscn):
   - Kiểm tra 10 Trang bị, 12 Lõi, Túi 6 Ô, Shop Reroll: 8 / 8 BÀI ĐẠT CHUẨN (100%)
2. Bộ Kiểm thử Giai đoạn 4 (TestPhase4.tscn):
   - Kiểm tra Wave 6 Prep, Wave 7 Boss FSM, Audio, Score: 8 / 8 BÀI ĐẠT CHUẨN (100%)
3. Bộ Kiểm thử Giai đoạn 5 (TestPhase5.tscn):
   - Kiểm tra 4 Class, Vũ khí Melee/AoE, 4 Kỹ năng, UI:  8 / 8 BÀI ĐẠT CHUẨN (100%)
======================================================================
   TỔNG HỢP: 24 / 24 BÀI KIỂM THỬ ĐẠT CHUẨN TUYỆT ĐỐI (100%)
======================================================================
```

### 5.2. Đánh giá Hiệu năng Vận hành
- Tốc độ khung hình: Duy trì ổn định ở mức 60 FPS trong mọi tình huống chiến đấu, kể cả khi mật độ quái đạt giới hạn 55 thực thể ở Đợt Chuẩn bị.
- Mức tiêu thụ bộ nhớ: Bộ nhớ RAM chiếm dụng ổn định dưới 110 MB nhờ cơ chế Object Pooling và đồ họa hình học nội sinh.
- Thời gian tải màn chơi: Khởi tạo tức thì (dưới 0.3 giây) do toàn bộ tài nguyên hình học và âm thanh đều được tạo sinh trực tiếp từ mã nguồn.

### 5.3. Kết luận và Hướng Phát triển
Đề tài **ARAM Mayhem Campaign** đã hoàn thành xuất sắc toàn bộ các mục tiêu đặt ra:
- Hiện thực hóa thành công một sản phẩm trò chơi điện tử thể loại Roguelite Survivor hoàn chỉnh từ giao diện Menu đến trận chiến trùm cuối.
- Chứng minh tính ưu việt của kiến trúc **Data-Driven kết hợp Event Bus** trong việc xây dựng hệ thống chỉ số phức tạp và dễ bảo trì.
- Dự án có thể xuất bản độc lập thành tệp thực thi Windows Desktop và mở rộng thêm các lớp nhân vật, trang bị hoặc cơ chế bản đồ mới trong tương lai một cách thuận tiện.

