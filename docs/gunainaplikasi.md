Terminal backend/server
cd backend
venv\Scripts\python.exe app.py

Terminal Flutter Android
Contoh untuk HP:
cd frontend
flutter run -d android --dart-define=API_BASE_URL=https://URL-CLOUDFLARE/api

Terminal Cloudflare Tunnel
Di folder yang ada cloudflared.exe:
cloudflared.exe tunnel --url http://localhost:5000
Nanti Cloudflare akan kasih URL seperti:

https://random-name.trycloudflare.com
Lalu URL itu dipakai di Flutter:

https://random-name.trycloudflare.com/api
Jadi urutan kerjanya:

jalankan backend dulu
jalankan cloudflared
copy URL trycloudflare
jalankan Flutter Android dengan --dart-define=API_BASE_URL=.../api
Contoh lengkap:

flutter run -d android --dart-define=API_BASE_URL=https://abc-def-ghi.trycloudflare.com/api
Catatan penting:

kalau URL Cloudflare berubah, app harus dijalankan ulang dengan URL baru
backend tetap harus hidup di laptop
Cloudflare Tunnel tidak menggantikan backend, cuma membuka akses dari luar/local HP ke backend kamu