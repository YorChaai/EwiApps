# Panduan Keamanan Deploy (Anti Crack / Anti Bajak / Anti Ubah-Ubah)

Dokumen ini dibuat untuk membantu Anda mencatat strategi keamanan sebelum deployment aplikasi `Flutter + Python (Flask)`.

Fokus:
- Mencegah akses tidak sah (jailbreak dalam konteks bypass role/hak akses).
- Mengurangi risiko aplikasi di-crack, dibajak, atau dimodifikasi.
- Menentukan tool yang dipakai dan apa tindakan setelah hasil tool keluar.

---

## 1. Definisi Singkat “Jailbreak” di Proyek Anda

Di konteks aplikasi bisnis seperti ini, “jailbreak” umumnya berarti:
- User mem-bypass role (staff jadi bisa akses data manager/user lain).
- User memodifikasi request API agar bisa ubah status data tidak semestinya.
- User membaca/mengubah data lewat celah otorisasi (IDOR).
- Biner aplikasi diubah (tamper/crack) lalu dipakai ulang.

Jadi fokus utama Anda bukan cuma “root/jailbreak device”, tapi juga:
- API security
- Otorisasi per-role
- Integritas aplikasi saat didistribusikan

---

## 2. Peta Risiko Utama

| Risiko | Dampak | Prioritas |
|---|---|---|
| IDOR (akses data milik user lain via ganti ID) | Bocor data, ubah data orang lain | Tinggi |
| Role bypass (endpoint manager dipakai staff) | Kontrol approval rusak | Tinggi |
| Token abuse (token bocor/expired terlalu lama) | Account takeover | Tinggi |
| File upload abuse | Malware/DoS/storage abuse | Tinggi |
| API brute force/login spam | Ganggu layanan, tebak password | Tinggi |
| App tampering (apk/exe dimodifikasi) | Logika klien dibypass | Sedang-Tinggi |
| Reverse engineering | Bocor endpoint/flow internal | Sedang |

---

## 3. Tool yang Disarankan (Tanpa Ubah Kode Dulu)

## 3.1 Python / Backend (Flask)

| Tool | Fungsi | Kapan Dipakai |
|---|---|---|
| `pip-audit` | Scan dependency rentan (CVE) | Sebelum build/release |
| `bandit` | Static security scan source Python | Saat QA/security check |
| `semgrep` | Rule-based scan bug/security patterns | Saat review berkala |
| `detect-secrets` / `gitleaks` | Deteksi secret/API key bocor | Sebelum commit/release |
| `safety` (opsional) | Cek kerentanan package Python | Pelengkap `pip-audit` |

Contoh perintah:
```bash
pip-audit
bandit -r backend -x backend/venv,backend/__pycache__,backend/migrations
semgrep scan --config auto backend
detect-secrets scan > .secrets.baseline
```

## 3.2 Flutter / Frontend

| Tool/Mode | Fungsi | Kapan Dipakai |
|---|---|---|
| `flutter analyze` | Cek issue coding/statik dasar | Tiap perubahan |
| Build release + obfuscation | Menyulitkan reverse engineering | Saat generate build rilis |
| App signing (Windows/Android/iOS) | Menjaga integritas biner | Saat distribusi |
| SAST scan (Semgrep) untuk Dart | Cari pattern insecure di Dart | Sebelum release |

Contoh build obfuscation:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

Catatan:
- Obfuscation bukan anti-hack total, hanya memperberat reverse engineering.

## 3.3 Infrastruktur Deploy

| Tool | Fungsi | Kapan Dipakai |
|---|---|---|
| Nginx/Caddy (reverse proxy + TLS) | HTTPS, hardening header, rate limit dasar | Production wajib |
| Fail2ban | Blok IP brute force | Production |
| WAF (Cloudflare/ModSecurity) | Filter traffic berbahaya | Production internet-facing |
| Trivy (container/image scan) | Scan image dependency/OS CVE | Jika pakai Docker |

---

## 4. Library Keamanan yang Relevan (Saat Nanti Siap Ubah Kode)

Bagian ini untuk catatan future plan.

## 4.1 Backend Flask

| Library | Kegunaan |
|---|---|
| `Flask-Limiter` | Rate limit login/API sensitif |
| `Flask-Talisman` | Security headers (CSP/HSTS/X-Frame-Options, dll) |
| `bcrypt` / `passlib` | Hash password kuat |
| `PyJWT` (dengan expiry ketat + rotation policy) | Token auth aman |
| `marshmallow` / schema validation | Validasi input payload |

## 4.2 Flutter

| Area | Catatan |
|---|---|
| Root/Jailbreak detection | Bisa ditambahkan jika target utama mobile dan risiko tinggi |
| SSL pinning | Untuk cegah MITM di jaringan tidak terpercaya |
| Secure storage | Simpan token di secure storage, bukan plain file |
| Tamper/root policy | Mis. blok fitur sensitif bila perangkat terdeteksi tidak aman |

