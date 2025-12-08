/* =========================================================================
   File: 10_Create_Analytical_Views.sql
   Deskripsi: Membuat SQL Views untuk Dashboard Power BI
   Database Target: DW_LPPM (Kelompok 5)
   ========================================================================= */

USE DW_LPPM;
GO

-- =======================================================
-- VIEW 1: EXECUTIVE GOVERNANCE DASHBOARD
-- Tujuan: Memantau kinerja makro LPPM (Proposal, Dana, Durasi Review)
-- Target User: Kepala LPPM, Rektorat
-- =======================================================
CREATE OR ALTER VIEW dbo.vw_Executive_Governance AS
SELECT 
    d.Tahun,
    d.Kuartal,
    d.NamaBulan,
    d.Bulan, -- Untuk sorting
    pr.Nama_Pusat_Riset,
    s.Nama_Skema,
    s.Jenis_Skema,
    
    -- Metrik Utama
    COUNT(fp.ProposalKey) AS Total_Proposal_Masuk,
    SUM(fp.Dana_Diajukan) AS Total_Dana_Ajuan,
    SUM(fp.Dana_Disetujui) AS Total_Dana_Disetujui,
    AVG(fp.Lama_Review_Hari) AS Rata_Rata_Durasi_Review,
    
    -- Status Kualitas (Indikator Kinerja)
    CASE 
        WHEN AVG(fp.Lama_Review_Hari) <= 14 THEN 'Excellent (<2 Weeks)'
        WHEN AVG(fp.Lama_Review_Hari) <= 30 THEN 'Good (<1 Month)'
        ELSE 'Needs Improvement (>1 Month)'
    END AS Status_Efisiensi,
    
    -- Ranking Pusat Riset berdasarkan Dana
    RANK() OVER (PARTITION BY d.Tahun ORDER BY SUM(fp.Dana_Disetujui) DESC) AS Ranking_Dana
    
FROM dbo.Fact_Proposal fp
JOIN dbo.Dim_Date d ON fp.DateKey_Pengajuan = d.DateKey
JOIN dbo.Dim_PusatRiset pr ON fp.PusatRisetKey_Afiliasi = pr.PusatRisetKey
JOIN dbo.Dim_Skema s ON fp.SkemaKey = s.SkemaKey
GROUP BY d.Tahun, d.Kuartal, d.NamaBulan, d.Bulan, pr.Nama_Pusat_Riset, s.Nama_Skema, s.Jenis_Skema;
GO


-- =======================================================
-- VIEW 2: RESEARCHER PRODUCTIVITY & OUTPUT
-- Tujuan: Melihat siapa dosen paling produktif dan unit mana yang aktif
-- Target User: Dekan, Kaprodi
-- =======================================================
CREATE OR ALTER VIEW dbo.vw_Researcher_Productivity AS
SELECT 
    p.Nama_Peneliti,
    p.NIDN,
    p.Jabatan_Fungsional,
    prod.Nama_Prodi,
    prod.Fakultas,
    d.Tahun,
    
    -- Metrik Produktivitas
    COUNT(DISTINCT fp.ProposalKey) AS Jml_Proposal,
    SUM(CASE WHEN fp.Status_Proposal = 'Diterima' THEN 1 ELSE 0 END) AS Jml_Grant_Lolos,
    ISNULL(SUM(fp.Dana_Disetujui), 0) AS Total_Dana_Dikelola,
    
    -- Metrik Publikasi (dari tabel Fact_Authorship)
    COUNT(DISTINCT fa.PublikasiKey) AS Jml_Publikasi,
    ISNULL(SUM(fa.Jumlah_Sitasi), 0) AS Total_Sitasi,
    
    -- Segmentasi Dosen
    CASE 
        WHEN COUNT(DISTINCT fa.PublikasiKey) >= 5 THEN 'Star Researcher'
        WHEN COUNT(DISTINCT fa.PublikasiKey) >= 2 THEN 'Active Researcher'
        ELSE 'Junior Researcher'
    END AS Researcher_Segment,
    
    -- Ranking Dosen dalam Fakultas
    RANK() OVER (PARTITION BY prod.Fakultas, d.Tahun ORDER BY SUM(fp.Dana_Disetujui) DESC) AS Ranking_In_Faculty
    
