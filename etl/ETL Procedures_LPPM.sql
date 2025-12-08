/*
===========================================================================
TAHAP 1: DESAIN FISIKAL DATABASE (DDL)
KELOMPOK 5 - LPPM ITERA
Deskripsi: Membuat Database, Tabel Dimensi, Tabel Fakta, dan Relasi.
===========================================================================
*/

USE master;
GO

-- 1. BERSIHKAN DATABASE LAMA (RESET)
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'DW_LPPM')
BEGIN
    ALTER DATABASE DW_LPPM SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_LPPM;
END
GO

-- 2. BUAT DATABASE BARU
CREATE DATABASE DW_LPPM;
GO
USE DW_LPPM;
GO
CREATE SCHEMA stg; -- Schema untuk Staging Area
GO

-- =======================================================
-- 3. CREATE DIMENSION TABLES
-- =======================================================

-- Dimensi Program Studi
CREATE TABLE Dim_Prodi (
    ProdiKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Kode_Prodi VARCHAR(10),
    Nama_Prodi VARCHAR(150),
    Jurusan VARCHAR(150),
    Fakultas VARCHAR(100)
);

-- Dimensi Pusat Riset
CREATE TABLE Dim_PusatRiset (
    PusatRisetKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Nama_Pusat_Riset VARCHAR(150),
    Nama_Kepala_Pusat VARCHAR(150)
);

-- Dimensi Skema Pendanaan
CREATE TABLE Dim_Skema (
    SkemaKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Nama_Skema VARCHAR(100),
    Jenis_Skema VARCHAR(50),
    Sumber_Dana VARCHAR(50)
);

-- Dimensi Lokasi (Abdimas)
CREATE TABLE Dim_Lokasi (
    LokasiKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Nama_Desa VARCHAR(100),
    Kecamatan VARCHAR(100),
    Kabupaten VARCHAR(100),
    Provinsi VARCHAR(100)
);

-- Dimensi Tanggal
CREATE TABLE Dim_Date (
    DateKey INT NOT NULL PRIMARY KEY, -- YYYYMMDD
    Tanggal DATE,
    Hari INT,
    Bulan INT,
    NamaBulan VARCHAR(20),
    Tahun INT,
    Kuartal INT,
    Semester VARCHAR(20)
);

-- Dimensi Publikasi
CREATE TABLE Dim_Publikasi (
    PublikasiKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Judul VARCHAR(500),
    Jurnal VARCHAR(200),
    Tahun_Terbit INT,
    Kuartil VARCHAR(10),
    Sinta_Rank VARCHAR(10)
);

-- Dimensi Peneliti (SCD Type 2)
CREATE TABLE Dim_Peneliti (
    PenelitiKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    NIDN VARCHAR(20),
    Nama_Peneliti VARCHAR(150),
    Jabatan_Fungsional VARCHAR(50),
    ProdiKey_Afiliasi INT,
    PusatRisetKey_Afiliasi INT,
    IsCurrent BIT DEFAULT 1,
    CONSTRAINT FK_DP_Prodi FOREIGN KEY (ProdiKey_Afiliasi) REFERENCES Dim_Prodi(ProdiKey),
    CONSTRAINT FK_DP_Pusat FOREIGN KEY (PusatRisetKey_Afiliasi) REFERENCES Dim_PusatRiset(PusatRisetKey)
);

-- Dimensi Mahasiswa
CREATE TABLE Dim_Mahasiswa (
    MahasiswaKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    NIM VARCHAR(20),
    Nama_Mahasiswa VARCHAR(150),
    ProdiKey INT,
    CONSTRAINT FK_DM_Prodi FOREIGN KEY (ProdiKey) REFERENCES Dim_Prodi(ProdiKey)
);

-- =======================================================
-- 4. CREATE FACT TABLES
-- =======================================================

