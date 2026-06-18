# PRD - Kasir UMKM Offline

## Product Name

WarungKasir

## Product Vision

Membantu pemilik usaha kecil dan warung sembako mencatat stok, transaksi, omzet, dan keuntungan secara mudah tanpa memerlukan internet.

## Background

Sebagian besar warung sembako masih menggunakan pencatatan manual sehingga sulit mengetahui:

* Stok barang yang tersedia
* Barang yang paling laku
* Omzet harian
* Keuntungan harian
* Riwayat transaksi

Aplikasi ini dibuat sebagai solusi POS (Point of Sale) sederhana yang dapat berjalan sepenuhnya secara offline menggunakan Flutter dan SQLite.

---

# Objectives

1. Memudahkan proses transaksi penjualan.
2. Mengurangi kesalahan pencatatan stok.
3. Menyediakan laporan omzet dan keuntungan secara otomatis.
4. Mendukung penggunaan tanpa internet.
5. Dapat dikembangkan ke versi barcode dan cloud di masa depan.

---

# Target User

## Primary User

Pemilik warung sembako.

## Secondary User

Kasir toko kecil.

---

# MVP Features

## Dashboard

Menampilkan:

* Omzet hari ini
* Profit hari ini
* Jumlah transaksi hari ini
* Jumlah produk aktif

---

## Manajemen Barang

* Tambah barang
* Edit barang
* Hapus barang
* Cari barang
* Lihat stok barang

---

## Manajemen Stok

* Tambah stok
* Riwayat perubahan stok
* Koreksi stok

---

## Kasir

* Cari barang berdasarkan nama
* Tambah ke keranjang
* Ubah jumlah barang
* Hapus barang dari keranjang
* Hitung total otomatis
* Checkout
* Simpan transaksi

---

## Struk

* Simpan transaksi sebagai struk
* Share struk PDF
* Persiapan integrasi printer bluetooth

---

## Riwayat Transaksi

* Daftar transaksi
* Detail transaksi
* Cetak ulang struk

---

## Laporan

### Harian

* Omzet
* Profit
* Jumlah transaksi

### Bulanan

* Omzet
* Profit

### Produk Terlaris

Top produk berdasarkan jumlah penjualan.

---

# Out Of Scope MVP

* Barcode Scanner
* Multi User
* Sinkronisasi Cloud
* Multi Toko
* Manajemen Hutang Piutang
* Pembelian Supplier
* Akuntansi Lengkap

---

# Success Metrics

* Transaksi selesai dalam kurang dari 10 detik.
* Penambahan barang ke keranjang maksimal 2 tap.
* Semua transaksi otomatis mengurangi stok.
* Omzet dan profit harian dapat dilihat tanpa perhitungan manual.

# Additional Feature - App Update & Maintenance

## Feature Name

Application Update Management

## Objective

Memastikan pengguna selalu mendapatkan versi aplikasi terbaru tanpa harus mencari file APK secara manual.

---

# User Story

Sebagai pemilik warung,

Saya ingin mengetahui jika ada versi aplikasi terbaru,

Sehingga saya dapat memperbarui aplikasi dengan mudah dan tetap mendapatkan fitur terbaru serta perbaikan bug.

---

# Functional Requirements

## Check Update

Aplikasi akan melakukan pengecekan versi saat:

* Aplikasi dibuka
* User menekan tombol "Cek Pembaruan"

---

## Update Notification

Jika tersedia versi baru:

Tampilkan informasi:

* Versi terbaru
* Changelog
* Ukuran file (opsional)

Action:

* Update Sekarang
* Nanti Saja

---

## Force Update

Administrator dapat menentukan apakah update wajib dilakukan.

Jika:

force_update = true

Maka user tidak dapat menggunakan aplikasi sebelum melakukan update.

---

## Manual Check

Menu:

Pengaturan → Cek Pembaruan

---

## Version Information

Menu Pengaturan menampilkan:

* Versi aplikasi saat ini
* Tanggal build
* Status update

---

# Future Features

* Delta update
* Background download
* Release channel (Stable / Beta)
* Auto update tanpa interaksi pengguna
