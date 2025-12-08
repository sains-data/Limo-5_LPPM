/*
===========================================================================
FILE: 08_Data_Quality_Checks.sql
DESKRIPSI: Script Validasi Kualitas Data (QA)
TUJUAN: Memastikan data bersih, konsisten, dan valid secara logika bisnis.
===========================================================================
*/

USE DW_LPPM;
GO

PRINT '>>> MULAI PENGECEKAN KUALITAS DATA (QA CHECKS) <<<';

-- 1. CEK KELENGKAPAN (COMPLETENESS)
-- Memastikan tidak ada Foreign Key yang NULL di Tabel Fakta Utama
SELECT 
    'Fact_Proposal' AS TableName,
    'Check Null Foreign Keys' AS Test_Name,
    COUNT(*) AS Failed_Rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM Fact_Proposal
WHERE DateKey_Pengajuan IS NULL 
   OR PenelitiKey_Ketua IS NULL 
   OR SkemaKey IS NULL;

-- 2. CEK LOGIKA BISNIS (CONSISTENCY)
-- Dana Disetujui TIDAK BOLEH lebih besar dari Dana Diajukan
SELECT 
    'Fact_Proposal' AS TableName,
    'Check Dana Logic (Setuju <= Ajuan)' AS Test_Name,
    COUNT(*) AS Failed_Rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM Fact_Proposal
WHERE Dana_Disetujui > Dana_Diajukan;

-- 3. CEK INTEGRITAS REFERENSI (ORPHAN CHECK)
-- Memastikan Peneliti di Tabel Fakta benar-benar ada di Tabel Dimensi
SELECT 
    'Fact_Proposal' AS TableName,
    'Check Orphan Peneliti' AS Test_Name,
    COUNT(*) AS Orphan_Count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM Fact_Proposal f
LEFT JOIN Dim_Peneliti d ON f.PenelitiKey_Ketua = d.PenelitiKey
WHERE d.PenelitiKey IS NULL;

-- 4. CEK VOLUME DATA (DATA VOLUME)
-- Memastikan jumlah data memenuhi target (50.000++)
SELECT 
    'Fact_Proposal' AS TableName,
    'Check Minimum Volume (50k)' AS Test_Name,
    COUNT(*) AS Total_Rows,
    CASE WHEN COUNT(*) >= 50000 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM Fact_Proposal;

-- 5. CEK DATA BARU (SYSTEM LOGS)
-- Memastikan data simulasi log sistem juga masuk
SELECT 
    'Fact_Dataset_Statistik' AS TableName,
    'Check System Logs Exist' AS Test_Name,
    COUNT(*) AS Total_Rows,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM Fact_Dataset_Statistik;

PRINT '>>> PENGECEKAN SELESAI <<<';
GO
