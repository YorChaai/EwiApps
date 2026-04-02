-- Migration: Add revenue_type column to revenues table
-- Date: 2026-04-02
-- Description: Add revenue_type to distinguish between PENDAPATAN LANGSUNG and PENDAPATAN LAIN LAIN

-- Step 1: Add the column with default value
ALTER TABLE revenues
ADD COLUMN revenue_type VARCHAR(32) NOT NULL DEFAULT 'pendapatan_langsung';

-- Step 2: Create index for better query performance
CREATE INDEX IF NOT EXISTS ix_revenues_revenue_type ON revenues(revenue_type);

-- Step 3: Verify the migration
-- SELECT COUNT(*) as total, revenue_type FROM revenues GROUP BY revenue_type;

-- Note: All existing records will have 'pendapatan_langsung' as default
-- This maintains backward compatibility with existing data
