# Cloudflare Tunnel

Jalankan dari root project:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\cloudflare\start_tunnel.ps1
```

Jika backend memakai port lain:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\cloudflare\start_tunnel.ps1 -Url http://localhost:5001
```

Urutan pakai:

1. Jalankan backend `MiniProjectKPI_EWI`.
2. Jalankan script tunnel di atas.
3. Copy URL `https://....trycloudflare.com`.
4. Di aplikasi Android, isi `Server URL` menjadi `https://....trycloudflare.com/api`.
