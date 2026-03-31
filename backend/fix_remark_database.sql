-- ============================================================
-- FIX: Clear "inc.PPN11%" from revenues.remark column
-- ============================================================
-- This script removes template example text from remark column
-- so it doesn't appear in generated Excel reports.
--
-- Run this ONCE to clean up existing data.
-- Future reports will have empty remark columns (for manual fill).
-- ============================================================

-- Step 1: Check current data with "inc.PPN11%" in remark
SELECT id, invoice_number, remark
FROM revenues
WHERE remark LIKE '%inc.PPN11%'
   OR remark LIKE '%inc. PPN11%'
   OR remark LIKE '%Pemungut%';

-- Step 2: Clear remark for all revenues with "inc.PPN11%"
UPDATE revenues
SET remark = ''
WHERE remark LIKE '%inc.PPN11%'
   OR remark LIKE '%inc. PPN11%'
   OR remark LIKE '%Pemungut%';

-- Step 3: Verify the update
SELECT id, invoice_number, remark
FROM revenues
WHERE remark = ''
LIMIT 10;

-- Step 4: Count affected rows
SELECT
    COUNT(*) as total_cleared
FROM revenues
WHERE remark = '';

-- ============================================================
-- DONE! Restart your application after running this script.
-- ============================================================
