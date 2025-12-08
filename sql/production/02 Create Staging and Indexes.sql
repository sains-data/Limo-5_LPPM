/*
===========================================================================
FILE: 02_Create_Staging_and_Indexes.sql
DESKRIPSI: Membuat Tabel Staging dan Index untuk Optimasi Performa
DATABASE TARGET: DW_LPPM
===========================================================================
*/

USE DW_LPPM;
GO

-- =======================================================
-- 1. CREATE STAGING TABLES (Checklist Misi 2: Staging tables dibuat)
-- Deskripsi: Tabel polosan tanpa FK untuk menampung data mentah (ETL Load)
-- =======================================================

-- Staging Proposal
IF OBJECT_ID('stg.Proposal', 'U') IS NOT NULL DROP TABLE stg.Proposal;
CREATE TABLE stg.Proposal (
    Id_Proposal INT,
    Judul_Proposal VARCHAR(MAX),
    Tgl_Pengajuan DATE,
    NIDN_Ketua VARCHAR(50),
    Nama_Skema VARCHAR(100),
    Nama_PusatRiset VARCHAR(150),
    Dana_Ajuan DECIMAL(18,2),
    Status_Proposal VARCHAR(50),
    LoadDate DATETIME DEFAULT GETDATE()
);

-- Staging KKN
IF OBJECT_ID('stg.KKN', 'U') IS NOT NULL DROP TABLE stg.KKN;
CREATE TABLE stg.KKN (
    Id_KKN INT,
    NIM_Mahasiswa VARCHAR(20),
    NIDN_DPL VARCHAR(50),
    Lokasi_Desa VARCHAR(100),
    Lokasi_Kabupaten VARCHAR(100),
    Tgl_Mulai DATE,
    LoadDate DATETIME DEFAULT GETDATE()
);

-- Staging Publikasi
IF OBJECT_ID('stg.Publikasi', 'U') IS NOT NULL DROP TABLE stg.Publikasi;
CREATE TABLE stg.Publikasi (
    Id_Publikasi INT,
    Judul_Artikel VARCHAR(MAX),
    Jurnal VARCHAR(250),
    Tahun INT,
    NIDN_Penulis VARCHAR(50),
    Kuartil VARCHAR(10),
    LoadDate DATETIME DEFAULT GETDATE()
);

-- Staging Logs (Untuk Dashboard Sistem Data)
IF OBJECT_ID('stg.System_Logs', 'U') IS NOT NULL DROP TABLE stg.System_Logs;
CREATE TABLE stg.System_Logs (
    Log_ID INT,
    Tipe_Log VARCHAR(50), -- 'Download', 'Search'
    Item_Name VARCHAR(200),
    User_Action VARCHAR(50),
    Timestamp DATETIME
);

PRINT '>>> STAGING TABLES BERHASIL DIBUAT <<<';


-- =======================================================
-- 2. CREATE INDEXES (Checklist Misi 2: Indexes dibuat)
-- Deskripsi: Meningkatkan kecepatan query dashboard Power BI
-- =======================================================

-- Index untuk Fact_Proposal (Sering difilter berdasarkan Waktu & Pusat Riset)
CREATE NONCLUSTERED INDEX IX_FactProposal_DatePengajuan ON Fact_Proposal(DateKey_Pengajuan);
CREATE NONCLUSTERED INDEX IX_FactProposal_PusatRiset ON Fact_Proposal(PusatRisetKey_Afiliasi);
CREATE NONCLUSTERED INDEX IX_FactProposal_Skema ON Fact_Proposal(SkemaKey);
CREATE NONCLUSTERED INDEX IX_FactProposal_Peneliti ON Fact_Proposal(PenelitiKey_Ketua);

-- Index untuk Fact_KKN (Filter Lokasi & Waktu)
CREATE NONCLUSTERED INDEX IX_FactKKN_Lokasi ON Fact_KKN(LokasiKey);
CREATE NONCLUSTERED INDEX IX_FactKKN_Date ON Fact_KKN(DateKey_Mulai);

-- Index untuk Fact_Authorship (Join ke Peneliti & Publikasi)
CREATE NONCLUSTERED INDEX IX_FactAuthorship_Peneliti ON Fact_Authorship(PenelitiKey);
CREATE NONCLUSTERED INDEX IX_FactAuthorship_Publikasi ON Fact_Authorship(PublikasiKey);

-- Index untuk Fact Tambahan (Dashboard Visualisasi Baru)
CREATE NONCLUSTERED INDEX IX_FactDataset_Date ON Fact_Dataset_Statistik(DateKey_Log);
CREATE NONCLUSTERED INDEX IX_FactSearch_KataKunci ON Fact_Pencarian_Log(KataKunciKey);

PRINT '>>> INDEXING SELESAI <<<';
GO
