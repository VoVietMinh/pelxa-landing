# Pelxa — Color Palette

> Tone định hướng: **Clean · Clear · Smart · Future-ready**
> Hệ màu chủ đạo: **Xanh dương (Blue spectrum)** — gợi cảm giác công nghệ, đáng tin cậy, toàn cầu, và hướng tới tương lai.

---

## 1. Primary Colors (Màu chính)

| Tên | HEX | RGB | Sử dụng |
|-----|-----|-----|---------|
| **Pelxa Blue** | `#0066FF` | rgb(0, 102, 255) | Màu thương hiệu chính, CTA, logo |
| **Deep Ocean** | `#0052E0` | rgb(0, 82, 224) | Hover state, gradient dark |
| **Sky Pulse** | `#0099FF` | rgb(0, 153, 255) | Accent, link, secondary CTA |
| **Cyan Spark** | `#00C2FF` | rgb(0, 194, 255) | Highlight, badge, "smart" accent |

## 2. Dark / Neutral Colors

| Tên | HEX | RGB | Sử dụng |
|-----|-----|-----|---------|
| **Midnight** | `#001A4D` | rgb(0, 26, 77) | Background tối, hero overlay |
| **Navy Ink** | `#0A2540` | rgb(10, 37, 64) | Heading, text quan trọng |
| **Slate** | `#3D4F66` | rgb(61, 79, 102) | Body text |
| **Cool Gray** | `#7A8AA0` | rgb(122, 138, 160) | Subtitle, caption |

## 3. Light / Background Colors

| Tên | HEX | RGB | Sử dụng |
|-----|-----|-----|---------|
| **Pure White** | `#FFFFFF` | rgb(255, 255, 255) | Background chính |
| **Frost** | `#F4F8FE` | rgb(244, 248, 254) | Section background |
| **Ice Blue** | `#E0F0FF` | rgb(224, 240, 255) | Card, panel, illustration fill |
| **Soft Border** | `#D6E2F0` | rgb(214, 226, 240) | Divider, input border |

## 4. Functional Colors

| Tên | HEX | Sử dụng |
|-----|-----|---------|
| **Success** | `#10B981` | Trạng thái thành công |
| **Warning** | `#F59E0B` | Cảnh báo |
| **Error** | `#EF4444` | Lỗi, destructive |
| **Info** | `#0099FF` | Thông báo (đồng bộ với Sky Pulse) |

---

## 5. Gradients (Gradient chính)

### Primary Gradient — Hero / Logo
```css
background: linear-gradient(135deg, #0066FF 0%, #0099FF 100%);
```

### Smart Gradient — Accent / Button hover
```css
background: linear-gradient(135deg, #0099FF 0%, #00C2FF 100%);
```

### Future Gradient — Cover / Banner
```css
background: linear-gradient(135deg, #001A4D 0%, #0052E0 50%, #00B4FF 100%);
```

### Subtle Gradient — Background section
```css
background: linear-gradient(180deg, #FFFFFF 0%, #F4F8FE 100%);
```

---

## 6. Tỉ lệ sử dụng (60-30-10 rule)

- **60%** — Trắng & nền sáng (`#FFFFFF`, `#F4F8FE`)
- **30%** — Xanh dương chính (`#0066FF`, `#0099FF`)
- **10%** — Accent & dark (`#00C2FF`, `#0A2540`)

---

## 7. Lưu ý sử dụng

- **Không** dùng xanh dương trên nền tối < `#0A2540` — sẽ mất contrast.
- **Luôn** đảm bảo contrast ratio ≥ 4.5:1 cho text (WCAG AA).
- Khi in ấn, dùng phiên bản CMYK tương đương `#0066FF` ≈ `C100 M60 Y0 K0`.
- Không dùng quá 2 sắc xanh chính trong cùng 1 component để giữ sự **clean**.
