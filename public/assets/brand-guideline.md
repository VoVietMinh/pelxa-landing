# Pelxa — Brand Guideline

> **Pelxa** — Giải pháp Content · Ads · Traffic toàn cầu, hướng tới tương lai.
> Phiên bản: 1.0 | Cập nhật: 2026

---

## 1. Brand Essence (Bản chất thương hiệu)

### Mission
Cung cấp giải pháp **Content, Quảng cáo và Traffic** thông minh, hiệu quả ở quy mô **toàn cầu**, giúp khách hàng tăng trưởng bền vững trong kỷ nguyên số.

### Vision
Trở thành nền tảng tăng trưởng số (digital growth platform) **future-ready** — kết nối thương hiệu với người dùng đúng nơi, đúng lúc, đúng thông điệp.

### Core Values
- **Clean** — Minh bạch, rõ ràng trong dữ liệu và cam kết.
- **Clear** — Truyền thông đơn giản, dễ hiểu, đúng trọng tâm.
- **Smart** — Ứng dụng AI & data-driven trong mọi giải pháp.
- **Global & Future** — Tư duy toàn cầu, sẵn sàng cho ngày mai.

### Brand Personality
Chuyên nghiệp · Thân thiện · Tự tin · Có chiều sâu công nghệ.

---

## 2. Logo

### Cấu trúc
Logo Pelxa gồm **2 thành phần**:
1. **Symbol (P-mark)** — Chữ "P" cách điệu kết hợp đường cong & điểm quỹ đạo, biểu tượng cho dòng chảy traffic và phạm vi toàn cầu.
2. **Wordmark** — "pelxa" viết thường, sans-serif đậm, tạo cảm giác hiện đại & tiếp cận.

### Phiên bản
| File | Sử dụng |
|------|---------|
| `logo-primary.svg` / `.png` | Logo chuẩn — website, văn bản, brochure |
| `logo-icon.svg` / `.png` | Chỉ symbol — avatar, watermark |
| `favicon.png` | Trình duyệt, tab |
| `app-icon.png` | App icon iOS/Android (1024×1024) |

### Clear Space
Khoảng trống tối thiểu xung quanh logo = **1× chiều cao của symbol**.

### Min Size
- Web: tối thiểu **120px** chiều rộng cho `logo-primary`.
- Print: tối thiểu **25mm** chiều rộng.
- Icon: tối thiểu **24×24px**.

### ❌ Không được làm
- Không xoay, nghiêng, kéo méo logo.
- Không đổi màu ngoài bộ palette chính thức.
- Không đặt logo trên nền có contrast thấp (<3:1).
- Không thêm hiệu ứng đổ bóng, viền, glow ngoài quy chuẩn.
- Không thay đổi font wordmark.

---

## 3. Color System

Xem chi tiết tại `color-palette.md`.

**Tóm tắt nhanh:**
- Primary: `#0066FF` (Pelxa Blue)
- Dark: `#0A2540` (Navy Ink)
- Light BG: `#F4F8FE` (Frost)
- Accent: `#00C2FF` (Cyan Spark)

---

## 4. Typography

### Font Family
- **Primary (Display & UI):** Inter, Helvetica, Arial, sans-serif
- **Alternative:** Manrope, Plus Jakarta Sans, SF Pro
- **Mono (Code/data):** JetBrains Mono, Fira Code

### Type Scale (Web)

| Level | Size | Weight | Line-height | Sử dụng |
|-------|------|--------|-------------|---------|
| Display | 64px | 800 | 1.1 | Hero headline |
| H1 | 48px | 700 | 1.15 | Page title |
| H2 | 36px | 700 | 1.2 | Section title |
| H3 | 24px | 600 | 1.3 | Sub-section |
| Body L | 18px | 400 | 1.6 | Lead paragraph |
| Body | 16px | 400 | 1.6 | Default text |
| Caption | 14px | 500 | 1.4 | Label, meta |
| Tiny | 12px | 500 | 1.4 | Footnote |

### Quy tắc
- **Heading** dùng `Navy Ink (#0A2540)` hoặc trắng trên nền xanh.
- **Body** dùng `Slate (#3D4F66)`.
- Khoảng cách chữ (letter-spacing) cho heading lớn: **-0.02em đến -0.03em**.

---

## 5. Iconography

### Style
- **Stroke-based**, độ dày 2.5–3px, bo tròn đầu (round cap).
- Grid: **24×24** hoặc **64×64**.
- Màu: `#0066FF` (chính) + `#0099FF` / `#00C2FF` (accent).
- Có thể fill nhẹ bằng `#E0F0FF` cho hiệu ứng layered.

