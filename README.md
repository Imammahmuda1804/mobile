# RANAHINSIGHT Mobile App

Folder `Mobile` berisi aplikasi Flutter untuk user RANAHINSIGHT. Aplikasi ini dipakai untuk eksplorasi destinasi, pencarian keyword/semantic, detail destinasi, favorite, compare, profile, avatar, dan ulasan user.

## Kegunaan Aplikasi

Mobile app dipakai untuk:

- membuka landing/home mobile;
- melihat rekomendasi destinasi;
- mencari destinasi dengan keyword atau semantic search;
- filter kota dan kategori;
- melihat detail destinasi, gallery, peta topik, rating, dan review;
- memberi ulasan user aplikasi;
- menambah/menghapus favorite;
- compare dua destinasi;
- mengubah profile dan foto profile.

Mobile tidak mengakses database langsung. Semua data diambil dari backend NestJS.

## Syarat Sistem

Disarankan:

- Flutter SDK 3.24 atau lebih baru.
- Dart SDK sesuai Flutter.
- Android Studio atau Android SDK.
- Device Android fisik atau emulator.
- Backend berjalan dan bisa diakses dari device.

Package utama:

- `dio` untuk HTTP.
- `flutter_riverpod` untuk state.
- `go_router` untuk navigasi.
- `flutter_secure_storage` untuk token.
- `cached_network_image` untuk gambar.
- `fl_chart` untuk chart.
- `lucide_icons_flutter` untuk icon.
- `image_picker` untuk avatar.
- `flutter_dotenv` untuk env.

## Instalasi dari Clone Baru

Masuk folder mobile:

```powershell
cd "D:\Kuliah\Ta\New folder\Mobile"
```

Install dependency:

```powershell
flutter pub get
```

Buat atau cek file `.env`:

```env
API_BASE_URL=http://192.168.1.10:3000
```

Untuk emulator Android, backend lokal biasanya bisa memakai:

```env
API_BASE_URL=http://10.0.2.2:3000
```

Untuk device fisik, gunakan IP LAN laptop:

```powershell
ipconfig
```

Cari IPv4 Wi-Fi, lalu pakai:

```env
API_BASE_URL=http://<IPv4-Laptop>:3000
```

Pastikan:

- laptop dan HP satu jaringan;
- firewall Windows mengizinkan port 3000 private network;
- backend berjalan di laptop;
- URL bisa dibuka dari browser HP.

## Menjalankan Aplikasi

Cek device:

```powershell
flutter devices
```

Run:

```powershell
flutter run -d <device_id>
```

Contoh:

```powershell
flutter run -d IFWGMR8LCMLJBMZH
```

Jika memakai USB dan ingin akses backend `localhost:3000` dari HP, gunakan adb reverse:

```powershell
adb reverse tcp:3000 tcp:3000
```

Jika `adb` tidak dikenali, gunakan path lengkap Android SDK platform-tools atau tambahkan ke PATH.

## Struktur Folder

| Path | Kegunaan |
| --- | --- |
| `lib/main.dart` | Entrypoint Flutter. |
| `lib/app/` | Root app, router, config, dan theme. |
| `lib/app/app.dart` | Bootstrap awal, startup splash, dan MaterialApp router. |
| `lib/app/router.dart` | Route dan bottom navigation shell. |
| `lib/app/config/` | Env dan endpoint backend. |
| `lib/app/theme/` | Warna, typography, spacing, dan ThemeData. |
| `lib/core/network/` | Dio client, token interceptor, dan result wrapper. |
| `lib/core/storage/` | Secure storage untuk token. |
| `lib/core/utils/` | Formatter dan helper URL gambar. |
| `lib/core/widgets/` | Widget reusable seperti button, text field, card, loader, error panel, image preview, select sheet. |
| `lib/core/constants/` | Konstanta kategori destinasi. |
| `lib/features/auth/` | Login, register, auth repository, auth controller, dan model auth. |
| `lib/features/home/` | Home mobile dan repository trending. |
| `lib/features/search/` | Search page, search repository, model destination summary, filter. |
| `lib/features/destination_detail/` | Detail destinasi, model detail, repository, review, gallery, topic insight. |
| `lib/features/compare/` | Compare page, repository, dan model compare. |
| `lib/features/profile/` | Profile, favorite, avatar, repository, dan model favorite. |
| `assets/images/` | Asset gambar lokal. |
| `android/` | Project Android native, Gradle, manifest, dan konfigurasi build. |
| `test/` | Test Flutter. |
| `MOBILE_CODE_FLOW.md` | Dokumentasi flow source code mobile. |

