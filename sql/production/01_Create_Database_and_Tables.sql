/*
===========================================================================
FILE: 01_Create_Database_and_Tables.sql
DESKRIPSI: DDL untuk Database DW_LPPM (Kelompok 5)
===========================================================================
*/

USE master;
GO

-- 1. BERSIHKAN DATABASE LAMA (JIKA ADA)
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
CREATE SCHEMA stg; -- Schema khusus Staging Area
GO

-- =======================================================
-- 3. CREATE DIMENSION TABLES
-- =======================================================

CREATE TABLE Dim_Prodi (
    ProdiKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Kode_Prodi VARCHAR(10), 
    Nama_Prodi VARCHAR(150), 
    Jurusan VARCHAR(150), 
    Fakultas VARCHAR(100)
);

CREATE TABLE Dim_PusatRiset (
    PusatRisetKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Nama_Pusat_Riset VARCHAR(150), 
    Nama_Kepala_Pusat VARCHAR(150)
);

CREATE TABLE Dim_Skema (
    SkemaKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Nama_Skema VARCHAR(100), 
    Jenis_Skema VARCHAR(50), 
    Sumber_Dana VARCHAR(50)
);

CREATE TABLE Dim_Lokasi (
    LokasiKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Nama_Desa VARCHAR(100), 
    Kecamatan VARCHAR(100), 
    Kabupaten VARCHAR(100), 
    Provinsi VARCHAR(100)
);

CREATE TABLE Dim_Date (
    DateKey INT NOT NULL PRIMARY KEY,
    Tanggal DATE, 
    Hari INT, 
    Bulan INT, 
    NamaBulan VARCHAR(20), 
    Tahun INT, 
    Kuartal INT, 
    Semester VARCHAR(20)
);

CREATE TABLE Dim_Publikasi (
    PublikasiKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Judul_Artikel VARCHAR(500), -- Nama kolom yang benar
    Jurnal VARCHAR(200), 
    Tahun_Terbit INT, 
    Kuartil VARCHAR(10), 
    Sinta_Rank VARCHAR(10)
);

-- Dimensi Tambahan (Dataset & Kata Kunci - Untuk Laporan Visualisasi Baru)
CREATE TABLE Dim_Dataset (
    DatasetKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Nama_Dataset VARCHAR(200),
    Kategori_Nama VARCHAR(100),
    Format VARCHAR(50)
);

CREATE TABLE Dim_KataKunci (
    KataKunciKey INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Kata_Kunci VARCHAR(100),
    Kategori_Pencarian VARCHAR(100)
);

-- Dimensi dengan Foreign Key (Dibuat belakangan)
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
    CONSTRAINT FK_FP_DateAjuan FOREIGN KEY (DateKey_Pengajuan) REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_FP_DatePutus FOREIGN KEY (DateKey_Keputusan) REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_FP_Ketua FOREIGN KEY (PenelitiKey_Ketua) REFERENCES Dim_Peneliti(PenelitiKey),
    CONSTRAINT FK_FP_Skema FOREIGN KEY (SkemaKey) REFERENCES Dim_Skema(SkemaKey),
    CONSTRAINT FK_FP_Pusat FOREIGN KEY (PusatRisetKey_Afiliasi) REFERENCES Dim_PusatRiset(PusatRisetKey)
);

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

-- Fact Tambahan (Log Sistem - Untuk Visualisasi Baru)
CREATE TABLE Fact_Dataset_Statistik (
    StatKey BIGINT NOT NULL PRIMARY KEY IDENTITY(1,1),
    DateKey_Log INT,
    DatasetKey INT,
    Total_Downloads INT,
    Total_Views INT,
    CONSTRAINT FK_FDS_Date FOREIGN KEY (DateKey_Log) REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_FDS_Dataset FOREIGN KEY (DatasetKey) REFERENCES Dim_Dataset(DatasetKey)
);

CREATE TABLE Fact_Pencarian_Log (
    LogKey BIGINT NOT NULL PRIMARY KEY IDENTITY(1,1),
    DateKey_Log INT,
    KataKunciKey INT,
    Total_Pencarian INT,
    Total_Pencarian_Nihil INT, 
    Waktu_Respon_Ms INT,
    CONSTRAINT FK_FPL_Date FOREIGN KEY (DateKey_Log) REFERENCES Dim_Date(DateKey),
    CONSTRAINT FK_FPL_Kwd FOREIGN KEY (KataKunciKey) REFERENCES Dim_KataKunci(KataKunciKey)
);

PRINT '>>> DATABASE & TABEL BERHASIL DIBUAT <<<';
GO
