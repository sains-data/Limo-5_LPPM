/* =========================================================================
   File: 12_Backup.sql
   Deskripsi: Strategi Backup dan Recovery untuk DW_LPPM (Kelompok 5)
   Ref: Modul Misi 3 Step 4 (Backup Strategy)
   ========================================================================= */

USE master;
GO

-- 1. Pastikan Database dalam Recovery Model FULL (Syarat Transaction Log Backup)
ALTER DATABASE DW_LPPM SET RECOVERY FULL;
GO


-- =======================================================
-- 2. STORED PROCEDURES UNTUK BACKUP
-- =======================================================

-- A. FULL BACKUP (Mingguan)
CREATE OR ALTER PROCEDURE dbo.sp_FullBackup_LPPM
AS
BEGIN
    SET NOCOUNT ON;
    -- PENTING: Ganti path ini sesuai folder di laptop/server Anda (misal: C:\Backup\)
    DECLARE @BackupPath NVARCHAR(500) = 'C:\Backup\'; 
    DECLARE @FileName NVARCHAR(500);
    DECLARE @DatabaseName NVARCHAR(100) = 'DW_LPPM';
    DECLARE @CurrentDate NVARCHAR(50);
    
    -- Format nama file: DW_LPPM_Full_YYYYMMDD_HHMMSS.bak
    SET @CurrentDate = CONVERT(NVARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 108), ':', '');
    SET @FileName = @BackupPath + @DatabaseName + '_Full_' + @CurrentDate + '.bak';
    
    BACKUP DATABASE [DW_LPPM] 
    TO DISK = @FileName 
    WITH INIT, NAME = 'DW_LPPM Full Backup', COMPRESSION, STATS = 10;
    
    PRINT 'Full Backup sukses disimpan di: ' + @FileName;
END;
GO


-- B. DIFFERENTIAL BACKUP (Harian)
CREATE OR ALTER PROCEDURE dbo.sp_DifferentialBackup_LPPM
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BackupPath NVARCHAR(500) = 'C:\Backup\';
    DECLARE @FileName NVARCHAR(500);
    DECLARE @DatabaseName NVARCHAR(100) = 'DW_LPPM';
    DECLARE @CurrentDate NVARCHAR(50);
    
    SET @CurrentDate = CONVERT(NVARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 108), ':', '');
    SET @FileName = @BackupPath + @DatabaseName + '_Diff_' + @CurrentDate + '.bak';
    
    BACKUP DATABASE [DW_LPPM] 
    TO DISK = @FileName 
    WITH DIFFERENTIAL, INIT, NAME = 'DW_LPPM Diff Backup', COMPRESSION, STATS = 10;
    
    PRINT 'Differential Backup sukses disimpan di: ' + @FileName;
END;
GO


-- C. TRANSACTION LOG BACKUP (Per 6 Jam)
CREATE OR ALTER PROCEDURE dbo.sp_LogBackup_LPPM
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BackupPath NVARCHAR(500) = 'C:\Backup\';
    DECLARE @FileName NVARCHAR(500);
    DECLARE @DatabaseName NVARCHAR(100) = 'DW_LPPM';
    DECLARE @CurrentDate NVARCHAR(50);
    
    SET @CurrentDate = CONVERT(NVARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 108), ':', '');
    SET @FileName = @BackupPath + @DatabaseName + '_Log_' + @CurrentDate + '.trn';
    
    BACKUP LOG [DW_LPPM] 
    TO DISK = @FileName 
    WITH INIT, NAME = 'DW_LPPM Log Backup', COMPRESSION, STATS = 10;
    
    PRINT 'Transaction Log Backup sukses disimpan di: ' + @FileName;
END;
GO