## Flow Aplikasi

1. `main.dart` menjalankan Flutter.
2. `app.dart` memuat env dan restore auth.
3. `router.dart` menentukan halaman aktif.
4. UI membaca provider Riverpod.
5. Repository memanggil backend lewat Dio.
6. Model Dart memetakan response JSON.
7. UI menampilkan loading, error, atau data.

## Flow Network

File utama:

- `lib/core/network/dio_client.dart`
- `lib/core/network/token_interceptor.dart`
- `lib/core/storage/secure_storage_service.dart`
- `lib/app/config/env.dart`

Alur:

1. `Env` membaca `API_BASE_URL`.
2. `dioProvider` membuat Dio dengan base URL.
3. `TokenInterceptor` mengambil token dari secure storage.
4. Request dikirim ke backend.
5. Response dipetakan oleh repository.

## Flow Auth

File utama:

- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/data/auth_controller.dart`
- `lib/features/auth/presentation/login_page.dart`
- `lib/features/auth/presentation/register_page.dart`

Alur:

1. User login/register.
2. Repository memanggil backend.
3. Token disimpan di secure storage.
4. Auth controller menyimpan state user.
5. Router dan UI memakai state ini untuk auth gate.

## Flow Search

File utama:

- `lib/features/search/presentation/search_page.dart`
- `lib/features/search/data/search_repository.dart`
- `lib/features/search/data/search_models.dart`

Alur:

1. User mengetik query.
2. User memilih mode keyword/semantic.
3. User bisa filter kota/kategori.
4. Repository memanggil backend.
5. Result ditampilkan sebagai destination card.

## Flow Detail Destinasi

File utama:

- `lib/features/destination_detail/presentation/destination_detail_page.dart`
- `lib/features/destination_detail/data/destination_repository.dart`
- `lib/features/destination_detail/data/destination_models.dart`

Alur:

1. User membuka detail.
2. Provider mengambil data detail.
3. Repository memanggil backend.
4. Model memetakan topic group, topic sentiment, review, gallery, dan rating.
5. UI menampilkan hero, metric, gallery, topic insight, review, dan form ulasan.

## Flow Compare

File utama:

- `lib/features/compare/presentation/compare_page.dart`
- `lib/features/compare/data/compare_repository.dart`
- `lib/features/compare/data/compare_models.dart`

Alur:

1. User memilih dua destinasi.
2. Repository meminta hasil compare ke backend.
3. Model compare memetakan metric, sentiment, topik, dan ringkasan.
4. UI menampilkan panel perbandingan.

## Flow Profile dan Favorite

File utama:

- `lib/features/profile/presentation/profile_page.dart`
- `lib/features/profile/data/profile_repository.dart`
- `lib/features/profile/data/profile_models.dart`

Alur:

1. User membuka profile/favorite.
2. App mengambil data user dan favorite.
3. User bisa edit profile, upload avatar, filter favorite, remove favorite, dan compare dari tray.

## Validasi Setelah Clone

```powershell
cd "D:\Kuliah\Ta\New folder\Mobile"
flutter pub get
flutter analyze
flutter test
flutter run -d <device_id>
```

Manual check:

- startup splash tampil;
- login/register;
- home trending;
- search keyword/semantic;
- filter kota/kategori;
- detail destinasi;
- favorite add/remove/check;
- review submit;
- compare;
- profile update dan avatar.

## Troubleshooting

### Backend tidak terhubung di HP

Periksa:

- `API_BASE_URL` memakai IP laptop, bukan `localhost`;
- HP dan laptop satu Wi-Fi;
- backend hidup;
- firewall membuka port 3000;
- URL backend bisa dibuka dari browser HP.

### `INSTALL_FAILED_USER_RESTRICTED`

Aktifkan izin install via USB di pengaturan developer options Android, lalu coba ulang `flutter run`.

### Gradle daemon crash

Coba:

```powershell
flutter clean
flutter pub get
cd android
.\gradlew --stop
cd ..
flutter run
```

Jika ada `hs_err_pid*.log`, itu log crash JVM dan aman dihapus setelah tidak dibutuhkan.

### Gambar tidak tampil

Periksa:

- URL gambar dari backend bisa dibuka;
- backend menyajikan `/uploads`;
- `resolveImageUrl` menerima base URL yang benar;
- permission internet Android tersedia di `AndroidManifest.xml`.