FROM dbo.Dim_Peneliti p
JOIN dbo.Dim_Prodi prod ON p.ProdiKey_Afiliasi = prod.ProdiKey
LEFT JOIN dbo.Fact_Proposal fp ON p.PenelitiKey = fp.PenelitiKey_Ketua
LEFT JOIN dbo.Dim_Date d ON fp.DateKey_Pengajuan = d.DateKey
LEFT JOIN dbo.Fact_Authorship fa ON p.PenelitiKey = fa.PenelitiKey
WHERE p.IsCurrent = 1
GROUP BY p.Nama_Peneliti, p.NIDN, p.Jabatan_Fungsional, prod.Nama_Prodi, prod.Fakultas, d.Tahun;
GO


-- =======================================================
-- VIEW 3: GEOGRAPHIC ANALYSIS (SEBARAN KKN)
-- Tujuan: Analisis lokasi pengabdian masyarakat (Peta GIS)
-- Target User: LPPM, Pemda
-- =======================================================
CREATE OR ALTER VIEW dbo.vw_Abdimas_Map AS
SELECT 
    l.Provinsi,
    l.Kabupaten,
    l.Kecamatan,
    l.Nama_Desa,
    d.Tahun,
    fk.Periode_KKN,
    
    -- Metrik Sebaran
    COUNT(fk.MahasiswaKey) AS Jml_Mahasiswa,
    COUNT(DISTINCT fk.PenelitiKey_DPL) AS Jml_Dosen_Pembimbing,
    
    -- Indikator Kepadatan (Misal: >50 Mhs = High Density)
    CASE 
        WHEN COUNT(fk.MahasiswaKey) > 50 THEN 'High Density'
        WHEN COUNT(fk.MahasiswaKey) > 20 THEN 'Medium Density'
        ELSE 'Low Density'
    END AS Density_Level

FROM dbo.Fact_KKN fk
JOIN dbo.Dim_Lokasi l ON fk.LokasiKey = l.LokasiKey
JOIN dbo.Dim_Date d ON fk.DateKey_Mulai = d.DateKey
GROUP BY l.Provinsi, l.Kabupaten, l.Kecamatan, l.Nama_Desa, d.Tahun, fk.Periode_KKN;
GO


-- =======================================================
-- VIEW 4: SYSTEM USAGE & SEARCH ANALYTICS
-- Tujuan: Analisis dataset/kata kunci
-- Target User: Admin Sistem Data
-- =======================================================
CREATE OR ALTER VIEW dbo.vw_System_Usage_Analytics AS
SELECT 
    -- Dimensi Dataset
    ds.Nama_Dataset,
    ds.Kategori_Nama,
    ds.Format,
    
    -- Dimensi Waktu
    d.NamaBulan,
    d.Bulan,
    d.Tahun,
    
    -- Metrik Unduhan & Views
    SUM(fds.Total_Downloads) AS Total_Downloads,
    SUM(fds.Total_Views) AS Total_Views,
    
    -- Konversi Rate (View to Download)
    CASE 
        WHEN SUM(fds.Total_Views) > 0 
        THEN (CAST(SUM(fds.Total_Downloads) AS FLOAT) / SUM(fds.Total_Views)) * 100 
        ELSE 0 
    END AS Conversion_Rate
    
FROM dbo.Fact_Dataset_Statistik fds
JOIN dbo.Dim_Dataset ds ON fds.DatasetKey = ds.DatasetKey
JOIN dbo.Dim_Date d ON fds.DateKey_Log = d.DateKey
GROUP BY ds.Nama_Dataset, ds.Kategori_Nama, ds.Format, d.NamaBulan, d.Bulan, d.Tahun;
GO

-- View Khusus Pencarian (untuk Treemap Kata Kunci)
CREATE OR ALTER VIEW dbo.vw_Search_Keywords AS
SELECT 
    k.Kata_Kunci,
    k.Kategori_Pencarian,
    SUM(fpl.Total_Pencarian) AS Total_Hits,
    SUM(fpl.Total_Pencarian_Nihil) AS Total_Not_Found,
    AVG(fpl.Waktu_Respon_Ms) AS Avg_Response_Time
FROM dbo.Fact_Pencarian_Log fpl
JOIN dbo.Dim_KataKunci k ON fpl.KataKunciKey = k.KataKunciKey
GROUP BY k.Kata_Kunci, k.Kategori_Pencarian;
GO

PRINT '>>> SEMUA ANALYTICAL VIEWS BERHASIL DIBUAT <<<';