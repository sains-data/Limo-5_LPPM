/*
===========================================================================
FILE: 03_Master_ETL_Procedure.sql
DESKRIPSI: Stored Procedure Utama untuk Generate & Load Data
DATABASE: DW_LPPM
===========================================================================
*/

USE DW_LPPM;
GO
SET NOCOUNT ON;

-- =======================================================
-- 1. POPULATE STATIC DIMENSIONS (Data Asli)
-- =======================================================

-- Prodi Lengkap ITERA
INSERT INTO Dim_Prodi VALUES 
('SD','Sains Data','Sains','Fakultas Sains'),
('SA','Sains Aktuaria','Sains','Fakultas Sains'),
('MA','Matematika','Sains','Fakultas Sains'),
('IF','Teknik Informatika','TPI','FTI'),
('TI','Teknik Industri','TPI','FTI'),
('TA','Teknik Pertambangan','TPI','FTI'),
('PWK','Perencanaan Wilayah','TIK','FTIK'),
('AR','Arsitektur','TIK','FTIK'),
('SI','Teknik Sipil','TIK','FTIK'),
('TL','Teknik Lingkungan','TIK','FTIK');

-- Pusat Riset LPPM
INSERT INTO Dim_PusatRiset VALUES 
('Pusat Mitigasi Gempa dan Tsunami','Prof. Harkunti'),
('Pusat Observatorium Astronomi (OAIL)','Dr. Meezan'),
('Pusat Riset Material dan Energi','Harry Yuliansyah'),
('Pusat Riset Hayati Berkelanjutan','Dr. Winati'),
('Pusat Keamanan Digital','Prof. Sarwono'),
('Pusat Studi Pembangunan (SDGs)','Rinda Gusvita'),
('Pusat Infrastruktur Berkelanjutan','Prof. Ibnu Syabri'),
('Pusat Integrated Waste (IWACI)','Ir. Rifqi Sufra'),
('Pusat Penelitian Publikasi','Dr. Aditya'),
('Pusat Pengabdian KKN','Dr. Idra Herlina');

-- Skema & Lokasi
INSERT INTO Dim_Skema VALUES 
('Hibah Dasar','Penelitian','Internal'),
('Hibah Terapan','Penelitian','Ristekdikti'),
('Hibah Pascasarjana','Penelitian','Eksternal'),
('Abdimas Desa','Abdimas','Internal'),
('KKN Tematik','Abdimas','Mandiri');

INSERT INTO Dim_Lokasi VALUES 
('Desa Sabah Balau','Tanjung Bintang','Lampung Selatan','Lampung'),
('Way Huwi','Jati Agung','Lampung Selatan','Lampung'),
('Kotabumi','Kotabumi','Lampung Utara','Lampung'),
('Metro Pusat','Metro','Kota Metro','Lampung'),
('Kalianda','Kalianda','Lampung Selatan','Lampung');

-- =======================================================
-- 2. POPULATE DYNAMIC DIMENSIONS
-- =======================================================

-- A. Dimensi Tanggal (RENTANG AMAN: 2022 - 2030)
DECLARE @StartDate DATE = '2022-01-01';
DECLARE @EndDate DATE = '2030-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO Dim_Date VALUES (
        CAST(CONVERT(VARCHAR(8), @StartDate, 112) AS INT),
        @StartDate, DAY(@StartDate), MONTH(@StartDate), DATENAME(MONTH, @StartDate), 
        YEAR(@StartDate), DATEPART(QUARTER, @StartDate),
        CASE WHEN MONTH(@StartDate) <= 6 THEN 'Genap' ELSE 'Ganjil' END
    );
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END
PRINT '-> Kalender (2022-2030) Siap.';

-- B. Dosen (250 Data) & Mahasiswa (1000 Data)
DECLARE @i INT = 1;
WHILE @i <= 250 
BEGIN 
    INSERT INTO Dim_Peneliti VALUES 
    (CONCAT('00',100+@i), CONCAT('Dosen ',@i), 'Lektor', (ABS(CHECKSUM(NEWID()))%10)+1, (ABS(CHECKSUM(NEWID()))%10)+1, 1); 
    SET @i=@i+1; 
