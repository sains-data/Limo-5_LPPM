# Prosedur Pemulihan - Data Warehouse DW_LPPM (Kelompok 5)

---

## 1. Gambaran Umum

Dokumen ini menyediakan prosedur standar operasional (SOP) pemulihan untuk data warehouse **DW_LPPM**. Prosedur backup telah diotomatisasi menggunakan script `SQL-Scripts/12_Backup.sql`.

### Tujuan Pemulihan (Recovery Objectives)

| Metrik | Target | Keterangan |
|--------|--------|------------|
| **RTO** (Recovery Time Objective) | 4 jam | Waktu maksimal sistem boleh down. |
| **RPO** (Recovery Point Objective) | 6 jam | Maksimal data hilang (sesuai interval log backup). |

---

## 2. Strategi Backup

### Jadwal Backup Otomatis

| Tipe Backup | Frekuensi | Waktu Eksekusi | Retensi | Stored Procedure |
|-------------|-----------|----------------|---------|------------------|
| **Full** | Mingguan | Minggu 02:00 | 30 hari | `sp_FullBackup_LPPM` |
| **Differential** | Harian | Senin-Sabtu 02:00 | 14 hari | `sp_DifferentialBackup_LPPM` |
| **Transaction Log** | Per 6 Jam | 00:00, 06:00, 12:00, 18:00 | 7 hari | `sp_LogBackup_LPPM` |

### Konvensi Penamaan File & Lokasi

**Lokasi Penyimpanan:** `C:\Backup\`

| Tipe | Format Nama File |
|------|------------------|
| Full | `DW_LPPM_Full_YYYYMMDD_HHMMSS.bak` |
| Differential | `DW_LPPM_Diff_YYYYMMDD_HHMMSS.bak` |
| Log | `DW_LPPM_Log_YYYYMMDD_HHMMSS.trn` |

---

## 3. Skenario Pemulihan

| Skenario | Penyebab Umum | Metode Restore |
|----------|---------------|----------------|
| **Kerusakan Database Total** | File korup, kegagalan disk | Restore Full Terakhir + Diff Terakhir + Log susulan |
| **Human Error** | Tidak sengaja `DELETE` / `DROP` | Point-in-Time Recovery (Stop At) |
| **Server Crash** | OS Failure, Ransomware | Install ulang SQL Server -> Restore Full ke Server Baru |

---

## 4. Prosedur Restore Utama (Langkah demi Langkah)

Berikut adalah script T-SQL untuk melakukan restore database dari bencana total.

### Langkah 1: Verifikasi File Backup
Pastikan file backup bisa dibaca dan tidak korup.
```sql


RESTORE VERIFYONLY 
FROM DISK = 'C:\Backup\DW_LPPM_Full_20251208_020000.bak'
WITH CHECKSUM;