-- Fact Proposal (50k Data)
CREATE TABLE Fact_Proposal (
    ProposalKey BIGINT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Id_Sumber INT,
    DateKey_Pengajuan INT,
    DateKey_Keputusan INT,
    PenelitiKey_Ketua INT,
    SkemaKey INT,
    PusatRisetKey_Afiliasi INT,
    Dana_Diajukan DECIMAL(18,2),
    Dana_Disetujui DECIMAL(18,2),
    Lama_Review_Hari INT,
    Status_Proposal VARCHAR(50),
    
    -- Constraints
    CONSTRAINT FK_FP_DateAjuan FOREIGN KEY (DateKey_Pengajuan) REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_FP_DatePutus FOREIGN KEY (DateKey_Keputusan) REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_FP_Ketua FOREIGN KEY (PenelitiKey_Ketua) REFERENCES Dim_Peneliti(PenelitiKey),
    CONSTRAINT FK_FP_Skema FOREIGN KEY (SkemaKey) REFERENCES Dim_Skema(SkemaKey),
    CONSTRAINT FK_FP_Pusat FOREIGN KEY (PusatRisetKey_Afiliasi) REFERENCES Dim_PusatRiset(PusatRisetKey)
);

-- Fact KKN
CREATE TABLE Fact_KKN (
    KKNKey BIGINT NOT NULL PRIMARY KEY IDENTITY(1,1),
    DateKey_Mulai INT,
    LokasiKey INT,
    MahasiswaKey INT,
    PenelitiKey_DPL INT,
    Jumlah_Mahasiswa INT,
    Periode_KKN VARCHAR(50),
    
    CONSTRAINT FK_FK_Date FOREIGN KEY (DateKey_Mulai) REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_FK_Lokasi FOREIGN KEY (LokasiKey) REFERENCES Dim_Lokasi(LokasiKey),
    CONSTRAINT FK_FK_Mhs FOREIGN KEY (MahasiswaKey) REFERENCES Dim_Mahasiswa(MahasiswaKey),
    CONSTRAINT FK_FK_DPL FOREIGN KEY (PenelitiKey_DPL) REFERENCES Dim_Peneliti(PenelitiKey)
);

-- Fact Authorship
CREATE TABLE Fact_Authorship (
    AuthorshipKey BIGINT NOT NULL PRIMARY KEY IDENTITY(1,1),
    PenelitiKey INT,
    PublikasiKey INT,
    DateKey_Terbit INT,
    Jumlah_Sitasi INT,
    
    CONSTRAINT FK_FA_Peneliti FOREIGN KEY (PenelitiKey) REFERENCES Dim_Peneliti(PenelitiKey),
    CONSTRAINT FK_FA_Publikasi FOREIGN KEY (PublikasiKey) REFERENCES Dim_Publikasi(PublikasiKey),
    CONSTRAINT FK_FA_Date FOREIGN KEY (DateKey_Terbit) REFERENCES Dim_Date(DateKey)
);

-- =======================================================
-- 5. STAGING TABLES (Syarat Modul)
-- =======================================================
CREATE TABLE stg.Proposal (Id INT, Judul VARCHAR(MAX), Tgl DATE);
CREATE TABLE stg.KKN (Id INT, Lokasi VARCHAR(100));
CREATE TABLE stg.Publikasi (Id INT, Judul VARCHAR(MAX));

GO