-- D. CLEANUP OLD BACKUPS (Maintenance - Hapus History Lama)
CREATE OR ALTER PROCEDURE dbo.sp_CleanupOldBackups_LPPM
    @RetentionDays INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DeleteDate DATETIME = DATEADD(DAY, -@RetentionDays, GETDATE());
    
    -- Hapus history backup dari msdb agar tidak membengkak
    EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @DeleteDate;
    
    PRINT 'Cleanup History Backup (lebih dari ' + CAST(@RetentionDays AS VARCHAR) + ' hari) sukses.';
END;
GO


-- =======================================================
-- 3. SQL AGENT JOBS (PENJADWALAN OTOMATIS)
-- =======================================================
USE msdb;
GO

-- JOB 1: Full Backup (Mingguan - Setiap Minggu jam 02:00 Pagi)
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'LPPM_Backup_Full_Weekly')
    EXEC sp_delete_job @job_name = 'LPPM_Backup_Full_Weekly', @delete_unused_schedule=1;
GO
EXEC sp_add_job @job_name = 'LPPM_Backup_Full_Weekly', @enabled = 1;
EXEC sp_add_jobstep @job_name = 'LPPM_Backup_Full_Weekly', @step_name = 'Exec Full Backup', 
    @subsystem = 'TSQL', @command = 'EXEC master.dbo.sp_FullBackup_LPPM;', @database_name = 'master';
EXEC sp_add_schedule @schedule_name = 'WeeklySunday', @freq_type = 8, @freq_interval = 1, @freq_recurrence_factor = 1, @active_start_time = 020000;
EXEC sp_attach_schedule @job_name = 'LPPM_Backup_Full_Weekly', @schedule_name = 'WeeklySunday';
EXEC sp_add_jobserver @job_name = 'LPPM_Backup_Full_Weekly';
GO

-- JOB 2: Diff Backup (Harian - Senin s.d Sabtu jam 02:00 Pagi)
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'LPPM_Backup_Diff_Daily')
    EXEC sp_delete_job @job_name = 'LPPM_Backup_Diff_Daily', @delete_unused_schedule=1;
GO
EXEC sp_add_job @job_name = 'LPPM_Backup_Diff_Daily', @enabled = 1;
EXEC sp_add_jobstep @job_name = 'LPPM_Backup_Diff_Daily', @step_name = 'Exec Diff Backup', 
    @subsystem = 'TSQL', @command = 'EXEC master.dbo.sp_DifferentialBackup_LPPM;', @database_name = 'master';
EXEC sp_add_schedule @schedule_name = 'DailyNoSunday', @freq_type = 8, @freq_interval = 126, @freq_recurrence_factor = 1, @active_start_time = 020000;
EXEC sp_attach_schedule @job_name = 'LPPM_Backup_Diff_Daily', @schedule_name = 'DailyNoSunday';
EXEC sp_add_jobserver @job_name = 'LPPM_Backup_Diff_Daily';
GO

-- JOB 3: Log Backup (Setiap 6 Jam Sekali)
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'LPPM_Backup_Log_6Hourly')
    EXEC sp_delete_job @job_name = 'LPPM_Backup_Log_6Hourly', @delete_unused_schedule=1;
GO
EXEC sp_add_job @job_name = 'LPPM_Backup_Log_6Hourly', @enabled = 1;
EXEC sp_add_jobstep @job_name = 'LPPM_Backup_Log_6Hourly', @step_name = 'Exec Log Backup', 
    @subsystem = 'TSQL', @command = 'EXEC master.dbo.sp_LogBackup_LPPM;', @database_name = 'master';
EXEC sp_add_schedule @schedule_name = 'Every6Hours', @freq_type = 4, @freq_interval = 1, @freq_subday_type = 8, @freq_subday_interval = 6, @active_start_time = 000000;
EXEC sp_attach_schedule @job_name = 'LPPM_Backup_Log_6Hourly', @schedule_name = 'Every6Hours';
EXEC sp_add_jobserver @job_name = 'LPPM_Backup_Log_6Hourly';
GO

PRINT '>>> KONFIGURASI BACKUP DW_LPPM BERHASIL DITERAPKAN! <<<';