Catatan penting:
- Untuk desktop Windows, kontrol paling efektif adalah code signing + server-side authorization ketat.
- Jangan bergantung pada proteksi client saja.

---

## 5. Setelah Tool Dipakai, Harus Diapain?

Ini bagian yang paling penting.

## 5.1 Alur Tindak Lanjut Hasil Scan

1. Klasifikasi temuan:
- `Critical/High`: wajib diperbaiki sebelum release.
- `Medium`: boleh release jika ada mitigasi sementara + tiket fix.
- `Low`: backlog terjadwal.

2. Validasi temuan:
- Pisahkan false positive vs temuan real.

3. Buat tiket:
- Satu temuan = satu tiket.
- Isi: file, risiko, exploit path, owner, target selesai.

4. Retest:
- Jalankan tool ulang setelah fix.

5. Simpan bukti:
- Simpan report scan per release untuk audit internal.

## 5.2 Gate “Boleh Deploy”

Checklist minimum:
- [ ] Tidak ada `Critical`.
- [ ] Tidak ada `High` di auth/authorization/upload.
- [ ] Dependency CVE high sudah ditambal atau ada compensating control jelas.
- [ ] Endpoint role-sensitive sudah diuji manual (manager/staff/mitra).
- [ ] Build release sudah signed.
- [ ] TLS aktif dan endpoint non-HTTPS ditutup.

---

## 6. Hardening Praktis yang Paling Berdampak

Prioritas implementasi (urutan praktis):

1. **Authorization server-side ketat**
- Setiap endpoint cek ownership + role.
- Jangan percaya data dari client.

2. **Rate limit**
- Login, notifikasi, export, endpoint berat.

3. **Token policy**
- Access token short-lived.
- Refresh token policy jelas.
- Revoke token saat logout/reset password.

4. **Upload hardening**
- Whitelist extension.
- Verifikasi MIME.
- Batasi ukuran.
- Simpan filename random.

5. **Security headers + TLS**
- HSTS, X-Content-Type-Options, X-Frame-Options, CSP dasar.

6. **Logging & monitoring**
- Log event sensitif: login fail, reject/approve, perubahan role, export massal.
- Alert jika ada pola anomali.

---

## 7. Catatan Khusus Anti Crack/Bajak Aplikasi

Tidak ada proteksi 100% di sisi client, tapi Anda bisa menaikkan biaya serangan:

- Pakai build `release` saja untuk distribusi.
- Obfuscate simbol build Flutter.
- Sign semua artefak installer/app.
- Simpan logic sensitif di backend, bukan di frontend.
- Endpoint backend wajib verifikasi hak akses tiap request.
- Hindari hardcode secret di aplikasi client.

Untuk Windows distribution:
- Gunakan code signing certificate untuk installer/exe.
- Distribusi lewat channel resmi (satu sumber update).
- Verifikasi checksum/hash release internal.

---

## 8. Rencana Eksekusi 30 Hari (Tanpa Chaos)

Minggu 1:
- Jalankan `pip-audit`, `bandit`, `semgrep`, `detect-secrets`.
- Buat baseline temuan.

Minggu 2:
- Fix temuan high di auth/authorization/upload.
- Tambahkan rate limit di endpoint kritikal (saat siap ubah kode).

Minggu 3:
- Hardening deploy: TLS, reverse proxy, logging, fail2ban.
- Uji manual role bypass + IDOR.

Minggu 4:
- Retest full.
- Freeze release candidate.
- Simpan security report sebagai artefak release.

---

## 9. Template Catatan Risiko (Siap Pakai)

| ID | Risiko | Modul | Dampak | Kemungkinan | Prioritas | Aksi | Owner | Due Date | Status |
|---|---|---|---|---|---|---|---|---|---|
| R-001 | IDOR detail settlement | Backend `routes/settlements.py` | Data bocor/ubah | Sedang | Tinggi | Tambah ownership check ketat | Backend | yyyy-mm-dd | Open |
| R-002 | Token expiry terlalu panjang | Auth | Account takeover | Sedang | Tinggi | Perketat expiry + revoke flow | Backend | yyyy-mm-dd | Open |
| R-003 | Build belum obfuscate/signed | Frontend release | Mudah reverse/tamper | Sedang | Sedang | Release policy + signing | DevOps | yyyy-mm-dd | Open |

---

## 10. Kesimpulan untuk Keputusan Anda Sekarang

Kalau saat ini Anda masih tahap catat (belum ubah kode), langkah paling tepat:
- Jalankan tool scan dulu.
- Buat risk register dari hasil scan + uji manual role.
- Tentukan gate deploy.

Jadi keputusan deploy nanti berbasis data, bukan feeling.

