# 🔍 Laporan Kamus Data & Distribusi Tahunan

## 📅 1. Distribusi Data Per Tahun (Actual Transaction Date)
Data volume berdasarkan kapan transaksi benar-benar terjadi.

### Tabel: `expenses`
| Tahun | Jumlah Data |
| :--- | :--- |
| 2022 | 5 |
| 2023 | 18 |
| 2024 | 482 |
| 2025 | 1 |
| 2026 | 33 |
| 2029 | 2 |
| 2030 | 29 |

### Tabel: `advances`
| Tahun | Jumlah Data |
| :--- | :--- |
| 2024 | 3 |
| 2026 | 15 |
| 2029 | 1 |
| 2030 | 18 |
| NULL | 1 |

### Tabel: `revenues`
| Tahun | Jumlah Data |
| :--- | :--- |
| 2024 | 14 |
| 2025 | 1 |
| 2026 | 2 |

### Tabel: `taxes`
| Tahun | Jumlah Data |
| :--- | :--- |
| 2023 | 1 |
| 2024 | 9 |
| 2025 | 1 |

### Tabel: `dividends`
| Tahun | Jumlah Data |
| :--- | :--- |
| 2024 | 2 |

## 🛠️ 2. Kamus Data (Tipe Kolom untuk Persiapan Excel)

### Struktur Tabel: `advance_item_subcategories`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| advance_item_id | Angka Bulat | YA |
| category_id | Angka Bulat | YA |

### Struktur Tabel: `advance_items`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| advance_id | Angka Bulat | YA |
| category_id | Angka Bulat | YA |
| description | Teks (Max 300) | YA |
| estimated_amount | Angka Desimal | YA |
| revision_no | Angka Bulat | TIDAK |
| evidence_path | Teks (Max 500) | TIDAK |
| evidence_filename | Teks (Max 200) | TIDAK |
| date | Tanggal (YYYY-MM-DD) | TIDAK |
| source | Teks (Max 50) | TIDAK |
| currency | Teks (Max 10) | TIDAK |
| currency_exchange | Angka Desimal | TIDAK |
| status | Teks (Max 20) | TIDAK |
| notes | Teks Panjang | TIDAK |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |

### Struktur Tabel: `advances`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| title | Teks (Max 200) | YA |
| description | Teks Panjang | TIDAK |
| advance_type | Teks (Max 10) | TIDAK |
| user_id | Angka Bulat | YA |
| status | Teks (Max 30) | TIDAK |
| notes | Teks Panjang | TIDAK |
| approved_revision_no | Angka Bulat | TIDAK |
| active_revision_no | Angka Bulat | TIDAK |
| report_year | Angka Bulat | TIDAK |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| updated_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| approved_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |

### Struktur Tabel: `alembic_version`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| version_num | Teks (Max 32) | YA |

### Struktur Tabel: `categories`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| name | Teks (Max 100) | YA |
| code | Teks (Max 10) | YA |
| parent_id | Angka Bulat | TIDAK |
| status | Teks (Max 20) | TIDAK |
| created_by | Angka Bulat | TIDAK |
| sort_order | Angka Bulat | TIDAK |
| main_group | Teks (Max 50) | TIDAK |

### Struktur Tabel: `dividend_settings`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| year | Angka Bulat | YA |
| profit_retained | Angka Desimal | YA |
| opening_cash_balance | Angka Desimal | YA |
| accounts_receivable | Angka Desimal | YA |
| prepaid_tax_pph23 | Angka Desimal | YA |
| prepaid_expenses | Angka Desimal | YA |
| other_receivables | Angka Desimal | YA |
| office_inventory | Angka Desimal | YA |
| other_assets | Angka Desimal | YA |
| accounts_payable | Angka Desimal | YA |
| salary_payable | Angka Desimal | YA |
| shareholder_payable | Angka Desimal | YA |
| accrued_expenses | Angka Desimal | YA |
| share_capital | Angka Desimal | YA |
| retained_earnings_balance | Angka Desimal | YA |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |

### Struktur Tabel: `dividends`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| date | Tanggal (YYYY-MM-DD) | YA |
| name | Teks (Max 150) | YA |
| amount | Angka Desimal | YA |
| recipient_count | Angka Bulat | YA |
| tax_percentage | Angka Desimal | YA |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| report_year | Angka Bulat | TIDAK |

