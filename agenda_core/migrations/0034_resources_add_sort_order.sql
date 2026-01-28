-- Migration: Add sort_order column to resources table
-- Date: 2026-01-28

ALTER TABLE resources ADD COLUMN sort_order INT UNSIGNED NOT NULL DEFAULT 0 AFTER is_active;
