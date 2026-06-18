# FSD - Kasir UMKM Offline

## Technology Stack

### Frontend

Flutter

### State Management

Riverpod

### Local Database

SQLite (Drift)

### PDF

pdf
printing

### Thermal Printer Future

esc_pos_utils_plus
blue_thermal_printer

---

# Database Design

## products

| Field         | Type     |
| ------------- | -------- |
| id            | INTEGER  |
| name          | TEXT     |
| cost_price    | DOUBLE   |
| selling_price | DOUBLE   |
| stock         | INTEGER  |
| unit          | TEXT     |
| created_at    | DATETIME |
| updated_at    | DATETIME |
| deleted_at    | DATETIME |

---

## stock_histories

| Field      | Type     |
| ---------- | -------- |
| id         | INTEGER  |
| product_id | INTEGER  |
| qty        | INTEGER  |
| type       | TEXT     |
| note       | TEXT     |
| created_at | DATETIME |

type:

* IN
* OUT
* ADJUSTMENT

---

## transactions

| Field          | Type     |
| -------------- | -------- |
| id             | INTEGER  |
| invoice_number | TEXT     |
| subtotal       | DOUBLE   |
| payment        | DOUBLE   |
| change_amount  | DOUBLE   |
| total_profit   | DOUBLE   |
| created_at     | DATETIME |

---

## transaction_items

| Field          | Type    |
| -------------- | ------- |
| id             | INTEGER |
| transaction_id | INTEGER |
| product_id     | INTEGER |
| product_name   | TEXT    |
| qty            | INTEGER |
| cost_price     | DOUBLE  |
| selling_price  | DOUBLE  |
| profit         | DOUBLE  |

---

# Business Rules

## Create Product

Required:

* Nama Barang
* Harga Modal
* Harga Jual

Default:

* Stok = 0

---

## Add Stock

Input:

* Barang
* Jumlah
* Catatan

System:

* Menambah stok produk
* Menyimpan histori stok

---

## Checkout

System:

1. Simpan transaksi
2. Simpan detail transaksi
3. Kurangi stok
4. Hitung profit
5. Generate nomor invoice

Format invoice:

INV-YYYYMMDD-XXXX

Contoh:

INV-20260801-0001

---

## Profit Calculation

Profit Item:

profit = (selling_price - cost_price) × qty

Total Profit:

sum(all item profit)

---

# Main Navigation

1. Dashboard
2. Barang
3. Kasir
4. Riwayat
5. Laporan

---

# Folder Structure

lib/

core/
constants/
helpers/
theme/

database/

features/

dashboard/
product/
stock/
cashier/
transaction/
report/
printer/

shared/

widgets/

main.dart

---

# Offline Strategy

Semua data disimpan di SQLite.

Tidak memerlukan:

* API
* Internet
* Server

---

# Future Ready

Database dirancang agar dapat ditambahkan:

* barcode
* cloud sync
* multi user
* multi branch

tanpa perubahan besar struktur tabel.


# App Update System Specification

## Architecture

Flutter
+
SQLite
+
Version Checker API
+
APK Auto Update

---

# Server Requirements

Subdomain:

update.domainanda.com

Contoh:

update.warungkasir.app

---

# File Structure

/apk/

app-v1.0.0.apk

app-v1.1.0.apk

app-v1.2.0.apk

/version.json

---

# Version Endpoint

GET

/version.json

Response:

{
"version": "1.2.0",
"build_number": 12,
"force_update": false,
"apk_url": "https://update.warungkasir.app/apk/app-v1.2.0.apk",
"changelog": [
"Perbaikan laporan",
"Optimasi transaksi",
"Perbaikan bug printer"
]
}

---

# Update Flow

App Start

↓

Check Version

↓

Compare Version

↓

Latest Available?

↓

Yes

↓

Show Update Dialog

↓

Download APK

↓

Install APK

---

# Settings Module

## New Menu

Pengaturan

### General

* Nama Toko
* Alamat Toko
* Nomor Telepon

### Application

* Versi Aplikasi
* Cek Pembaruan

### Data

* Backup Database
* Restore Database

---

# Database Backup

Backup Type:

SQLite Database File

Example:

backup_20260801.db

Storage:

Internal Storage

Shareable:

WhatsApp
Google Drive
Telegram

---

# Restore Database

User dapat memilih file:

*.db

Sistem akan:

1. Validasi file
2. Replace database lama
3. Restart aplikasi

---

# Version Service

Class:

VersionService

Functions:

checkUpdate()

downloadApk()

installApk()

getCurrentVersion()

---

# Flutter Packages

package_info_plus

dio

open_filex

permission_handler

---

# Security

APK hanya dapat diunduh dari domain resmi.

Contoh:

https://update.warungkasir.app

Jika domain tidak valid:

Update dibatalkan.

---

# Release Strategy

Stable Channel

Digunakan seluruh pelanggan.

Beta Channel

Digunakan untuk testing internal.

---

# Operational Flow

Developer

↓

Build APK

↓

Upload APK

↓

Update version.json

↓

User Receive Update Notification

↓

User Install Update

---

# Non Functional Requirements

Version Check Response

< 2 Seconds

APK Download Resume

Supported

Offline App Usage

Supported

Update Without Data Loss

Required
