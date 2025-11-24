# Data Mart - Lembaga Penelitian dan Pengabdian Kepada Masyarakat (LPPM)
Tugas Besar Pergudangan Data - Kelompok 5
SD25-31007 - Pergudangan Data Tugas Besar Kelompok

## Team Members
- 123450067 - Qois Olifio (Project Lead)
- 123450038 - Hanna Gresia Sinaga (ETL Developer)
- 123450108 - Citra Agustin (BI Developer & QA)
- 122450059 - Nathanael Daniel Santoso (Database Designer)

## Project Description
Proyek data mart ini dirancang untuk menganalisis dan memantau proses bisnis di Lembaga Penelitian dan Pengabdian Kepada Masyarakat (LPPM). Tujuannya adalah untuk menyediakan wawasan terkait produktivitas penelitian, pengelolaan hibah, capaian luaran (publikasi dan HKI), dan pelaksanaan pengabdian masyarakat (Abdimas) untuk mendukung pengambilan keputusan oleh pemangku kepentingan seperti Kepala LPPM dan Pimpinan Institut.

## Business Domain
Lembaga Penelitian dan Pengabdian Kepada Masyarakat (LPPM), yang bertanggung jawab atas pengelolaan dan koordinasi seluruh kegiatan penelitian dan pengabdian. Proses bisnis utama yang dianalisis meliputi:
* Manajemen Hibah Penelitian & Abdimas (penerimaan proposal, review, penetapan dana)
* Monitoring Kemajuan Proyek (pelaporan progres, pemantauan serapan anggaran)
* Pengelolaan Luaran (Output) (pendataan publikasi, validasi jurnal, pendaftaran HKI)
* Pelaksanaan Pengabdian dan KKN (penerimaan pendaftaran KKN, penempatan DPL, pengelolaan mitra)
* Pemantauan Kinerja Riset (analisis produktivitas peneliti, pelacakan sitasi)

## Architecture
- Approach: Kimball/Inmon/Data Vault
- Platform: SQL Server on Azure VM
- ETL: SSIS

## Key Features
- Fact tables:
  * Fact_Proposal
  * Fact_Authorship
  * Fact_KKN
- Dimension tables:
  * Dim_Peneliti
  * Dim_Prodi
  * Dim_PusatRiset
  * Dim_Skema
  * Dim_Publikasi
  * Dim_Lokasi
  * Dim_Date
  * Dim_Mahasiswa
- KPIs:
  * Jumlah Publikasi Bereputasi (per peneliti/pusat riset)
  * Rasio Keberhasilan Proposal (Success Rate)
  * Jumlah HKI Didaftarkan
  * Rata-rata Waktu Review Proposal
  * Jumlah Mitra Terlibat (untuk Abdimas)
  * Jumlah Sitasi per Peneliti

## Documentation
- [Business Requirements] (docs/01-requirements/)
- [Design Documents] (docs/02-design/)

## Timeline
- Misi 1: [Tanggal]
- Misi 2: [Tanggal]
- Misi 3: [Tanggal]
