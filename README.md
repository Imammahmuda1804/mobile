# RANAHINSIGHT Mobile

Aplikasi Flutter mobile untuk user RANAHINSIGHT. App ini memakai backend yang sama dengan web dan ditargetkan berjalan di HP fisik Android lewat USB debugging.

## Setup Awal

1. Pastikan Flutter SDK dan Android SDK sudah terpasang.
2. Aktifkan Developer Options dan USB debugging di HP.
3. Sambungkan HP ke laptop lewat USB, lalu izinkan debugging dari prompt Android.
4. Ubah `API_BASE_URL` di `.env` menjadi IP LAN komputer backend, bukan `localhost`.
5. Jalankan backend agar bisa diakses dari HP, misalnya bind ke `0.0.0.0`.

```bash
flutter devices
flutter pub get
flutter run -d <device_id>
```

## Catatan Koneksi API

HP fisik tidak bisa mengakses `localhost` laptop. Gunakan IP Wi-Fi/LAN laptop, contoh:

```txt
API_BASE_URL=http://192.168.1.10:3000
```

Jika request gagal, cek firewall Windows, jaringan HP/laptop, dan pastikan backend mendengar koneksi dari jaringan lokal.

## Struktur

Project memakai struktur feature-first:

- `app/`: router, theme, dan konfigurasi global.
- `core/`: network, storage, error mapper, widget reusable, utility.
- `features/`: auth, home, search, compare, detail destinasi, profile/favorit.
