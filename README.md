```bash
# 1. Jalankan Backend (Flask)
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend'
.\venv\Scripts\activate 
python app.py

# 2. Jalankan Frontend Desktop (Flutter)
cd "D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend" 
flutter run -d windows

# 3. Jalankan Cloudflare (Akses internet HP tanpa WiFi, port 5000)
cloudflared tunnel --url http://127.0.0.1:5000

# Opsional: Jika run di HP via Cloudflare, ubah baseUrl di lib/services/api_service.dart
# cd "D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend" && flutter run
```