/*
===========================================================================
TAHAP 2: PROSES ETL & DATA GENERATION (50.000 DATA)
KELOMPOK 5 - LPPM ITERA
Deskripsi: Mengisi data dimensi dan fakta dengan logika yang sudah diperbaiki.
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

-- =======================================================
-- 3. POPULATE FACTS (LOGIKA YANG SUDAH DIPERBAIKI)
-- =======================================================

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

GO

USE DW_LPPM;
GO

-- =============================================
-- RE-CREATE VIEWS FOR POWER BI
-- (Wajib dijalankan setelah Reset Database)
-- =============================================

-- 1. VIEW EXECUTIVE (KPI & Tren)
CREATE OR ALTER VIEW vw_Proposal_Analytics AS
SELECT 
    d.Tahun,
    d.Kuartal,
    d.Semester,
    pr.Nama_Pusat_Riset,
    s.Nama_Skema,
    s.Jenis_Skema,
    s.Sumber_Dana,
    COUNT(fp.ProposalKey) AS Total_Proposal,
    SUM(fp.Dana_Diajukan) AS Total_Dana_Diajukan,
    SUM(fp.Dana_Disetujui) AS Total_Dana_Disetujui,
    AVG(fp.Lama_Review_Hari) AS Rata_Rata_Review_Hari,
    SUM(CASE WHEN fp.Status_Proposal = 'Diterima' THEN 1 ELSE 0 END) AS Proposal_Diterima
FROM Fact_Proposal fp
JOIN Dim_Date d ON fp.DateKey_Pengajuan = d.DateKey
JOIN Dim_PusatRiset pr ON fp.PusatRisetKey_Afiliasi = pr.PusatRisetKey
JOIN Dim_Skema s ON fp.SkemaKey = s.SkemaKey
GROUP BY d.Tahun, d.Kuartal, d.Semester, pr.Nama_Pusat_Riset, s.Nama_Skema, s.Jenis_Skema, s.Sumber_Dana;
GO

-- 2. VIEW PENELITI (Produktivitas Dosen)
CREATE OR ALTER VIEW vw_Peneliti_Performance AS
SELECT 
    p.NIDN,
    p.Nama_Peneliti,
    p.Jabatan_Fungsional,
    prod.Nama_Prodi,
    prod.Fakultas,
    COUNT(DISTINCT fp.ProposalKey) AS Jml_Proposal,
    SUM(fp.Dana_Disetujui) AS Total_Dana,
    COUNT(DISTINCT fa.PublikasiKey) AS Jml_Publikasi,
    SUM(fa.Jumlah_Sitasi) AS Total_Sitasi
FROM Dim_Peneliti p
JOIN Dim_Prodi prod ON p.ProdiKey_Afiliasi = prod.ProdiKey
LEFT JOIN Fact_Proposal fp ON p.PenelitiKey = fp.PenelitiKey_Ketua
LEFT JOIN Fact_Authorship fa ON p.PenelitiKey = fa.PenelitiKey
WHERE p.IsCurrent = 1
GROUP BY p.NIDN, p.Nama_Peneliti, p.Jabatan_Fungsional, prod.Nama_Prodi, prod.Fakultas;
GO

-- 3. VIEW PETA (GIS Sebaran KKN)
CREATE OR ALTER VIEW vw_Abdimas_Map AS
SELECT 
    l.Provinsi,
    l.Kabupaten,
    l.Kecamatan,
    l.Nama_Desa,
    d.Tahun,
    fk.Periode_KKN,
    COUNT(fk.MahasiswaKey) AS Jml_Mahasiswa,
    COUNT(DISTINCT fk.PenelitiKey_DPL) AS Jml_Dosen
FROM Fact_KKN fk
JOIN Dim_Lokasi l ON fk.LokasiKey = l.LokasiKey
JOIN Dim_Date d ON fk.DateKey_Mulai = d.DateKey
GROUP BY l.Provinsi, l.Kabupaten, l.Kecamatan, l.Nama_Desa, d.Tahun, fk.Periode_KKN;
GO

USE DW_LPPM;
GO

-- REVISI VIEW: MENAMBAHKAN KOLOM 'BULAN' (ANGKA) UNTUK SORTING
CREATE OR ALTER VIEW vw_Proposal_Analytics AS
SELECT 
    d.Tahun,
    d.Kuartal,
    d.Bulan,      -- <--- INI KITA TAMBAHKAN (Angka 1-12)
    d.NamaBulan,  -- (Januari, Februari...)
    pr.Nama_Pusat_Riset,
    s.Nama_Skema,
    s.Jenis_Skema,
    COUNT(fp.ProposalKey) AS Total_Proposal,
    SUM(fp.Dana_Disetujui) AS Total_Dana_Setuju,
    AVG(fp.Lama_Review_Hari) AS Avg_Review_Days
FROM Fact_Proposal fp
JOIN Dim_Date d ON fp.DateKey_Pengajuan = d.DateKey
JOIN Dim_PusatRiset pr ON fp.PusatRisetKey_Afiliasi = pr.PusatRisetKey
JOIN Dim_Skema s ON fp.SkemaKey = s.SkemaKey
GROUP BY d.Tahun, d.Kuartal, d.Bulan, d.NamaBulan, pr.Nama_Pusat_Riset, s.Nama_Skema, s.Jenis_Skema;
GO