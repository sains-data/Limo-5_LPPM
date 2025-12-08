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

```mermaid
graph LR
    subgraph Sources
    A[SIPPM DB]
    B[Sistem KKN]
    C[Server Logs]
    end

    subgraph Staging
    D[Staging Schema (stg)]
    end

    subgraph DataWarehouse
    E[Dimensi (dbo)]
    F[Fakta (dbo)]
    end

    A --> D
    B --> D
    C --> D
    D -->|Transform & Cleanse| E
    D -->|Aggregasi & Load| F
