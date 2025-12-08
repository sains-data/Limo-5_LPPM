/* =========================================================================
   File: 11_Security.sql
   Deskripsi: Implementasi Keamanan (Roles, Users, Masking, Audit)
   Database Target: DW_LPPM (Kelompok 5)
   ========================================================================= */

USE DW_LPPM;
GO

-- =======================================================
-- 1. PEMBUATAN ROLE DATABASE
-- =======================================================

-- Cleanup Member Role Lama (Jika Ada)
IF DATABASE_PRINCIPAL_ID('executive_user') IS NOT NULL AND DATABASE_PRINCIPAL_ID('db_executive') IS NOT NULL
    ALTER ROLE db_executive DROP MEMBER executive_user;
IF DATABASE_PRINCIPAL_ID('analyst_user') IS NOT NULL AND DATABASE_PRINCIPAL_ID('db_analyst') IS NOT NULL
    ALTER ROLE db_analyst DROP MEMBER analyst_user;
IF DATABASE_PRINCIPAL_ID('etl_operator_user') IS NOT NULL AND DATABASE_PRINCIPAL_ID('db_etl_operator') IS NOT NULL
    ALTER ROLE db_etl_operator DROP MEMBER etl_operator_user;
IF DATABASE_PRINCIPAL_ID('viewer_user') IS NOT NULL AND DATABASE_PRINCIPAL_ID('db_viewer') IS NOT NULL
    ALTER ROLE db_viewer DROP MEMBER viewer_user;
GO

-- Hapus Role Lama
IF DATABASE_PRINCIPAL_ID('db_executive') IS NOT NULL DROP ROLE db_executive;
IF DATABASE_PRINCIPAL_ID('db_analyst') IS NOT NULL DROP ROLE db_analyst;
IF DATABASE_PRINCIPAL_ID('db_etl_operator') IS NOT NULL DROP ROLE db_etl_operator;
IF DATABASE_PRINCIPAL_ID('db_viewer') IS NOT NULL DROP ROLE db_viewer;
GO

-- Buat Role Baru
CREATE ROLE db_executive;    -- Untuk Pimpinan (Rektor/Ketua LPPM)
CREATE ROLE db_analyst;      -- Untuk Tim Data Science
CREATE ROLE db_etl_operator; -- Untuk Mesin/Job ETL
CREATE ROLE db_viewer;       -- Untuk Dosen/Tamu
GO

-- Grant Permissions (Hak Akses)
-- Executive: Bisa lihat semua data asli (Unmasked)
GRANT SELECT ON SCHEMA::dbo TO db_executive; 
GRANT UNMASK TO db_executive; 

-- Analyst: Bisa lihat data, buat view, dan lihat data asli
GRANT SELECT ON SCHEMA::dbo TO db_analyst;
GRANT CREATE VIEW TO db_analyst;
GRANT UNMASK TO db_analyst;

-- ETL Operator: Kuasa penuh untuk manipulasi data (CRUD)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO db_etl_operator;
GRANT EXECUTE TO db_etl_operator;

-- Viewer: Hanya bisa lihat data (terkena Masking)
GRANT SELECT ON SCHEMA::dbo TO db_viewer; 
GO


-- =======================================================
-- 2. PEMBUATAN LOGIN DAN USER
-- =======================================================

USE master;
GO
-- Hapus Login Lama di Server
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'executive_user') DROP LOGIN executive_user;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'analyst_user') DROP LOGIN analyst_user;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'etl_operator_user') DROP LOGIN etl_operator_user;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'viewer_user') DROP LOGIN viewer_user;
GO

-- Buat Login Baru
CREATE LOGIN executive_user WITH PASSWORD = 'Executive@2025', CHECK_POLICY = OFF;
CREATE LOGIN analyst_user WITH PASSWORD = 'Analyst@2025', CHECK_POLICY = OFF;
CREATE LOGIN etl_operator_user WITH PASSWORD = 'ETL0perator@2025', CHECK_POLICY = OFF;
CREATE LOGIN viewer_user WITH PASSWORD = 'Viewer@2025', CHECK_POLICY = OFF;
GO

USE DW_LPPM;
GO
-- Hapus User Lama di Database
IF DATABASE_PRINCIPAL_ID('executive_user') IS NOT NULL DROP USER executive_user;
IF DATABASE_PRINCIPAL_ID('analyst_user') IS NOT NULL DROP USER analyst_user;
IF DATABASE_PRINCIPAL_ID('etl_operator_user') IS NOT NULL DROP USER etl_operator_user;
IF DATABASE_PRINCIPAL_ID('viewer_user') IS NOT NULL DROP USER viewer_user;
GO

-- Mapping User Database ke Login Server
CREATE USER executive_user FOR LOGIN executive_user;
CREATE USER analyst_user FOR LOGIN analyst_user;
CREATE USER etl_operator_user FOR LOGIN etl_operator_user;
CREATE USER viewer_user FOR LOGIN viewer_user;
GO

-- Masukkan User ke dalam Role
ALTER ROLE db_executive ADD MEMBER executive_user;
ALTER ROLE db_analyst ADD MEMBER analyst_user;
ALTER ROLE db_etl_operator ADD MEMBER etl_operator_user;
ALTER ROLE db_viewer ADD MEMBER viewer_user;
GO