END

SET @i = 1;
WHILE @i <= 1000 
BEGIN 
    INSERT INTO Dim_Mahasiswa VALUES 
    (CONCAT('121',@i), CONCAT('Mhs ',@i), (ABS(CHECKSUM(NEWID()))%10)+1); 
    SET @i=@i+1; 
END
PRINT '-> Dosen & Mahasiswa Siap.';

-- C. Publikasi (10.000 Data)
SET @i = 1;
WHILE @i <= 10000 
BEGIN 
    INSERT INTO Dim_Publikasi VALUES 
    (CONCAT('Artikel Ilmiah Topik-',@i), 'IEEE Access', 2023, 'Q1', 'S1'); 
    SET @i=@i+1; 
END
PRINT '-> Data Publikasi Siap.';

-- =======================================================
-- 3. POPULATE FACTS (LOGIKA YANG SUDAH DIPERBAIKI)
-- =======================================================

PRINT 'Sedang Generate 50.000 Fakta Proposal...';

DECLARE @x INT = 1;
DECLARE @RandDateKey INT;
DECLARE @RandDateObj DATE;
DECLARE @NewDateObj DATE;
DECLARE @NewDateKey INT;

WHILE @x <= 50000
BEGIN
    -- 1. Ambil DateKey Acak (2022-2025)
    SELECT TOP 1 @RandDateKey = DateKey FROM Dim_Date WHERE Tahun BETWEEN 2022 AND 2025 ORDER BY NEWID();
    
    -- 2. KONVERSI TANGGAL YANG BENAR (FIX ERROR SEBELUMNYA)
    -- Ubah Key (INT) -> Date (DATE) -> Tambah Hari -> Balikin ke Key (INT)
    SET @RandDateObj = CAST(CAST(@RandDateKey AS CHAR(8)) AS DATE);
    SET @NewDateObj = DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % 90), @RandDateObj); -- Putusan +0-90 hari
    SET @NewDateKey = CAST(CONVERT(VARCHAR(8), @NewDateObj, 112) AS INT);

    -- 3. Insert ke Fakta
    INSERT INTO Fact_Proposal VALUES (
        100000+@x, 
        @RandDateKey, -- Tgl Ajuan
        @NewDateKey,  -- Tgl Putusan (AMAN)
        (ABS(CHECKSUM(NEWID()))%250)+1, -- Dosen
        (ABS(CHECKSUM(NEWID()))%5)+1,   -- Skema
        (ABS(CHECKSUM(NEWID()))%10)+1,  -- Pusat Riset
        (ABS(CHECKSUM(NEWID()))%100 + 10) * 1000000, -- Dana Ajuan
        (ABS(CHECKSUM(NEWID()))%100) * 1000000,      -- Dana Setuju
        DATEDIFF(DAY, @RandDateObj, @NewDateObj),    -- Lama Review
        CASE WHEN (ABS(CHECKSUM(NEWID()))%10) < 5 THEN 'Diterima' ELSE 'Ditolak' END
    );
    SET @x = @x + 1;
END
PRINT '-> Fact Proposal 50K: OK (No Error)';

-- Isi Fact KKN (5000 Data)
SET @x = 1;
WHILE @x <= 5000 
BEGIN 
    INSERT INTO Fact_KKN VALUES 
    (20240601, (ABS(CHECKSUM(NEWID()))%5)+1, (ABS(CHECKSUM(NEWID()))%1000)+1, (ABS(CHECKSUM(NEWID()))%250)+1, 1, 'KKN 2024'); 
    SET @x=@x+1; 
END

-- Isi Fact Authorship (10.000 Data)
SET @x = 1;
WHILE @x <= 10000 
BEGIN 
    INSERT INTO Fact_Authorship VALUES 
    ((ABS(CHECKSUM(NEWID()))%250)+1, @x, 20240101, (ABS(CHECKSUM(NEWID()))%50)); 
    SET @x=@x+1; 
END

PRINT '>>> TAHAP 2 SELESAI: SEMUA DATA BERHASIL DIISI! <<<';
GO
