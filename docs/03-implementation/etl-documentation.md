# Dokumentasi ETL - Data Warehouse LPPM ITERA
---

## 1. Gambaran Umum ETL

### 1.1 Tujuan
Proses ETL (Extract, Transform, Load) ini bertujuan untuk mengintegrasikan data dari sistem operasional penelitian (SIPPM), sistem pengabdian (KKN), dan log aktivitas sistem ke dalam Data Warehouse `DW_LPPM`. Data ini akan digunakan untuk analisis produktivitas dosen, sebaran pengabdian, dan kinerja riset institusi.

### 1.2 Jadwal ETL
| Proses | Frekuensi | Jadwal | Metode |
|--------|-----------|--------|--------|
| ETL Harian (Incremental) | Setiap Hari | 02:00 WIB | SQL Agent Job |
| Refresh Data Master | Mingguan | Minggu 03:00 WIB | Manual / Scheduled | 
| Full Reload | Bulanan | Akhir Bulan | Stored Procedure |

### 1.3 Komponen ETL

- **Staging Layer:** Skema `stg` di database untuk menampung data mentah.
- **Transformation Layer:** Menggunakan T-SQL Stored Procedure (`usp_Master_ETL`) untuk pembersihan dan logika bisnis.
- **Data Quality Layer:** Validasi referensi kunci (Foreign Key) dan logika tanggal.
- **Loading Layer:** Insert ke tabel Dimensi dan Fakta di skema `dbo`.

---

## 2. Sumber Data

### 2.1 Sistem Sumber

| Sistem Sumber | Deskripsi | Koneksi | Frekuensi Update |
|---------------|-----------|---------|------------------|
| **SIPPM (Sistem Penelitian)** | Data proposal dan hibah | SQL Database | Real-time |
| **Sistem KKN** | Data penempatan mahasiswa | Web Database | Semesteran |
| **SINTA / Scopus** | Data publikasi eksternal | API / CSV | Bulanan |
| **Server Logs** | Log akses dan pencarian | System Logs | Real-time |

### 2.2 Tabel Sumber Utama

- **Proposal:** Data pengajuan judul, dana, dan status review.
- **Peneliti:** Data dosen, NIDN, dan jabatan fungsional.
- **Mahasiswa:** Data peserta KKN dan prodi asal.
- **Publikasi:** Metadata artikel ilmiah dan sitasi.

---

## 3. Arsitektur ETL

### 3.1 Diagram Arsitektur

graph LR
    subgraph Sources
    A[SIPPM DB] 
    B[Sistem KKN] 
    C[Server Logs]
    end

    subgraph Staging
    D[Staging Schema] 
    end

    subgraph DataWarehouse
    E[Dimensi] 
    F[Fakta] 
    end

    A --> D
    B --> D
    C --> D
    D --> E
    D --> F

3.2 Teknologi
Database: SQL Server 2019

ETL Tool: T-SQL Stored Procedures (usp_Master_ETL)

Orchestration: SQL Server Agent Jobs

4. Alur Data (Data Flow)
Persiapan (Pre-ETL): - Membersihkan tabel Staging (TRUNCATE).

Memastikan tidak ada koneksi yang terkunci.

Ekstraksi (Extract): - Mengambil data transaksi baru dari SIPPM ke stg.Proposal.

Mengambil log aktivitas ke stg.System_Logs.

Transformasi (Transform):

Data Cleaning: Menghapus spasi berlebih pada nama dosen.

Standardisasi: Mengubah format tanggal menjadi DateKey (YYYYMMDD).

Business Logic: Menghitung Lama_Review_Hari (Tgl Keputusan - Tgl Ajuan).

Handling Null: Mengisi nilai kosong pada Dana_Disetujui dengan 0 jika status ditolak.

Muat Dimensi (Load Dimension):

Update Dim_Peneliti (SCD Type 2) jika ada perubahan jabatan.

Insert data baru ke Dim_Publikasi.

Muat Fakta (Load Fact):

Load Fact_Proposal dengan referensi key yang valid.

Load Fact_KKN dan Fact_Authorship.

Load Fact_Pencarian_Log untuk analisis sistem.

5. Aturan Transformasi (Transformation Rules)
5.1 Dim_Peneliti (SCD Type 2)
Logika: Jika dosen naik jabatan (misal: Lektor ke Lektor Kepala), record lama dinonaktifkan (IsCurrent = 0) dan record baru dibuat (IsCurrent = 1).

Tujuan: Melacak riwayat produktivitas dosen pada setiap jenjang jabatan.

5.2 Fact_Proposal (Logika Bisnis)
Dana Disetujui:

Jika Status = 'Diterima', Dana Disetujui = 80-100% Dana Ajuan.

Jika Status = 'Ditolak', Dana Disetujui = 0.

Tanggal Keputusan:

Harus lebih besar atau sama dengan Tanggal Pengajuan (Validasi Logika).

6. Prosedur ETL Utama
6.1 Master Procedure
dbo.usp_Master_ETL: Prosedur utama yang dipanggil oleh SQL Agent. Mengatur urutan eksekusi:

Populate Dimensions

Populate Facts

Update Statistics

6.2 Validasi Data (QA Checks)
Script validasi dijalankan setelah ETL selesai:

Memastikan tidak ada PenelitiKey yang NULL (Orphan Data).

Memastikan Total Data Proposal sesuai target (misal > 50.000 rows).

7. Penanganan Error
Transaction Management: Menggunakan BEGIN TRY...COMMIT/ROLLBACK dalam Stored Procedure untuk mencegah data parsial masuk jika terjadi error.

Logging: Kesalahan dicatat dalam tabel sistem SQL Server atau log agent.