-- =======================================================
-- 3. DYNAMIC DATA MASKING (Perlindungan Data Pribadi)
-- =======================================================

-- Masking NIDN di Tabel Dim_Peneliti
-- Contoh: 00123456 -> 00XXXX56
IF OBJECT_ID('dbo.Dim_Peneliti', 'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Dim_Peneliti 
    ALTER COLUMN NIDN ADD MASKED WITH (FUNCTION = 'partial(2,"XXXX",2)');
END
GO

-- Masking NIM di Tabel Dim_Mahasiswa
-- Contoh: 121450123 -> 121XXXX23
IF OBJECT_ID('dbo.Dim_Mahasiswa', 'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Dim_Mahasiswa 
    ALTER COLUMN NIM ADD MASKED WITH (FUNCTION = 'partial(3,"XXXX",2)');
END
GO


-- =======================================================
-- 4. AUDIT TRAIL (Mencatat Perubahan Data Proposal)
-- =======================================================

-- Buat Tabel Log Audit
IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL DROP TABLE dbo.AuditLog;
GO

CREATE TABLE dbo.AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(128),
    Operation NVARCHAR(10), -- INSERT, UPDATE, DELETE
    RecordID BIGINT, 
    OldValue NVARCHAR(MAX),
    NewValue NVARCHAR(MAX),
    ModifiedBy NVARCHAR(128) DEFAULT SUSER_SNAME(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Trigger Audit pada Tabel Fact_Proposal
-- Setiap ada perubahan Proposal, akan dicatat siapa pelakunya
CREATE OR ALTER TRIGGER trg_Audit_Fact_Proposal
ON dbo.Fact_Proposal
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operation NVARCHAR(10);
    
    -- Tentukan Jenis Operasi
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted) SET @Operation = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted) SET @Operation = 'INSERT';
    ELSE SET @Operation = 'DELETE';

    -- Catat INSERT
    IF @Operation = 'INSERT'
        INSERT INTO dbo.AuditLog (TableName, Operation, RecordID, NewValue)
        SELECT 'Fact_Proposal', 'INSERT', ProposalKey, 
        CONCAT('Dana:', Dana_Diajukan, ', Status:', Status_Proposal) FROM inserted;

    -- Catat UPDATE
    IF @Operation = 'UPDATE'
        INSERT INTO dbo.AuditLog (TableName, Operation, RecordID, OldValue, NewValue)
        SELECT 'Fact_Proposal', 'UPDATE', i.ProposalKey, 
        CONCAT('Dana:', d.Dana_Diajukan, ', Status:', d.Status_Proposal),
        CONCAT('Dana:', i.Dana_Diajukan, ', Status:', i.Status_Proposal)
        FROM inserted i JOIN deleted d ON i.ProposalKey = d.ProposalKey;

    -- Catat DELETE
    IF @Operation = 'DELETE'
        INSERT INTO dbo.AuditLog (TableName, Operation, RecordID, OldValue)
        SELECT 'Fact_Proposal', 'DELETE', ProposalKey, 
        CONCAT('Dana:', Dana_Diajukan, ', Status:', Status_Proposal) FROM deleted;
END;
GO


-- =======================================================
-- 5. SQL SERVER AUDIT (Server Level Tracking)
-- =======================================================
USE master;
GO

-- Bersihkan Audit Lama
IF EXISTS (SELECT * FROM sys.server_audits WHERE name = 'LPPM_Audit')
BEGIN
    ALTER SERVER AUDIT LPPM_Audit WITH (STATE = OFF);
    DROP SERVER AUDIT LPPM_Audit;
END
GO

-- Buat Server Audit (Simpan Log ke File)
-- PENTING: Pastikan folder C:\Audit\ sudah dibuat manual di Windows Explorer
-- Jika menggunakan Docker/Linux, ganti path ke '/var/opt/mssql/data/'
CREATE SERVER AUDIT LPPM_Audit
TO FILE 
(
    FILEPATH = 'C:\Audit\', -- Ubah path ini jika perlu
    MAXSIZE = 100 MB,
    MAX_ROLLOVER_FILES = 10
)
WITH (ON_FAILURE = CONTINUE);
GO

-- Aktifkan Audit
ALTER SERVER AUDIT LPPM_Audit WITH (STATE = ON);
GO

-- Buat Spesifikasi Audit di Database Target
USE DW_LPPM;
GO

IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = 'LPPM_Audit_Spec')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION LPPM_Audit_Spec WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION LPPM_Audit_Spec;
END
GO

CREATE DATABASE AUDIT SPECIFICATION LPPM_Audit_Spec
FOR SERVER AUDIT LPPM_Audit
ADD (SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo BY public), -- Pantau semua aktivitas tabel
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP); -- Pantau perubahan user role
GO

ALTER DATABASE AUDIT SPECIFICATION LPPM_Audit_Spec WITH (STATE = ON);
GO

PRINT '=== KONFIGURASI KEAMANAN DW_LPPM BERHASIL DITERAPKAN ===';
