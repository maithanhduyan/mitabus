#!/bin/bash
set -euo pipefail
#
# Odoo 19 Backup Script
# Tạo backup (database + filestore) dưới dạng zip, tự động xoá bản cũ.
#
# Cách dùng:
#   ./docker_bk_script.sh            # backup bình thường
#   ./docker_bk_script.sh --label pre-migration  # thêm nhãn vào tên file
#
# Cron (mỗi Chủ nhật 2h sáng):
#   0 2 * * 0 /home/odoo-19/backup/docker_bk_script.sh >> /home/odoo-19/backup/data/backup.log 2>&1

# ── Cấu hình ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/data"
KEEP=10                          # Giữ lại N bản backup gần nhất

# Đọc từ backup.conf
CONF="${SCRIPT_DIR}/backup.conf"
if [[ ! -f "$CONF" ]]; then
    echo "[ERROR] Không tìm thấy ${CONF}"
    exit 1
fi

CONTAINER=$(awk -F= '/^\s*container\s*=/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$CONF")
ODOO_CONF=$(awk -F= '/^\s*odoo_conf\s*=/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$CONF")
DB_NAME=$(awk -F= '/^\s*db\s*=/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$CONF")
DB_USER=$(awk -F= '/^\s*user\s*=/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$CONF")
DB_PASS=$(awk -F= '/^\s*password\s*=/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$CONF")
DB_HOST=$(awk -F= '/^\s*db_host\s*=/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$CONF")
DB_PORT=$(awk -F= '/^\s*db_port\s*=/{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$CONF")
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"

# ── Tên file ──────────────────────────────────────────────
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LABEL="${1:+_${1#--label=}}"; LABEL="${LABEL#_--label }"
[[ "${1:-}" == --label ]] && LABEL="_${2:-}" || { [[ "${1:-}" == --label=* ]] && LABEL="_${1#--label=}"; }
[[ -z "${1:-}" ]] && LABEL=""
FILENAME="${DB_NAME}_${TIMESTAMP}${LABEL}.zip"
CONTAINER_TMP="/tmp/${FILENAME}"

mkdir -p "$BACKUP_DIR"

# ── Hàm log ──────────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ── Hàm cleanup khi lỗi ──────────────────────────────────
cleanup() {
    docker exec "$CONTAINER" rm -f "$CONTAINER_TMP" 2>/dev/null || true
    rm -f "${BACKUP_DIR}/${FILENAME}" 2>/dev/null || true
}
trap cleanup ERR

# ── Kiểm tra container đang chạy ─────────────────────────
if ! docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
    log "ERROR: Container '$CONTAINER' không chạy."
    exit 1
fi

# ── Bước 1: Tạo backup trong container ───────────────────
log "Bắt đầu backup '${DB_NAME}' từ container '${CONTAINER}'..."

docker exec "$CONTAINER" python3 -c "
import odoo
from odoo.tools import config
config.parse_config([
    '-c', '${ODOO_CONF}',
    '--db_host=${DB_HOST}', '--db_port=${DB_PORT}',
    '--db_user=${DB_USER}', '--db_password=${DB_PASS}'
])
config['list_db'] = True
import odoo.service.db as db
with open('${CONTAINER_TMP}', 'wb') as f:
    db.dump_db('${DB_NAME}', f, 'zip')
print('DUMP_OK')
"

log "Dump hoàn tất bên trong container."

# ── Bước 2: Copy ra host ─────────────────────────────────
docker cp "${CONTAINER}:${CONTAINER_TMP}" "${BACKUP_DIR}/${FILENAME}"
log "Đã copy ra ${BACKUP_DIR}/${FILENAME}"

# ── Bước 3: Xoá file tạm trong container ─────────────────
docker exec "$CONTAINER" rm -f "$CONTAINER_TMP"

# ── Bước 4: Kiểm tra file backup ─────────────────────────
SIZE=$(stat -c%s "${BACKUP_DIR}/${FILENAME}" 2>/dev/null || echo 0)
SIZE_MB=$(awk "BEGIN{printf \"%.1f\", ${SIZE}/1048576}")

if [[ "$SIZE" -lt 1048576 ]]; then
    log "ERROR: File backup quá nhỏ (${SIZE_MB} MB), có thể bị lỗi!"
    exit 1
fi

# Kiểm tra zip hợp lệ
if ! unzip -tq "${BACKUP_DIR}/${FILENAME}" > /dev/null 2>&1; then
    log "ERROR: File zip không hợp lệ!"
    exit 1
fi

log "OK: ${FILENAME} (${SIZE_MB} MB)"

# ── Bước 5: Xoá bản cũ, giữ lại ${KEEP} bản mới nhất ───
COUNT=$(ls -1t "${BACKUP_DIR}"/${DB_NAME}_*.zip 2>/dev/null | wc -l)
if [[ "$COUNT" -gt "$KEEP" ]]; then
    DELETED=$(ls -1t "${BACKUP_DIR}"/${DB_NAME}_*.zip | tail -n +"$((KEEP + 1))")
    echo "$DELETED" | xargs rm -f
    log "Đã xoá $((COUNT - KEEP)) bản backup cũ, giữ lại ${KEEP} bản."
fi

# ── Tổng kết ──────────────────────────────────────────────
log "Danh sách backup hiện tại:"
ls -lht "${BACKUP_DIR}"/${DB_NAME}_*.zip 2>/dev/null | head -"$KEEP"