### Icon set khởi tạo
`content` · `ads` · `traffic` · `global` · `future` · `analytics` · `smart-ai` · `connect`

Xem trong thư mục `/icons/`.

### Quy tắc
- Không trộn nhiều style icon (outline + filled) trong cùng một section.
- Khoảng padding tối thiểu trong icon container: **20%** cạnh ngoài.

---

## 6. Imagery & Illustration

### Định hướng
- **Tone xanh dương** chủ đạo, có thể pha trộn cyan, trắng.
- Ưu tiên ảnh **abstract tech** — network, data flow, gradient mesh, light streaks.
- Avoid: ảnh stock generic, tone ấm (vàng/cam) làm chủ đạo.

### Photography
- Subject: con người làm việc với công nghệ, không gian sáng-sạch, văn phòng hiện đại.
- Filter: tăng nhẹ blue tint, giảm saturation 5–10%.

### Illustration
- Flat hoặc 2.5D, đường nét gọn, dùng gradient `#0066FF → #00C2FF`.
- Hạn chế chi tiết rườm rà — giữ tinh thần **clean & smart**.

---

## 7. UI Components (Web)

### Button
- **Primary:** background `#0066FF`, text trắng, radius `12px`, padding `14px 28px`.
- **Hover:** gradient `#0066FF → #0099FF`, shadow `0 8px 24px rgba(0,102,255,0.25)`.
- **Secondary:** border `1.5px #0066FF`, text `#0066FF`, background trong suốt.

### Card
- Background `#FFFFFF`, border `1px #D6E2F0`, radius `16px`.
- Shadow: `0 4px 16px rgba(10, 37, 64, 0.06)`.

### Input
- Border `1.5px #D6E2F0`, radius `10px`, padding `12px 16px`.
- Focus: border `#0066FF`, ring `0 0 0 4px rgba(0,102,255,0.12)`.

### Spacing scale
`4 · 8 · 12 · 16 · 24 · 32 · 48 · 64 · 96 px`

### Border radius scale
`6 · 10 · 12 · 16 · 24 · 32 px`

---

## 8. Voice & Tone

### Tiếng nói thương hiệu
- **Tự tin** mà không kiêu — nói bằng dữ liệu, không hứa suông.
- **Đơn giản** — câu ngắn, từ rõ, không thuật ngữ rườm.
- **Hướng tới hành động** — luôn có CTA cụ thể.
- **Toàn cầu** — tránh slang địa phương khi viết tiếng Anh.

### Ví dụ
| ❌ Tránh | ✅ Nên dùng |
|---------|-------------|
| "Chúng tôi là agency hàng đầu" | "Tăng traffic chất lượng — đo bằng kết quả thực." |
| "Solutions tối ưu hóa hiệu suất" | "Quảng cáo đúng người. Đúng lúc. Đúng chi phí." |
| "Cutting-edge synergy" | "Smart. Clean. Global." |

---

## 9. Application Examples

### Website
- Hero: nền gradient `Future Gradient` + headline trắng + CTA xanh.
- Section trắng/Frost xen kẽ, không quá 3 màu accent / page.

### Social Media
- Cover: dùng `social-cover.png` làm template chính.
- Post: tỷ lệ vuông 1:1, logo góc trên trái, accent line dưới cùng.

### App Icon
- Dùng `app-icon.png` (1024×1024). iOS/Android tự bo góc.

### Email Signature
```
[Tên] | Pelxa
Content · Ads · Traffic — Global, Future Ready
pelxa.com
```

---

## 10. Files trong bộ Brand Kit

```
pelxa-branding/
├── logo-primary.png     ← Logo đầy đủ (mark + wordmark)
├── logo-primary.svg
├── logo-icon.png        ← Chỉ symbol
├── logo-icon.svg
├── favicon.png          ← 64×64
├── favicon.svg
├── app-icon.png         ← 1024×1024
├── app-icon.svg
├── social-cover.png     ← 1200×630 (OG image)
├── social-cover.svg
├── color-palette.md
├── brand-guideline.md
└── icons/
    ├── content.svg
    ├── ads.svg
    ├── traffic.svg
    ├── global.svg
    ├── future.svg
    ├── analytics.svg
    ├── smart-ai.svg
    └── connect.svg
```

---

## Liên hệ

Mọi thắc mắc về sử dụng brand → **brand@pelxa.com**

© 2026 Pelxa. All rights reserved.
