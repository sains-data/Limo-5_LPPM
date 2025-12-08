/*
===========================================================================
FILE: 09_Test_Queries.sql
DESKRIPSI: Performance Testing & Analytical Queries
TUJUAN: Mengukur kecepatan respon database terhadap query analisis kompleks.
===========================================================================
*/

USE DW_LPPM;
GO

-- Aktifkan pencatatan waktu eksekusi
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

PRINT '=============================================================';
PRINT 'TEST 1: ANALISIS TOTAL DANA PER PUSAT RISET (AGREGASI)';
PRINT '=============================================================';

SELECT 
    pr.Nama_Pusat_Riset,
    COUNT(fp.ProposalKey) AS Jumlah_Proposal,
    FORMAT(SUM(fp.Dana_Diajukan), 'C', 'id-ID') AS Total_Dana_Ajuan,
    FORMAT(SUM(fp.Dana_Disetujui), 'C', 'id-ID') AS Total_Dana_Setuju,
    AVG(fp.Lama_Review_Hari) AS Avg_Review_Days
FROM Fact_Proposal fp
JOIN Dim_PusatRiset pr ON fp.PusatRisetKey_Afiliasi = pr.PusatRisetKey
GROUP BY pr.Nama_Pusat_Riset
ORDER BY SUM(fp.Dana_Disetujui) DESC;


PRINT '=============================================================';
PRINT 'TEST 2: TREN PROPOSAL PER TAHUN & SEMESTER (TIME SERIES)';
PRINT '=============================================================';

SELECT 
    d.Tahun,
    d.Semester,
    s.Jenis_Skema,
    COUNT(fp.ProposalKey) AS Total_Proposal,
    SUM(CASE WHEN fp.Status_Proposal = 'Diterima' THEN 1 ELSE 0 END) AS Accepted
FROM Fact_Proposal fp
JOIN Dim_Date d ON fp.DateKey_Pengajuan = d.DateKey
JOIN Dim_Skema s ON fp.SkemaKey = s.SkemaKey
GROUP BY d.Tahun, d.Semester, s.Jenis_Skema
ORDER BY d.Tahun, d.Semester;


PRINT '=============================================================';
PRINT 'TEST 3: ANALISIS KATA KUNCI PENCARIAN (VISUALISASI BARU)';
PRINT '=============================================================';

SELECT TOP 10
    k.Kata_Kunci,
    SUM(fpl.Total_Pencarian) AS Hits,
    AVG(fpl.Waktu_Respon_Ms) AS Avg_Latency_Ms
FROM Fact_Pencarian_Log fpl
JOIN Dim_KataKunci k ON fpl.KataKunciKey = k.KataKunciKey
GROUP BY k.Kata_Kunci
ORDER BY Hits DESC;

-- Matikan statistik
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO
