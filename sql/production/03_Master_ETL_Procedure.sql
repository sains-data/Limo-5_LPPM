/*
===========================================================================
FILE: 03_Master_ETL_Procedure.sql
DESKRIPSI: Stored Procedure Utama untuk Generate & Load Data (50k Rows)
DATABASE TARGET: DW_LPPM
===========================================================================
*/

USE DW_LPPM;
GO

-- Hapus Prosedur Lama jika ada
CREATE OR ALTER PROCEDURE dbo.usp_Master_ETL
AS
BEGIN
    SET NOCOUNT ON;
    PRINT '>>> MEMULAI MASTER ETL PROCESS';

    -- 1. BERSIHKAN DATA LAMA (TRUNCATE/DELETE)
    -- Urutan delete penting untuk menghindari error Foreign Key
    DELETE FROM Fact_Proposal;
    DELETE FROM Fact_KKN;
    DELETE FROM Fact_Authorship;
    DELETE FROM Fact_Dataset_Statistik;
    DELETE FROM Fact_Pencarian_Log;
    
    DELETE FROM Dim_Peneliti;
    DELETE FROM Dim_Mahasiswa;
    DELETE FROM Dim_Publikasi;
    
    -- Reset tabel dimensi statis (opsional, biar bersih aja)
    DELETE FROM Dim_Prodi;
    DELETE FROM Dim_PusatRiset;
    DELETE FROM Dim_Skema;
    DELETE FROM Dim_Lokasi;
    DELETE FROM Dim_Date;
    DELETE FROM Dim_Dataset;
    DELETE FROM Dim_KataKunci;

    -- Reset Identity Columns (Biar ID mulai dari 1 lagi)
    DBCC CHECKIDENT ('Fact_Proposal', RESEED, 0);
    DBCC CHECKIDENT ('Dim_Peneliti', RESEED, 0);
    -- (Ulangi untuk tabel lain jika perlu)

    PRINT '-> Data Lama Berhasil Dihapus.';

    -- =======================================================
    -- 2. POPULATE STATIC DIMENSIONS (Data Master Asli ITERA)
    -- =======================================================
    
    -- Dimensi Prodi
    INSERT INTO Dim_Prodi VALUES 
    ('SD','Sains Data','Sains','Fakultas Sains'), ('SA','Sains Aktuaria','Sains','Fakultas Sains'),
    ('IF','Teknik Informatika','TPI','FTI'), ('PWK','Perencanaan Wilayah','TIK','FTIK'),
    ('AR','Arsitektur','TIK','FTIK'), ('SI','Teknik Sipil','TIK','FTIK'),
    ('TL','Teknik Lingkungan','TIK','FTIK'), ('MA','Matematika','Sains','Fakultas Sains');

    -- Dimensi Pusat Riset
    INSERT INTO Dim_PusatRiset VALUES 
    ('Pusat Mitigasi Gempa','Prof. Harkunti'), ('Pusat Astronomi (OAIL)','Dr. Meezan'),
    ('Pusat Riset Material','Harry Yuliansyah'), ('Pusat Riset Hayati','Dr. Winati'),
    ('Pusat Keamanan Digital','Prof. Sarwono'), ('Pusat Studi Pembangunan','Rinda Gusvita'),
    ('Pusat Integrated Waste','Ir. Rifqi Sufra'), ('Pusat Penelitian Publikasi','Dr. Aditya');

    -- Dimensi Lainnya
    INSERT INTO Dim_Skema VALUES ('Hibah Dasar','Penelitian','Internal'), ('Hibah Terapan','Penelitian','Ristekdikti'), ('Abdimas Desa','Abdimas','Internal');
    INSERT INTO Dim_Lokasi VALUES ('Desa Sabah Balau','Tanjung Bintang','Lampung Selatan','Lampung'), ('Way Huwi','Jati Agung','Lampung Selatan','Lampung');
    
    -- Dimensi Dataset & Kata Kunci (Untuk Dashboard Baru)
    INSERT INTO Dim_Dataset VALUES ('Dataset Fasilitas', 'Fasilitas', 'CSV'), ('Dataset Keuangan', 'Keuangan', 'JSON'), ('Dataset Akademik', 'Akademik', 'Excel');
    INSERT INTO Dim_KataKunci VALUES ('beasiswa', 'Kemahasiswaan'), ('inventaris', 'Fasilitas'), ('nilai', 'Akademik'), ('jurnal', 'Penelitian');

    -- Dimensi Tanggal (2022-2030) - Safe Range
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

    -- Dimensi Dosen & Mahasiswa (Dummy)
    DECLARE @i INT = 1;
    WHILE @i <= 250 BEGIN INSERT INTO Dim_Peneliti VALUES (CONCAT('00',100+@i), CONCAT('Dosen ',@i), 'Lektor', (ABS(CHECKSUM(NEWID()))%8)+1, (ABS(CHECKSUM(NEWID()))%8)+1, 1); SET @i=@i+1; END
    SET @i = 1;
    WHILE @i <= 1000 BEGIN INSERT INTO Dim_Mahasiswa VALUES (CONCAT('121',@i), CONCAT('Mhs ',@i), (ABS(CHECKSUM(NEWID()))%8)+1); SET @i=@i+1; END
    
    -- Dimensi Publikasi (Dummy)
    SET @i = 1;
    WHILE @i <= 5000 BEGIN INSERT INTO Dim_Publikasi VALUES (CONCAT('Publikasi Topik ',@i), 'Jurnal ITERA', 2024, 'Q1', 'S1'); SET @i=@i+1; END

    PRINT '-> Dimensi Selesai Diisi.';

    -- =======================================================
    -- 3. POPULATE FACTS (50.000 ROWS)
    -- =======================================================
    
    -- A. Fact Proposal (50k)
    PRINT 'Sedang generate 50.000 data proposal...';
    DECLARE @x INT = 1;
    DECLARE @RandDateKey INT;
    DECLARE @RandDateObj DATE;
    DECLARE @NewDateKey INT;
    
    WHILE @x <= 50000
    BEGIN
        -- Logika Tanggal Aman (Fix Error Sebelumnya)
        SELECT TOP 1 @RandDateKey = DateKey FROM Dim_Date WHERE Tahun BETWEEN 2022 AND 2025 ORDER BY NEWID();
        SET @RandDateObj = CAST(CAST(@RandDateKey AS CHAR(8)) AS DATE);
        SET @NewDateKey = CAST(CONVERT(VARCHAR(8), DATEADD(DAY, (ABS(CHECKSUM(NEWID())) % 90), @RandDateObj), 112) AS INT);

        INSERT INTO Fact_Proposal VALUES (
            100000+@x, @RandDateKey, @NewDateKey, 
            (ABS(CHECKSUM(NEWID()))%250)+1, (ABS(CHECKSUM(NEWID()))%3)+1, (ABS(CHECKSUM(NEWID()))%8)+1,
            (ABS(CHECKSUM(NEWID()))%100 + 10) * 1000000, 
            (ABS(CHECKSUM(NEWID()))%100) * 1000000, 
            30, 'Diterima'
        );
        SET @x = @x + 1;
    END

    -- B. Fact KKN & Authorship & Logs (Sisa)
    SET @x = 1;
    WHILE @x <= 5000 BEGIN INSERT INTO Fact_KKN VALUES (20240601, (ABS(CHECKSUM(NEWID()))%2)+1, (ABS(CHECKSUM(NEWID()))%500)+1, (ABS(CHECKSUM(NEWID()))%250)+1, 1, 'KKN 2024'); SET @x=@x+1; END
    SET @x = 1;
    WHILE @x <= 5000 BEGIN INSERT INTO Fact_Authorship VALUES ((ABS(CHECKSUM(NEWID()))%250)+1, @x, 20240101, 10); SET @x=@x+1; END
    
    -- Fact Tambahan (Untuk Grafik Baru)
    SET @x = 1;
    WHILE @x <= 5000 BEGIN INSERT INTO Fact_Dataset_Statistik VALUES (20240101, (ABS(CHECKSUM(NEWID()))%3)+1, 50, 100); SET @x=@x+1; END
    SET @x = 1;
    WHILE @x <= 5000 BEGIN INSERT INTO Fact_Pencarian_Log VALUES (20240101, (ABS(CHECKSUM(NEWID()))%4)+1, 1, 0, 200); SET @x=@x+1; END

    PRINT '>>> ETL SELESAI! <<<';
END;
GO