### Struktur Tabel: `expense_subcategories`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| expense_id | Angka Bulat | YA |
| category_id | Angka Bulat | YA |

### Struktur Tabel: `expenses`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| settlement_id | Angka Bulat | YA |
| category_id | Angka Bulat | YA |
| description | Teks (Max 300) | YA |
| amount | Angka Desimal | YA |
| date | Tanggal (YYYY-MM-DD) | YA |
| source | Teks (Max 50) | TIDAK |
| advance_item_id | Angka Bulat | TIDAK |
| revision_no | Angka Bulat | TIDAK |
| currency | Teks (Max 10) | TIDAK |
| currency_exchange | Angka Desimal | TIDAK |
| evidence_path | Teks (Max 500) | TIDAK |
| evidence_filename | Teks (Max 200) | TIDAK |
| status | Teks (Max 20) | TIDAK |
| notes | Teks Panjang | TIDAK |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |

### Struktur Tabel: `manual_combine_groups`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| table_name | Teks (Max 20) | YA |
| report_year | Angka Bulat | YA |
| group_date | Tanggal (YYYY-MM-DD) | YA |
| row_ids_json | Teks Panjang | YA |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |

### Struktur Tabel: `notifications`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| user_id | Angka Bulat | YA |
| actor_id | Angka Bulat | TIDAK |
| action_type | Teks (Max 50) | YA |
| target_type | Teks (Max 50) | YA |
| target_id | Angka Bulat | YA |
| message | Teks Panjang | YA |
| read_status | Boolean (True/False) | TIDAK |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| link_path | Teks (Max 200) | TIDAK |

### Struktur Tabel: `revenues`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| invoice_date | Tanggal (YYYY-MM-DD) | YA |
| description | Teks (Max 300) | YA |
| invoice_value | Angka Desimal | YA |
| currency | Teks (Max 10) | TIDAK |
| currency_exchange | Angka Desimal | TIDAK |
| invoice_number | Teks (Max 50) | TIDAK |
| client | Teks (Max 150) | TIDAK |
| receive_date | Tanggal (YYYY-MM-DD) | TIDAK |
| amount_received | Angka Desimal | TIDAK |
| ppn | Angka Desimal | TIDAK |
| pph_23 | Angka Desimal | TIDAK |
| transfer_fee | Angka Desimal | TIDAK |
| remark | Teks Panjang | TIDAK |
| revenue_type | Teks (Max 32) | YA |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| report_year | Angka Bulat | TIDAK |

### Struktur Tabel: `settlements`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| title | Teks (Max 200) | YA |
| description | Teks Panjang | TIDAK |
| user_id | Angka Bulat | YA |
| settlement_type | Teks (Max 10) | TIDAK |
| status | Teks (Max 20) | TIDAK |
| report_year | Angka Bulat | TIDAK |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| updated_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| completed_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| advance_id | Angka Bulat | TIDAK |

### Struktur Tabel: `taxes`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| date | Tanggal (YYYY-MM-DD) | YA |
| description | Teks (Max 300) | YA |
| transaction_value | Angka Desimal | YA |
| currency | Teks (Max 10) | TIDAK |
| currency_exchange | Angka Desimal | TIDAK |
| ppn | Angka Desimal | TIDAK |
| pph_21 | Angka Desimal | TIDAK |
| pph_23 | Angka Desimal | TIDAK |
| pph_26 | Angka Desimal | TIDAK |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| report_year | Angka Bulat | TIDAK |

### Struktur Tabel: `users`
| Kolom | Tipe Data (Excel) | Wajib? |
| :--- | :--- | :--- |
| id | Angka Bulat | YA |
| username | Teks (Max 80) | YA |
| password_hash | Teks (Max 256) | YA |
| full_name | Teks (Max 150) | YA |
| phone_number | Teks (Max 20) | TIDAK |
| workplace | Teks (Max 100) | TIDAK |
| role | Teks (Max 20) | YA |
| profile_image | Teks (Max 500) | TIDAK |
| last_login | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| created_at | Waktu (YYYY-MM-DD HH:MM) | TIDAK |
| email | Teks (Max 150) | TIDAK |
| google_id | Teks (Max 200) | TIDAK |
| reset_token | Teks (Max 100) | TIDAK |
| reset_token_expiry | Waktu (YYYY-MM-DD HH:MM) | TIDAK |

