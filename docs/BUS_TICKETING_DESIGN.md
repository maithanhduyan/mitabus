# MiTaBus - Thiết kế Module Bán Vé Xe Khách & Vận Chuyển Hàng Hóa (Odoo 19)

## 1. Tổng quan

Hệ thống bán vé xe khách và quản lý vận chuyển hàng hóa cho **MITA BUS**, tham khảo mô hình vận hành thực tế từ **Xe Khách Minh Tâm** ([xeminhtam.com](https://xeminhtam.com)).

### Tuyến thí điểm
| Chiều | Điểm đi | Trạm trung gian | Trạm cuối |
|-------|---------|------------------|-----------|
| Đi | TP. Hồ Chí Minh | Xã Phú Túc → Đồng Tháp (QL60) → Trạm Đông Á | Vĩnh Long |
| Về | Vĩnh Long | Trạm Đông Á → Đồng Tháp (QL60) → Xã Phú Túc | TP. Hồ Chí Minh |

### Dịch vụ
- **Vận chuyển hành khách**: Xe 28 ghế, giá vé ~90.000đ/vé
- **Vận chuyển hàng hóa**: Nhận/trả hàng tại nhiều trạm trung gian, vận chuyển hỏa tốc trong ngày
- **Bồi thường thất lạc**: Khi hàng mất/thiếu/hỏng

---

## 2. Odoo Module: `bus_ticketing`

### 2.1 Models

#### `bus.route` — Tuyến xe
| Field | Type | Description |
|-------|------|-------------|
| `name` | Char | Tên tuyến (VD: "TP.HCM - Vĩnh Long") |
| `code` | Char | Mã tuyến (VD: "HCM-VL") |
| `origin_station_id` | Many2one → `bus.station` | Trạm xuất phát |
| `destination_station_id` | Many2one → `bus.station` | Trạm cuối |
| `distance_km` | Float | Khoảng cách (km) |
| `duration_hours` | Float | Thời gian di chuyển (giờ) |
| `stop_ids` | One2many → `bus.route.stop` | Danh sách trạm dừng |
| `active` | Boolean | Đang hoạt động |
| `is_round_trip` | Boolean | Có chiều ngược lại |
| `reverse_route_id` | Many2one → `bus.route` | Tuyến chiều ngược |

#### `bus.station` — Trạm/Văn phòng
| Field | Type | Description |
|-------|------|-------------|
| `name` | Char | Tên trạm (VD: "Trạm Hồ Chí Minh") |
| `code` | Char | Mã trạm (VD: "HCM") |
| `address` | Text | Địa chỉ (VD: "204C Sư Vạn Hạnh, P.9, Q.5, TP.HCM") |
| `city` | Char | Tỉnh/Thành phố |
| `phone_ticket` | Char | Hotline vé (VD: "02838.306.106") |
| `phone_cargo` | Char | Hotline hàng hóa (VD: "02839.381.019") |
| `station_type` | Selection | [`terminal`, `intermediate`, `pickup_point`] |
| `latitude` | Float | Vĩ độ |
| `longitude` | Float | Kinh độ |
| `partner_id` | Many2one → `res.partner` | Liên kết partner |
| `active` | Boolean | Đang hoạt động |

#### `bus.route.stop` — Trạm dừng trên tuyến
| Field | Type | Description |
|-------|------|-------------|
| `route_id` | Many2one → `bus.route` | Tuyến |
| `station_id` | Many2one → `bus.station` | Trạm |
| `sequence` | Integer | Thứ tự dừng |
| `distance_from_origin` | Float | Khoảng cách từ trạm xuất phát (km) |
| `duration_from_origin` | Float | Thời gian từ trạm xuất phát (phút) |
| `allow_boarding` | Boolean | Cho phép đón khách |
| `allow_alighting` | Boolean | Cho phép trả khách |
| `allow_cargo` | Boolean | Cho phép nhận/trả hàng |

#### `bus.vehicle` — Xe
| Field | Type | Description |
|-------|------|-------------|
| `name` | Char | Tên/Biển số xe |
| `license_plate` | Char | Biển số |
| `vehicle_type` | Selection | [`seat_28`, `seat_34`, `seat_40`, `limousine`] |
| `seat_capacity` | Integer | Số ghế (VD: 28) |
| `cargo_capacity_kg` | Float | Trọng tải hàng hóa (kg) |
| `seat_map_template_id` | Many2one → `bus.seat.map` | Sơ đồ ghế |
| `driver_id` | Many2one → `res.partner` | Tài xế chính |
| `co_driver_id` | Many2one → `res.partner` | Phụ xe |
| `state` | Selection | [`available`, `in_trip`, `maintenance`] |
| `active` | Boolean | Đang hoạt động |

#### `bus.seat.map` — Sơ đồ ghế
| Field | Type | Description |
|-------|------|-------------|
| `name` | Char | Tên sơ đồ (VD: "28 Ghế - Standard") |
| `vehicle_type` | Selection | Loại xe |
| `total_seats` | Integer | Tổng số ghế |
| `seat_ids` | One2many → `bus.seat` | Danh sách ghế |

#### `bus.seat` — Ghế
| Field | Type | Description |
|-------|------|-------------|
| `seat_map_id` | Many2one → `bus.seat.map` | Sơ đồ |
| `name` | Char | Mã ghế (VD: "A01", "B03") |
| `row` | Integer | Hàng |
| `column` | Integer | Cột |
| `floor` | Selection | [`lower`, `upper`] Tầng (nếu xe giường nằm) |
| `seat_type` | Selection | [`normal`, `vip`, `disabled`] |

#### `bus.trip` — Chuyến xe
| Field | Type | Description |
|-------|------|-------------|
| `name` | Char | Mã chuyến (auto-generate VD: "HCM-VL-20260402-0600") |
| `route_id` | Many2one → `bus.route` | Tuyến |
| `vehicle_id` | Many2one → `bus.vehicle` | Xe |
| `driver_id` | Many2one → `res.partner` | Tài xế |
| `departure_datetime` | Datetime | Giờ khởi hành |
| `arrival_datetime` | Datetime | Giờ dự kiến đến |
| `state` | Selection | [`draft`, `confirmed`, `boarding`, `departed`, `arrived`, `cancelled`] |
| `available_seats` | Integer | Số ghế trống (computed) |
| `ticket_ids` | One2many → `bus.ticket` | Danh sách vé |
| `cargo_ids` | One2many → `bus.cargo` | Danh sách hàng hóa |
| `notes` | Text | Ghi chú |

#### `bus.ticket` — Vé xe
| Field | Type | Description |
|-------|------|-------------|
| `name` | Char | Mã vé (auto: "VE-20260402-001") |
| `trip_id` | Many2one → `bus.trip` | Chuyến xe |
| `passenger_id` | Many2one → `res.partner` | Hành khách |
| `passenger_name` | Char | Tên hành khách |
| `passenger_phone` | Char | SĐT hành khách |
| `passenger_email` | Char | Email |
| `boarding_stop_id` | Many2one → `bus.route.stop` | Trạm lên |
| `alighting_stop_id` | Many2one → `bus.route.stop` | Trạm xuống |
| `seat_id` | Many2one → `bus.seat` | Ghế |
| `price` | Monetary | Giá vé |
| `currency_id` | Many2one → `res.currency` | Tiền tệ |
| `state` | Selection | [`draft`, `confirmed`, `checked_in`, `completed`, `cancelled`, `refunded`] |
| `booking_datetime` | Datetime | Thời điểm đặt vé |
| `payment_method` | Selection | [`cash`, `bank_transfer`, `momo`, `vnpay`, `zalopay`] |
| `qr_code` | Binary | QR code vé (dùng check-in) |
| `sale_order_id` | Many2one → `sale.order` | Liên kết đơn hàng |

#### `bus.pricing.rule` — Bảng giá theo đoạn
| Field | Type | Description |
|-------|------|-------------|
| `route_id` | Many2one → `bus.route` | Tuyến |
| `from_stop_id` | Many2one → `bus.route.stop` | Trạm lên |
| `to_stop_id` | Many2one → `bus.route.stop` | Trạm xuống |
| `price` | Monetary | Giá vé |
| `vehicle_type` | Selection | Loại xe |
| `date_from` | Date | Áp dụng từ |
| `date_to` | Date | Áp dụng đến |
| `is_holiday_price` | Boolean | Giá lễ/Tết |

#### `bus.cargo` — Đơn hàng hóa
| Field | Type | Description |
|-------|------|-------------|
| `name` | Char | Mã đơn (auto: "HH-20260402-001") |
| `trip_id` | Many2one → `bus.trip` | Chuyến xe |
| `sender_id` | Many2one → `res.partner` | Người gửi |
| `sender_name` | Char | Tên người gửi |
| `sender_phone` | Char | SĐT người gửi |
| `receiver_name` | Char | Tên người nhận |
| `receiver_phone` | Char | SĐT người nhận |
| `pickup_stop_id` | Many2one → `bus.route.stop` | Trạm gửi |
| `delivery_stop_id` | Many2one → `bus.route.stop` | Trạm nhận |
| `description` | Text | Mô tả hàng hóa |
| `weight_kg` | Float | Trọng lượng (kg) |
| `quantity` | Integer | Số kiện |
| `price` | Monetary | Phí vận chuyển |
| `currency_id` | Many2one → `res.currency` | Tiền tệ |
| `state` | Selection | [`draft`, `received`, `in_transit`, `delivered`, `returned`, `lost`] |
| `is_express` | Boolean | Hỏa tốc (trong ngày) |
| `cod_amount` | Monetary | Tiền thu hộ COD |
| `insurance_amount` | Monetary | Tiền bảo hiểm |
| `payment_method` | Selection | [`cash`, `bank_transfer`, `prepaid`] |
| `received_datetime` | Datetime | Thời điểm nhận hàng |
| `delivered_datetime` | Datetime | Thời điểm giao hàng |
| `tracking_ids` | One2many → `bus.cargo.tracking` | Lịch sử vận chuyển |

#### `bus.cargo.tracking` — Tracking hàng hóa
| Field | Type | Description |
|-------|------|-------------|
| `cargo_id` | Many2one → `bus.cargo` | Đơn hàng |
| `station_id` | Many2one → `bus.station` | Trạm |
| `datetime` | Datetime | Thời điểm |
| `status` | Selection | [`received`, `loaded`, `transit`, `unloaded`, `delivered`] |
| `note` | Text | Ghi chú |
| `user_id` | Many2one → `res.users` | Nhân viên xử lý |

#### `bus.schedule` — Lịch trình cố định
| Field | Type | Description |
|-------|------|-------------|
| `route_id` | Many2one → `bus.route` | Tuyến |
| `vehicle_type` | Selection | Loại xe |
| `departure_time` | Float | Giờ khởi hành (VD: 6.5 = 06:30) |
| `days_of_week` | Char | Ngày trong tuần ("1,2,3,4,5,6,7") |
| `active` | Boolean | Đang hoạt động |
| `default_price` | Monetary | Giá mặc định |

---

### 2.2 Dữ liệu thí điểm

#### Trạm/Văn phòng
| Code | Tên | Địa chỉ | Loại | ĐT Vé | ĐT Hàng |
|------|-----|---------|------|--------|----------|
| HCM | Trạm Hồ Chí Minh | 204C Sư Vạn Hạnh, P.An Đông, TP.HCM | terminal | 02838.306.106 | 02839.381.019 |
| BXMT | Bến Xe Miền Tây | 395 Kinh Dương Vương, P.An Lạc, Q.Bình Tân | terminal | 02838.306.106 | — |
| PTU | Xã Phú Túc | Số 18, KP2, Xã Phú Túc, Tỉnh Vĩnh Long | intermediate | 0948.222.207 | 02753.869.222 |
| DTP | Đồng Tháp (QL60) | Số 13/8B, Nguyễn Thị Thập, P.Thới Sơn, Tỉnh Đồng Tháp | intermediate | 02733.974.588 | 02733.974.588 |
| DGA | Trạm Đông Á | 105A, Đại lộ Đồng Khởi, P.Phú Tân, Tỉnh Vĩnh Long | intermediate | 02753.560.570 | 02753.560.570 |
| VLG | Vĩnh Long | 121 A3, Nguyễn Thị Định, P.Phú Tân, Tỉnh Vĩnh Long | terminal | 02753.813.688 | 02753.575.809 |

#### Tuyến HCM → Vĩnh Long (Lộ trình trạm dừng)
| Thứ tự | Trạm | Đón khách | Trả khách | Hàng hóa |
|--------|------|-----------|-----------|----------|
| 1 | HCM (Sư Vạn Hạnh) | ✅ | ❌ | ✅ |
| 2 | BXMT (Bến Xe Miền Tây) | ✅ | ❌ | ❌ |
| 3 | PTU (Xã Phú Túc) | ✅ | ✅ | ✅ |
| 4 | DTP (Đồng Tháp/QL60) | ✅ | ✅ | ✅ |
| 5 | DGA (Trạm Đông Á) | ❌ | ✅ | ✅ |
| 6 | VLG (Vĩnh Long) | ❌ | ✅ | ✅ |

#### Bảng giá (tham khảo)
| Đoạn | Loại xe | Giá |
|------|---------|-----|
| HCM → Vĩnh Long (full tuyến) | 28 Ghế | 90.000đ |
| HCM → Đồng Tháp | 28 Ghế | 90.000đ |
| HCM → Xã Phú Túc | 28 Ghế | 70.000đ |

---

### 2.3 Luồng nghiệp vụ chính

#### A. Bán vé hành khách
```
Khách đặt vé (Website/Quầy/Điện thoại)
  → Chọn tuyến, ngày, giờ khởi hành
  → Chọn trạm lên / trạm xuống
  → Hệ thống tính giá theo đoạn (bus.pricing.rule)
  → Chọn ghế (bus.seat trên trip)
  → Xác nhận & Thanh toán
  → Xuất vé QR code
  → Ngày đi: Check-in bằng QR tại trạm
  → Hoàn thành chuyến
```

#### B. Vận chuyển hàng hóa
```
Nhận hàng tại trạm (bất kỳ trạm allow_cargo)
  → Nhập thông tin người gửi/nhận
  → Chọn trạm giao
  → Cân/đo → Tính phí
  → Hàng hỏa tốc: Gửi ngay chuyến gần nhất
  → Tracking từng trạm (received → loaded → transit → unloaded → delivered)
  → Người nhận đến trạm nhận hàng
  → Hoàn thành / Bồi thường nếu thất lạc
```

#### C. Quản lý chuyến xe
```
Lịch trình cố định (bus.schedule) → Auto-tạo bus.trip hàng ngày
  → Gán xe (bus.vehicle) + tài xế
  → Theo dõi: draft → confirmed → boarding → departed → arrived
  → Dashboard: Tỷ lệ lấp đầy, doanh thu/chuyến, hàng hóa/chuyến
```

---

### 2.4 Sơ đồ Module Dependencies

```
bus_ticketing
├── depends: base, mail, sale, website, payment
├── models/
│   ├── bus_station.py
│   ├── bus_route.py
│   ├── bus_route_stop.py
│   ├── bus_vehicle.py
│   ├── bus_seat_map.py
│   ├── bus_seat.py
│   ├── bus_schedule.py
│   ├── bus_trip.py
│   ├── bus_ticket.py
│   ├── bus_pricing_rule.py
│   ├── bus_cargo.py
│   └── bus_cargo_tracking.py
├── views/
│   ├── bus_station_views.xml
│   ├── bus_route_views.xml
│   ├── bus_vehicle_views.xml
│   ├── bus_trip_views.xml
│   ├── bus_ticket_views.xml
│   ├── bus_cargo_views.xml
│   ├── bus_dashboard_views.xml
│   └── menu.xml
├── data/
│   ├── bus_station_data.xml        (6 trạm thí điểm)
│   ├── bus_route_data.xml          (2 tuyến HCM↔VL)
│   ├── bus_seat_map_data.xml       (sơ đồ 28 ghế)
│   ├── bus_pricing_data.xml        (bảng giá)
│   ├── bus_schedule_data.xml       (lịch trình cố định)
│   ├── sequence_data.xml
│   └── cron_data.xml               (auto-tạo trip hàng ngày)
├── security/
│   ├── security.xml                (groups: manager, operator, agent)
│   └── ir.model.access.csv
├── controllers/
│   ├── booking_controller.py       (API đặt vé online)
│   └── cargo_controller.py         (API kiểm tra đơn hàng)
├── static/
│   └── src/
│       └── xml/                    (website booking widget)
└── wizard/
    ├── trip_generator_wizard.py    (tạo chuyến hàng loạt)
    └── cargo_delivery_wizard.py    (xác nhận giao hàng)
```

---

### 2.5 Phân quyền

| Group | Quyền |
|-------|-------|
| `bus_ticketing.group_agent` | Bán vé, nhận hàng, check-in, xem chuyến |
| `bus_ticketing.group_operator` | + Quản lý chuyến, gán xe/tài xế, xác nhận giao hàng |
| `bus_ticketing.group_manager` | + Quản lý tuyến/trạm/xe/giá, báo cáo, cấu hình |

---

### 2.6 Tích hợp

| Tích hợp | Mục đích |
|----------|----------|
| `sale.order` | Liên kết vé/hàng hóa với đơn hàng Odoo |
| `payment` | Thanh toán online (VNPay, MoMo, ZaloPay) |
| `website` | Đặt vé trực tuyến, kiểm tra vé/đơn hàng |
| `mail` | Gửi email/SMS xác nhận vé, thông báo hàng đến |
| `account` | Kế toán doanh thu vé/hàng hóa |
| QR Code | Check-in vé, tracking hàng hóa |

---

### 2.7 Website Features (tham khảo xeminhtam.com)

1. **Đặt vé online**: Chọn nơi đi → nơi đến → ngày → hiển thị chuyến → chọn ghế → thanh toán
2. **Kiểm tra vé**: Nhập mã vé → hiển thị thông tin chuyến, ghế, trạng thái
3. **Kiểm tra đơn hàng**: Nhập mã đơn → tracking hàng hóa theo trạm
4. **Lộ trình phổ biến**: Cards hiển thị tuyến + giá
5. **Danh sách văn phòng**: Tabs theo tỉnh, có bản đồ Google Maps
