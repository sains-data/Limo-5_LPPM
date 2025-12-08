# Business Requirements Analysis
## Data Warehouse LPPM (Lembaga Penelitian dan Pengabdian Kepada Masyarakat) ITERA

---

## 1. Identifikasi Stakeholders

### Primary Stakeholders
- **Kepala LPPM**: Memantau kinerja makro penelitian, serapan dana hibah, dan target luaran institusi.
- **Ketua Pusat Riset**: Memantau produktivitas riset di pusat masing-masing (misal: Pusat Mitigasi Gempa, OAIL).
- **Kepala Pusat Pengabdian (KKN)**: Mengelola sebaran lokasi KKN dan jumlah mahasiswa terlibat.
- **Admin Data LPPM**: Mengelola validasi proposal dan update data sistem.

### Secondary Stakeholders
- **Dekan & Kaprodi**: Melihat kinerja dosen di fakultas/prodi masing-masing.
- **Dosen / Peneliti**: Melihat rekam jejak hibah dan status publikasi.
- **Mahasiswa**: Peserta KKN dan asisten peneliti.

### Decision Makers
- **Rektor & Wakil Rektor Bidang Akademik**: Penentuan kebijakan alokasi dana riset tahunan.
- **Kepala LPPM**: Persetujuan proposal dan penentuan prioritas topik riset.

---

## 2. Analisis Proses Bisnis

### Proses 1: Manajemen Hibah Penelitian & Abdimas
*Proses pengajuan proposal oleh dosen, review oleh reviewer, hingga penetapan pendanaan.*

**KPIs & Metrik Utama**:
- **Total Dana Disetujui** (`Total_Dana_Setuju`): Total nominal hibah yang dicairkan.
- **Rasio Keberhasilan Proposal**: Persentase proposal `Diterima` vs Total Masuk.
- **Efisiensi Review** (`Avg_Review_Days`): Rata-rata durasi dari submit hingga keputusan.
- **Distribusi Skema**: Jumlah proposal berdasarkan jenis skema (Dasar, Terapan, Abdimas).

### Proses 2: Pengabdian Masyarakat & KKN
*Proses pelaksanaan Kuliah Kerja Nyata (KKN) dan sebaran lokasinya.*

**KPIs & Metrik Utama**:
- **Sebaran Geografis**: Jumlah mahasiswa per Kabupaten/Kecamatan (`Jml_Mahasiswa`).
- **Kepadatan DPL**: Rasio jumlah mahasiswa per Dosen Pembimbing Lapangan.
- **Tren Partisipasi**: Jumlah mahasiswa KKN per tahun/periode.

### Proses 3: Produktivitas Luaran (Publikasi)
*Pencatatan hasil riset berupa jurnal ilmiah dan sitasi.*

**KPIs & Metrik Utama**:
- **Kualitas Publikasi**: Jumlah artikel Q1/Q2 vs Q3/Q4.
- **Impact Factor**: Total jumlah sitasi (`Jumlah_Sitasi`).
- **Peringkat Peneliti**: Top 10 dosen paling produktif berdasarkan jumlah publikasi.

### Proses 4: Analisis Sistem & Kebutuhan Data (System Logs)
*Pemantauan akses pengguna terhadap data/dokumen di sistem informasi LPPM.*

**KPIs & Metrik Utama**:
- **Topik Populer**: Kata kunci riset yang paling sering dicari (`Total_Pencarian`).
- **Kesenjangan Informasi**: Kata kunci yang dicari namun tidak ditemukan hasilnya (`Pencarian_Nihil`).
- **Pemanfaatan Aset**: Jumlah unduhan dataset/dokumen panduan (`Total_Downloads`).
- **Kinerja Server**: Rata-rata waktu respon sistem dalam milidetik.

---

## 3. Kebutuhan Analitik (Analytical Requirements)

### Pertanyaan Bisnis Utama (Business Questions)

**Strategic Level (Pimpinan):**
1. Bagaimana tren total dana penelitian selama 3 tahun terakhir (2022-2025)?
2. Pusat Riset mana yang menyerap anggaran terbesar dan paling produktif?
3. Apakah alokasi dana sebanding dengan luaran publikasi yang dihasilkan?

**Operational Level (Manajemen):**
4. Berapa rata-rata waktu yang dibutuhkan untuk me-review satu proposal?
5. Di kabupaten mana saja konsentrasi kegiatan KKN terbesar di Lampung?
6. Prodi mana yang paling aktif mengirimkan proposal penelitian?

**Technical/System Level:**
7. Dokumen/Dataset apa yang paling sering diunduh oleh civitas akademika?
8. Topik riset apa yang sering dicari tapi datanya belum tersedia (Search Gap)?

### Jenis Laporan / Dashboard yang Dibutuhkan
1. **Executive Overview Dashboard**: Menampilkan KPI makro (Total Proposal, Total Dana, Tren Waktu).
2. **Geographic Analysis Dashboard**: Peta sebaran lokasi KKN dan Abdimas (Bubble Map).
3. **Researcher Performance Dashboard**: Profil produktivitas dosen (Scatter Plot Dana vs Publikasi).
4. **System Analytics Dashboard**: Statistik unduhan dataset dan log pencarian kata kunci.

### Granularitas Data
- **Time Grain**: Harian (untuk log sistem), Bulanan/Tahunan (untuk proposal & publikasi).
- **Dimension Grain**: Per Peneliti, Per Prodi, Per Pusat Riset, Per Kabupaten.
- **Volume Data Target**: Minimal 50.000 record transaksi historis untuk analisis tren yang akurat.

---
