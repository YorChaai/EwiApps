# Daftar Tool Keamanan + Prioritas Bintang (1-3)

Skala prioritas:
- `★★★` = wajib dulu (fondasi sebelum deploy internet-facing).
- `★★` = sangat disarankan (fase penguatan).
- `★` = opsional/lanjutan (tetap berguna).

---

## A. Flutter / Client Build

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 1 | `flutter analyze` | ★★★ | Static analysis utama Flutter. |
| 2 | `dart analyze` | ★★ | Analisis Dart langsung untuk modul tertentu. |
| 3 | `flutter test` | ★★★ | Regression test agar fix keamanan tidak merusak fitur. |
| 4 | `flutter build --release --obfuscate --split-debug-info` | ★★★ | Mengurangi kemudahan reverse engineering. |
| 5 | Android App Signing (`jarsigner`/Play App Signing) | ★★★ | Menjamin APK/AAB resmi dan tidak dimodifikasi. |
| 6 | Windows code signing (`signtool`) | ★★★ | Menjamin installer/exe resmi di Windows. |
| 7 | iOS signing/provisioning | ★★★ | Integritas build iOS resmi. |
| 8 | ProGuard/R8 mapping management | ★★ | Pengelolaan simbol obfuscation untuk debugging aman. |

---

## B. Python / Backend SAST & Dependency

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 9 | `pip-audit` | ★★★ | Scan CVE dependency Python. |
| 10 | `bandit` | ★★★ | Security static scan source Python. |
| 11 | `semgrep` | ★★★ | Rule-based scan security lintas bahasa. |
| 12 | `safety` | ★★ | Alternatif/pendamping CVE scanner Python. |
| 13 | `ruff` | ★★ | Lint cepat; bantu kurangi bug risk. |
| 14 | `pylint` | ★ | Kualitas kode tambahan. |
| 15 | `mypy` | ★★ | Type-checking untuk cegah bug logic. |

---

## C. Secret Scanning

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 16 | `gitleaks` | ★★★ | Deteksi secret bocor di repo/history. |
| 17 | `detect-secrets` | ★★★ | Baseline secret scan sebelum commit/release. |
| 18 | `trufflehog` | ★★ | Scan kebocoran secret historis mendalam. |
| 19 | GitHub Secret Scanning | ★★ | Deteksi secret otomatis di platform git. |

---

## D. API Security Testing (DAST/Pentest)

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 20 | `OWASP ZAP` | ★★★ | DAST scan endpoint/API untuk attack umum. |
| 21 | `Burp Suite` | ★★★ | Pentest manual (authz, IDOR, tampering). |
| 22 | `Postman`/`Insomnia` test collection | ★★★ | Uji role, token, dan skenario workflow API. |
| 23 | `sqlmap` | ★★ | Uji SQL injection pada endpoint raw/rentan. |
| 24 | `nuclei` | ★★ | Scan template kerentanan cepat. |

---

## E. Load/Abuse & Reliability

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 25 | `k6` | ★★ | Load test + abuse scenario endpoint sensitif. |
| 26 | `Locust` | ★★ | Simulasi user konkuren dan stress flow bisnis. |
| 27 | `hey`/`wrk` | ★ | Benchmark ringan cepat. |

---

## F. Reverse Proxy, WAF, Hardening Network

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 28 | `Nginx` | ★★★ | TLS termination, security headers, rate limit dasar. |
| 29 | `Caddy` | ★★★ | Alternatif Nginx dengan TLS otomatis. |
| 30 | Cloudflare WAF | ★★★ | Proteksi edge traffic internet-facing. |
| 31 | ModSecurity + OWASP CRS | ★★ | WAF self-hosted rule set OWASP. |
| 32 | `fail2ban` | ★★★ | Blok brute-force dari log auth gagal. |
| 33 | `ufw`/`iptables`/Windows Firewall hardening | ★★★ | Menutup port yang tidak diperlukan. |
| 34 | `nmap` | ★★ | Audit port service yang terbuka. |

---

## G. Container / Host Vulnerability

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 35 | `Trivy` | ★★★ | Scan image/container/dependency OS. |
| 36 | `Grype` | ★★ | Alternatif scanner image/filesystem CVE. |
| 37 | `Docker Bench` | ★★ | Audit hardening konfigurasi Docker host. |

---

## H. CI/CD Security Gate

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 38 | GitHub Actions / GitLab CI Security Jobs | ★★★ | Otomasi scan wajib sebelum merge/deploy. |
| 39 | Dependabot / Renovate | ★★★ | Update dependency otomatis + PR patch CVE. |
| 40 | Snyk | ★★ | Scan dependency/container + policy management. |
| 41 | SonarQube (Security Rules) | ★★ | Analisis kualitas + hotspot keamanan. |
| 42 | pre-commit hooks | ★★★ | Memaksa lint/secret scan sebelum commit. |

---

## I. Monitoring, Logging, Incident

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 43 | `Sentry` | ★★★ | Error monitoring real-time (frontend/backend). |
| 44 | `ELK` / OpenSearch | ★★ | Log terpusat untuk audit/forensik. |
| 45 | `Loki + Grafana` | ★★ | Observability + alert dari log/metrik. |
| 46 | `Wazuh` | ★★ | SIEM + host security monitoring. |
| 47 | Prometheus + Alertmanager | ★★ | Alert service anomaly (CPU, latency, error spike). |

---

## J. Secrets & Key Management

| No | Tool | Prioritas | Fungsi |
|---|---|---|---|
| 48 | HashiCorp Vault | ★★★ | Penyimpanan secret terpusat + rotation. |
| 49 | 1Password Secrets Automation | ★★ | Manajemen secret untuk tim kecil/menengah. |
| 50 | AWS Secrets Manager / GCP Secret Manager / Azure Key Vault | ★★★ | Secret management native cloud. |

---

## K. Prioritas Implementasi Praktis (Urutan Realistis)

### Tahap 1 (Wajib sebelum deploy publik)
- `flutter analyze`, `flutter test`, release obfuscate + signing.
- `pip-audit`, `bandit`, `semgrep`.
- `gitleaks`/`detect-secrets`.
- `Nginx/Caddy + TLS`, `fail2ban`, firewall hardening.
- CI gate dasar (scan wajib lulus).

### Tahap 2 (Penguatan)
- `OWASP ZAP` + pentest manual Burp.
- `Trivy`/`Grype`.
- WAF (Cloudflare atau ModSecurity).
- Monitoring (`Sentry` + log terpusat).

### Tahap 3 (Lanjutan)
- SIEM penuh (`Wazuh`), policy engine, audit otomatis lanjutan.
- Secret manager enterprise + rotation terjadwal.

---

## L. Catatan Penting

- Tidak ada tool tunggal yang membuat aplikasi “anti-hack 100%”.
- Kombinasi terbaik adalah:
  1. Otorisasi backend ketat,
  2. scanning otomatis,
  3. hardening infrastruktur,
  4. monitoring dan respons insiden.

