# 📊 Analisis Struktur & Data Database (PostgreSQL)

Laporan ini merangkum isi database saat ini untuk panduan migrasi.

## 📋 Daftar Tabel & Jumlah Data
| Nama Tabel | Jumlah Baris |
| :--- | :--- |
| advance_item_subcategories | 4 |
| advance_items | 38 |
| advances | 33 |
| alembic_version | 1 |
| categories | 74 |
| dividend_settings | 3 |
| dividends | 2 |
| expense_subcategories | 9 |
| expenses | 570 |
| manual_combine_groups | 0 |
| notifications | 456 |
| revenues | 17 |
| settlements | 163 |
| taxes | 11 |
| users | 5 |

---

## 👤 Daftar Pengguna (Accounts & Roles)
Informasi akun yang terdaftar di dalam sistem.

| Username | Nama Lengkap | Role | Email |
| :--- | :--- | :--- | :--- |
| manager2 | erlangga2 | manager | - |
| manager1 | Anevril Chairu | manager | diofavianrch@gmail.com |
| mitra1 | Mitra Eksternal 1 | mitra_eks | - |
| staff2 | Staff 2 | staff | - |
| staff1 | Staff 1 | staff | - |

---

## 📅 Rentang Tahun (Actual Transaction Year)
Tahun yang terdeteksi berdasarkan tanggal transaksi asli di dalam data.

| Tabel | Tahun yang Tersedia |
| :--- | :--- |
| expenses | 2022, 2023, 2024, 2025, 2026, 2029, 2030 |
| advances | 2024, 2026, 2029, 2030 |
| revenues | 2024, 2025, 2026 |
| taxes | 2023, 2024, 2025 |
| dividends | 2024 |
| neraca (settings) | 2023, 2024, 2026 |

---

## 💰 Ringkasan Finansial Detail

### 🟢 Revenue (Pendapatan)
- **Total Nominal:** Rp 4,267,052,782.00
- **Tipe pendapatan_lain_lain:** 3 transaksi
- **Tipe pendapatan_langsung:** 14 transaksi

### 🔴 Pajak (Taxes)
- **Total PPN:** Rp 282,300,126.00
- **Total PPh 21:** Rp 25,939,666.00
- **Total PPh 23:** Rp 1,926,469.00
- **Total PPh 26:** Rp 0.00

### 💸 Pengeluaran (Expenses)
- **Total Seluruh Pengeluaran:** Rp 139,909,325,698.33
- **Status pending:** 24 item
- **Status approved:** 546 item

## ⚖️ Komponen Neraca (Balance Sheet)
Data saldo akun neraca dari tabel `dividend_settings`.

**Data Terbaru (Tahun 2026):**
- **Opening Cash:** Rp 0.00
- **Accounts Receivable:** Rp 0.00
- **Share Capital:** Rp 0.00
- **Retained Earnings:** Rp 0.00

## 🛠️ Struktur Kolom Tabel Penting
### Tabel: `revenues`
| Kolom | Tipe Data | Null? |
| :--- | :--- | :--- |
| id | integer | NO |
| invoice_date | date | NO |
| description | character varying | NO |
| invoice_value | double precision | NO |
| currency | character varying | YES |
| currency_exchange | double precision | YES |
| invoice_number | character varying | YES |
| client | character varying | YES |
| receive_date | date | YES |
| amount_received | double precision | YES |
| ppn | double precision | YES |
| pph_23 | double precision | YES |
| transfer_fee | double precision | YES |
| remark | text | YES |
| revenue_type | character varying | NO |
| created_at | timestamp without time zone | YES |
| report_year | integer | YES |

### Tabel: `taxes`
| Kolom | Tipe Data | Null? |
| :--- | :--- | :--- |
| id | integer | NO |
| date | date | NO |
| description | character varying | NO |
| transaction_value | double precision | NO |
| currency | character varying | YES |
| currency_exchange | double precision | YES |
| ppn | double precision | YES |
| pph_21 | double precision | YES |
| pph_23 | double precision | YES |
| pph_26 | double precision | YES |
| created_at | timestamp without time zone | YES |
| report_year | integer | YES |

### Tabel: `expenses`
| Kolom | Tipe Data | Null? |
| :--- | :--- | :--- |
| id | integer | NO |
| settlement_id | integer | NO |
| category_id | integer | NO |
| description | character varying | NO |
| amount | double precision | NO |
| date | date | NO |
| source | character varying | YES |
| advance_item_id | integer | YES |
| revision_no | integer | YES |
| currency | character varying | YES |
| currency_exchange | double precision | YES |
| evidence_path | character varying | YES |
| evidence_filename | character varying | YES |
| status | character varying | YES |
| notes | text | YES |
| created_at | timestamp without time zone | YES |

### Tabel: `dividend_settings`
| Kolom | Tipe Data | Null? |
| :--- | :--- | :--- |
| id | integer | NO |
| year | integer | NO |
| profit_retained | double precision | NO |
| opening_cash_balance | double precision | NO |
| accounts_receivable | double precision | NO |
| prepaid_tax_pph23 | double precision | NO |
| prepaid_expenses | double precision | NO |
| other_receivables | double precision | NO |
| office_inventory | double precision | NO |
| other_assets | double precision | NO |
| accounts_payable | double precision | NO |
| salary_payable | double precision | NO |
| shareholder_payable | double precision | NO |
| accrued_expenses | double precision | NO |
| share_capital | double precision | NO |
| retained_earnings_balance | double precision | NO |
| created_at | timestamp without time zone | YES |

### Tabel: `dividends`
| Kolom | Tipe Data | Null? |
| :--- | :--- | :--- |
| id | integer | NO |
| date | date | NO |
| name | character varying | NO |
| amount | double precision | NO |
| recipient_count | integer | NO |
| tax_percentage | double precision | NO |
| created_at | timestamp without time zone | YES |
| report_year | integer | YES |

### Tabel: `categories`
| Kolom | Tipe Data | Null? |
| :--- | :--- | :--- |
| id | integer | NO |
| name | character varying | NO |
| code | character varying | NO |
| parent_id | integer | YES |
| status | character varying | YES |
| created_by | integer | YES |
| sort_order | integer | YES |
| main_group | character varying | YES |

