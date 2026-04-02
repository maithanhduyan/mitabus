#!/bin/bash
set -euo pipefail
#
# Cài đặt tiếng Việt cho Odoo 19 và đặt làm ngôn ngữ mặc định
# Chạy: docker exec odoo bash /mnt/scripts/install_vi_VN.sh
#

CONTAINER="odoo"
CONF="/etc/odoo/odoo.conf"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ── Bước 1: Load tiếng Việt vào tất cả module đã cài ────
log "Đang cài đặt ngôn ngữ tiếng Việt (vi_VN)..."

odoo --config="$CONF" \
     --load-language=vi_VN \
     --stop-after-init \
     --no-http \
     2>&1 | tail -5

log "Đã load xong ngôn ngữ vi_VN."

# ── Bước 2: Đặt vi_VN làm ngôn ngữ mặc định, bỏ en_US ──
log "Đặt tiếng Việt làm ngôn ngữ mặc định cho toàn hệ thống..."

odoo shell --config="$CONF" --no-http --stop-after-init <<'PYEOF'
# 1. Kích hoạt tiếng Việt
vi = env['res.lang'].with_context(active_test=False).search([('code', '=', 'vi_VN')], limit=1)
if vi and not vi.active:
    vi.active = True
    print(f"[OK] Đã kích hoạt ngôn ngữ: {vi.name}")
elif vi:
    print(f"[OK] Ngôn ngữ đã hoạt động: {vi.name}")
else:
    print("[ERROR] Không tìm thấy vi_VN trong hệ thống!")
    exit()

# 2. Đặt vi_VN làm ngôn ngữ mặc định của company
companies = env['res.company'].search([])
for company in companies:
    print(f"  → Company: {company.name}")
    # Đặt partner lang
    if company.partner_id:
        company.partner_id.lang = 'vi_VN'

# 3. Đổi ngôn ngữ cho tất cả user hiện tại
users = env['res.users'].with_context(active_test=False).search([])
count = 0
for user in users:
    if user.lang != 'vi_VN':
        user.lang = 'vi_VN'
        count += 1
print(f"[OK] Đã đổi ngôn ngữ cho {count}/{len(users)} users sang vi_VN")

# 4. Đặt vi_VN làm ngôn ngữ mặc định cho user mới (qua ir.default)
field = env['ir.model.fields'].search([
    ('model', '=', 'res.partner'),
    ('name', '=', 'lang'),
], limit=1)
if field:
    existing = env['ir.default'].search([
        ('field_id', '=', field.id),
        ('company_id', '=', False),
        ('user_id', '=', False),
    ], limit=1)
    if existing:
        existing.json_value = '"vi_VN"'
    else:
        env['ir.default'].create({
            'field_id': field.id,
            'json_value': '"vi_VN"',
        })
    print("[OK] Đã đặt vi_VN làm ngôn ngữ mặc định cho partner mới")

# 5. Vô hiệu hóa en_US (tùy chọn - uncomment nếu muốn xóa hẳn)
en = env['res.lang'].with_context(active_test=False).search([('code', '=', 'en_US')], limit=1)
if en and en.active:
    en.active = False
    print("[OK] Đã vô hiệu hóa tiếng Anh (en_US)")

env.cr.commit()
print("\n=== HOÀN TẤT: Hệ thống đã chuyển sang tiếng Việt ===")
PYEOF

log "Xong! Khởi động lại container để áp dụng."
