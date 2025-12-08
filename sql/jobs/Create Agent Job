/*
===========================================================================
File: 09_create_agent_job.sql
Deskripsi: Script untuk membuat SQL Server Agent Job (Penjadwalan Otomatis)
Database Target: DW_LPPM (Kelompok 5)
===========================================================================
*/

USE msdb;
GO

-- 1. Hapus Job Lama jika ada (biar tidak duplikat error)
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'ETL_Daily_Load_LPPM')
    EXEC sp_delete_job @job_name = 'ETL_Daily_Load_LPPM', @delete_unused_schedule=1;
GO

-- 2. Buat Job Baru
EXEC sp_add_job
    @job_name = N'ETL_Daily_Load_LPPM', -- Nama Job Kita
    @enabled = 1,
    @description = N'Daily ETL load for DW_LPPM Data Mart';
GO

-- 3. Buat Step (Langkah Kerja)
-- Step ini akan memanggil Stored Procedure 'usp_Master_ETL' yang sudah kita buat
EXEC sp_add_jobstep
    @job_name = N'ETL_Daily_Load_LPPM',
    @step_name = N'Execute Master ETL Process',
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.usp_Master_ETL;',  -- Perintah yang dijalankan
    @database_name = N'DW_LPPM',             -- TARGET DATABASE YANG BENAR
    @retry_attempts = 3,
    @retry_interval = 5;
GO

-- 4. Buat Jadwal (Schedule) - Harian Jam 02:00 Pagi
EXEC sp_add_schedule
    @schedule_name = N'Daily at 2 AM',
    @freq_type = 4,        -- 4 = Harian
    @freq_interval = 1,    -- Setiap 1 hari
    @active_start_time = 020000; -- 02:00:00
GO

-- 5. Tempelkan Jadwal ke Job
EXEC sp_attach_schedule
    @job_name = N'ETL_Daily_Load_LPPM',
    @schedule_name = N'Daily at 2 AM';
GO

-- 6. Aktifkan Job di Server Lokal
EXEC sp_add_jobserver
    @job_name = N'ETL_Daily_Load_LPPM',
    @server_name = N'(local)';
GO

PRINT '>>> JOB AGENT BERHASIL DIBUAT: ETL_Daily_Load_LPPM <<<';
