-- =================================================================
-- MiTaBus – Khởi tạo PostgreSQL
-- Chạy một lần khi tạo cơ sở dữ liệu mới
-- =================================================================

-- Tiện ích mở rộng (extensions)
CREATE EXTENSION IF NOT EXISTS pg_trgm;       -- Tìm kiếm gần đúng
CREATE EXTENSION IF NOT EXISTS unaccent;      -- Bỏ dấu khi tìm kiếm
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- Mã hóa / UUID
CREATE EXTENSION IF NOT EXISTS vector;        -- Tìm kiếm vector (AI)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements; -- Giám sát truy vấn

-- Tối ưu hóa cho Odoo
ALTER SYSTEM SET idle_in_transaction_session_timeout = '600s';
ALTER SYSTEM SET statement_timeout = '600s';

SELECT pg_reload_conf();
