# Dokumentasi Flow Kode Mobile RANAHINSIGHT

Dokumen ini menjelaskan struktur folder `Mobile`, alur kerja kode, dan fungsi komentar Bahasa Indonesia yang ditambahkan pada bagian core aplikasi Flutter. Target pembaca adalah orang yang belum terbiasa memakai Flutter, Riverpod, GoRouter, Dio, secure storage, atau pola feature-based mobile app.

## Peran Folder Mobile

Folder `Mobile` adalah aplikasi Flutter untuk pengguna RANAHINSIGHT. Tugasnya:

1. menampilkan home, search, detail destinasi, compare, profile, favorite, login, dan register;
2. memanggil backend NestJS melalui Dio;
3. menyimpan token login di secure storage;
4. menampilkan data destinasi, sentimen, topic group, review, favorite, dan compare;
5. memakai design system mobile yang konsisten dengan web.

Mobile tidak memanggil service Python `Model` secara langsung. Semua data NLP sudah diproses dan disimpan oleh backend.

## Struktur Folder Utama

### `Mobile/lib/main.dart`

Posisi pada flow: entrypoint aplikasi Flutter.

Kegunaan:
- memastikan binding Flutter siap;
- memuat `.env`;
- menjalankan `ProviderScope`;
- membuka `RanahInsightApp`.

Alur:
1. `main()` dipanggil Android/iOS.
2. `.env` dibaca agar `API_BASE_URL` tersedia.
3. Riverpod `ProviderScope` dipasang.
4. App root berjalan.

### `Mobile/lib/app/app.dart`

Posisi pada flow: root widget aplikasi.

Kegunaan:
- menjalankan bootstrap awal;
- restore session user dari token tersimpan;
- memasang theme;
- memasang router;
- menampilkan startup splash sampai bootstrap selesai.

Komentar penting:
- `appBootstrapProvider`: menjalankan restore session sebelum app utama ditampilkan.
- `RanahInsightApp`: root widget yang memasang theme, router, dan startup splash.

Alur:
1. `appBootstrapProvider` memanggil `AuthController.restoreSession`.
2. Jika token valid, user dimuat dari backend.
3. Selama proses ini, `AppStartupSplash` tampil.
4. Setelah selesai, router menampilkan halaman utama.

### `Mobile/lib/app/router.dart`

Posisi pada flow: navigasi utama aplikasi.

Kegunaan:
- mendefinisikan route `home`, `search`, `compare`, `profile`, `destination/:slug`, `login`, dan `register`;
- membuat shell tab utama;
- menjaga bottom navigation dan brand bar mobile.

Komentar penting:
- `appRouterProvider`: router utama untuk tab shell, detail, auth, dan deep link query.
- `MainShell`: shell utama yang menampilkan brand bar dan bottom navigation.
- `_MobileBrandBar`: brand bar untuk identitas RANAHINSIGHT.

Alur:
1. GoRouter membaca lokasi saat ini.
2. Route tab dibungkus oleh `MainShell`.
3. Detail destinasi dan auth berada di luar shell tab.
4. Query param seperti `q`, `d1`, dan `d2` dipakai untuk search/compare.

### `Mobile/lib/app/config`

Posisi pada flow: konfigurasi environment dan endpoint.

File penting:
- `env.dart`: membaca `API_BASE_URL` dari `.env`.
- `api_endpoints.dart`: daftar endpoint backend.

Kegunaan:
- memusatkan URL backend;
- mencegah string endpoint tersebar di banyak repository.

### `Mobile/lib/app/theme`

Posisi pada flow: design system aplikasi.

File penting:
- `app_colors.dart`: token warna utama.
- `app_text_styles.dart`: token typography.
- `app_spacing.dart`: token spacing.
- `app_theme.dart`: theme Material.

Kegunaan:
- menjaga warna orange, blue, slate, success, warning, danger konsisten;
- mengurangi styling manual berulang.

## Core Layer

### `Mobile/lib/core/network`

Posisi pada flow: koneksi HTTP ke backend.

File penting:
- `dio_client.dart`
- `token_interceptor.dart`
- `api_result.dart`

Komentar penting:
- `secureStorageProvider`: provider penyimpanan aman untuk token auth.
- `dioProvider`: provider Dio utama untuk semua request backend.
- `responseData`: membaca response backend sebagai map yang aman.
- `unwrapData`: mengambil payload `data` dari response yang dibungkus interceptor backend.
- `TokenInterceptor`: memasang access token dan menangani sesi kadaluarsa.

Alur request:
1. Repository membaca `dioProvider`.
2. Dio memakai `Env.apiBaseUrl`.
3. `TokenInterceptor` memasang header token jika ada.
4. Repository memanggil endpoint backend.
5. Response dibuka dengan `unwrapData`.
6. Error Dio diubah menjadi `AppException`.

### `Mobile/lib/core/storage`

File penting:
- `secure_storage_service.dart`

Kegunaan:
- menyimpan access token dan refresh token;
- membaca token saat bootstrap;
- menghapus token saat logout atau token invalid.

### `Mobile/lib/core/errors`

File penting:
- `app_exception.dart`
- `error_mapper.dart`

Kegunaan:
- membuat bentuk error aplikasi yang sederhana;
- mengubah error Dio menjadi pesan yang bisa ditampilkan ke user.

### `Mobile/lib/core/widgets`

Posisi pada flow: reusable UI component.

File penting:
- `app_button.dart`
- `app_text_field.dart`
- `app_select_sheet.dart`
- `app_screen_scaffold.dart`
- `app_error_panel.dart`
- `app_inline_loader.dart`
- `app_startup_splash.dart`
- `destination_card.dart`
- `image_preview.dart`
- `metric_card.dart`
- `info_pill.dart`
- `icon_metric_card.dart`
- `empty_state.dart`
- `loading_skeleton.dart`

Kegunaan:
- memberi komponen UI yang konsisten;
- mengurangi duplikasi layout;
- memastikan loading, empty, error, card, select, dan preview gambar punya pola yang sama.

## Feature Auth

Folder:
- `Mobile/lib/features/auth`

File penting:
- `data/auth_models.dart`
- `data/auth_repository.dart`
- `data/auth_controller.dart`
- `presentation/login_page.dart`
- `presentation/register_page.dart`

Komentar penting:
- `AuthState`: state autentikasi yang dibaca UI dan bootstrap app.
- `AuthController`: controller Riverpod untuk login, register, restore session, dan logout.
- `restoreSession`: mengambil token tersimpan lalu memuat user aktif dari backend.
- `AuthRepository`: repository API untuk login, register, dan user aktif.

Alur login:
1. User mengisi form login.
2. `LoginPage` memanggil `AuthController.login`.
3. `AuthController` memanggil `AuthRepository.login`.
4. Token disimpan ke secure storage.
5. State berubah menjadi authenticated.
6. Router bisa membawa user ke halaman utama/profile.

Alur restore session:
1. App start memanggil `appBootstrapProvider`.
2. `AuthController.restoreSession` membaca access token.
3. Jika token ada, repository memanggil `/api/users/me`.
4. Jika sukses, user masuk otomatis.
5. Jika gagal, token dihapus.

## Feature Home

Folder:
- `Mobile/lib/features/home`

File penting:
- `data/home_repository.dart`
- `presentation/home_page.dart`

Komentar penting:
- `HomeRepository`: repository API untuk rekomendasi dan trending di home.
- `homeTrendingProvider`: memuat destinasi rekomendasi untuk home.
- `HomePage`: halaman home mobile dengan hero, prompt, insight, dan rekomendasi.

Alur:
1. `homeTrendingProvider` memanggil `HomeRepository.fetchTrending`.
2. Home menampilkan hero, prompt search, insight, dan rekomendasi.
3. Klik CTA search mengarah ke `/search?q=...`.
4. Klik destinasi mengarah ke `/destination/:slug`.

## Feature Search

Folder:
- `Mobile/lib/features/search`

File penting:
- `data/search_models.dart`
- `data/search_repository.dart`
- `presentation/search_page.dart`

Komentar penting:
- `SearchRepository`: repository API untuk keyword search, semantic search, kota, history, dan rekomendasi.
- `_readList`: membaca list dari response backend yang bisa terbungkus.
- `DestinationSummary`: model ringkas destinasi untuk search, home, compare, dan favorite card.
- `TopicFilter`: model topik untuk metadata/filter.
- `citiesProvider`: memuat daftar kota.
- `searchHistoryProvider`: memuat riwayat search hanya untuk user login.
- `SearchPage`: halaman search mobile untuk keyword, semantic, kota, kategori, dan hasil destinasi.
- `_search`: menjalankan pencarian sesuai mode dan filter aktif.

Alur keyword search:
1. User mengetik query atau memilih filter.
2. `_search` memanggil `SearchRepository.searchKeyword`.
3. Repository memanggil `/api/destinations`.
4. Response diubah menjadi `DestinationSummary`.
5. UI menampilkan kartu destinasi.

Alur semantic search:
1. User mengaktifkan mode semantic.
2. `_search` memanggil `SearchRepository.searchSemantic`.
3. Repository POST ke `/api/search`.
4. Backend menjalankan embedding dan pgvector.
5. Hasil tampil dengan score/top topic.

## Feature Destination Detail

Folder:
- `Mobile/lib/features/destination_detail`

File penting:
- `data/destination_models.dart`
- `data/destination_repository.dart`
- `presentation/destination_detail_page.dart`

Komentar penting:
- `DestinationRepository`: repository API untuk detail destinasi, favorit, topik review, dan submit review.
- `DestinationDetail`: model detail destinasi lengkap.
- `TopicGroupInsight`: model topic group luas untuk peta topik.
- `ScrapedTopicReview`: model review scraping saat membuka topik.
- `destinationDetailProvider`: memuat detail destinasi berdasarkan slug.
- `DestinationDetailPage`: halaman detail destinasi dengan hero, metrik, topik, galeri, favorite, dan review.
- `_checkFavorite`: mengecek status favorit user untuk destinasi aktif.
- `_toggleFavorite`: menambah atau menghapus favorit dengan rollback saat gagal.
- `_showTopicReviews`: membuka bottom sheet review berdasarkan topik atau topic group.

Alur:
1. Router membuka `/destination/:slug`.
2. `destinationDetailProvider` memanggil `DestinationRepository.fetchBySlug`.
3. Data detail ditampilkan pada hero, metric grid, decision cards, topic insight, gallery, review, dan form.
4. Jika user login, app mengecek favorite.
5. Klik topic membuka bottom sheet review yang terkait.
6. Submit review mengirim rating dan teks ke backend.

## Feature Compare

Folder:
- `Mobile/lib/features/compare`

File penting:
- `data/compare_models.dart`
- `data/compare_repository.dart`
- `presentation/compare_page.dart`

Komentar penting:
- `CompareRepository`: repository API untuk daftar destinasi dan hasil perbandingan.
- `ComparedDestination`: model destinasi dalam hasil compare.
- `CompareResult`: model hasil perbandingan dua destinasi.
- `compareDestinationsProvider`: memuat daftar destinasi untuk picker compare.
- `ComparePage`: halaman compare mobile untuk memilih dua destinasi dan melihat hasil analitik.
- `_compare`: meminta hasil compare saat dua destinasi sudah dipilih.

Alur:
1. User memilih destinasi A dan B.
2. `_compare` memanggil `CompareRepository.compare`.
3. Repository memanggil `/api/analytics/compare`.
4. Result menampilkan winner, skor, rating, sentimen, dan topik.

## Feature Profile dan Favorite

Folder:
- `Mobile/lib/features/profile`

File penting:
- `data/profile_models.dart`
- `data/profile_repository.dart`
- `presentation/profile_page.dart`

Komentar penting:
- `ProfileRepository`: repository API untuk profil, avatar, favorite, dan compare tray profile.
- `FavoriteDestination`: model destinasi favorit.
- `favoritesProvider`: memuat daftar favorite user login.
- `ProfilePage`: halaman profile untuk data user, favorite, filter, upload avatar, dan compare tray.

Alur:
1. Profile membaca state auth dari `AuthController`.
2. Jika belum login, UI menampilkan empty state dan tombol login.
3. Jika login, `favoritesProvider` memanggil repository.
4. User bisa edit profile, upload avatar, filter favorite, hapus favorite, atau memilih favorite untuk compare.

## Hubungan Mobile dengan Backend dan Web

Mobile dan web memakai backend yang sama. Perbedaannya:
- Web memakai Axios dan React Query.
- Mobile memakai Dio dan Riverpod.
- Keduanya membaca endpoint backend yang sama.
- Python `Model` tetap hanya dipanggil oleh backend.

Contoh flow:
- Search mobile: `SearchPage` -> `SearchRepository` -> backend `/api/search` atau `/api/destinations`.
- Detail mobile: `DestinationDetailPage` -> `DestinationRepository` -> backend `/api/destinations/slug/:slug`.
- Favorite mobile: `ProfilePage` atau detail -> repository -> backend `/api/favorites`.
- Compare mobile: `ComparePage` -> `CompareRepository` -> backend `/api/analytics/compare`.

## Pola Riverpod yang Dipakai

Jenis provider:
- `Provider`: dependency seperti Dio dan repository.
- `FutureProvider`: data async seperti detail, favorites, cities, trending.
- `StateNotifierProvider`: state login yang bisa berubah lewat action.

Alur umum:
1. UI memanggil `ref.watch(provider)` untuk membaca state/data.
2. UI memanggil `ref.read(repositoryProvider)` untuk action.
3. Repository mengakses backend.
4. Model parser mengubah JSON menjadi class Dart.
5. UI menampilkan `data`, `loading`, atau `error`.

## Aturan Komentar Mobile

Komentar yang dipertahankan atau ditambahkan harus:
- berbahasa Indonesia;
- singkat dan langsung menjelaskan fungsi;
- ditempatkan di class/function/provider yang penting dalam flow;
- tidak mengulang kode yang sudah jelas;
- tidak memenuhi widget kecil dengan komentar visual.

Komentar yang dihindari:
- komentar layout seperti `Header`, `Card`, `Button` jika widget sudah jelas;
- komentar panjang seperti dokumentasi framework;
- komentar berbahasa Inggris campur Indonesia;
- komentar step-by-step yang hanya mengulang isi fungsi.

## Cara Membaca Flow untuk Developer Baru

Urutan belajar yang disarankan:

1. Baca `lib/main.dart` untuk entrypoint Flutter.
2. Baca `lib/app/app.dart` untuk bootstrap dan startup splash.
3. Baca `lib/app/router.dart` untuk navigasi.
4. Baca `lib/core/network/dio_client.dart` dan `token_interceptor.dart` untuk koneksi backend.
5. Baca `lib/features/auth/data/auth_controller.dart` untuk login state.
6. Baca `lib/features/search/presentation/search_page.dart` untuk flow pencarian.
7. Baca `lib/features/destination_detail/presentation/destination_detail_page.dart` untuk detail destinasi.
8. Baca repository tiap feature untuk memahami endpoint backend yang dipakai.

Dengan urutan ini, developer baru bisa memahami dari startup, routing, network, state, data layer, sampai UI utama.

## Indeks File Berpengaruh dan Referensi Baris

Bagian ini memetakan file Flutter yang memengaruhi startup, routing, network, state, repository, model data, dan tampilan utama aplikasi mobile. Referensi baris menunjuk class, provider, atau fungsi utama.

### App Shell, Routing, Theme, dan Config

| Path | Posisi pada flow | Kegunaan | Referensi baris utama |
| --- | --- | --- | --- |
| `Mobile/lib/main.dart` | Entrypoint Flutter | Memuat env, inisialisasi Flutter binding, provider scope, dan menjalankan app. | `main` `main.dart:7` |
| `Mobile/lib/app/app.dart` | Root app | Menjalankan bootstrap awal, startup splash, theme, dan router. | `appBootstrapProvider` `app.dart:10`, `RanahInsightApp` `app.dart:18` |
| `Mobile/lib/app/router.dart` | Navigasi | Mendefinisikan route, shell bottom navigation, brand bar, dan tab utama. | `appRouterProvider` `router.dart:17`, `MainShell` `router.dart:74` |
| `Mobile/lib/app/config/env.dart` | Config env | Membaca API base URL dari `.env` untuk koneksi backend. | `Env` `env.dart:3` |
| `Mobile/lib/app/config/api_endpoints.dart` | Endpoint map | Menyimpan path endpoint backend agar repository tidak hard-code string berulang. | `ApiEndpoints` `api_endpoints.dart:1` |
| `Mobile/lib/app/theme/app_colors.dart` | Token warna | Menyamakan warna brand, AI, sentiment, surface, dan status di semua screen. | `AppColors` `app_colors.dart:3` |
| `Mobile/lib/app/theme/app_theme.dart` | Theme app | Membuat `ThemeData` global untuk MaterialApp. | `AppTheme` `app_theme.dart:5` |
| `Mobile/lib/app/theme/app_text_styles.dart` | Typography | Menyediakan style teks reusable. | `AppTextStyles` `app_text_styles.dart:5` |
| `Mobile/lib/app/theme/app_spacing.dart` | Spacing token | Menyediakan ukuran spacing konsisten. | `AppSpacing` `app_spacing.dart:1` |

### Core Network, Storage, Utils, dan Widget Reusable

| Path | Posisi pada flow | Kegunaan | Referensi baris utama |
| --- | --- | --- | --- |
| `Mobile/lib/core/network/dio_client.dart` | HTTP client | Membuat `Dio`, memasang base URL, interceptor token, dan helper response. | `secureStorageProvider` `dio_client.dart:10`, `dioProvider` `dio_client.dart:15`, `responseData` `dio_client.dart:30` |
| `Mobile/lib/core/network/token_interceptor.dart` | Auth interceptor | Menambahkan token ke request backend dan membantu menangani auth request. | `TokenInterceptor` `token_interceptor.dart:9` |
| `Mobile/lib/core/network/api_result.dart` | Result wrapper | Membungkus hasil sukses/gagal untuk flow repository yang butuh state eksplisit. | `ApiSuccess` `api_result.dart:5`, `ApiFailure` `api_result.dart:11` |
| `Mobile/lib/core/storage/secure_storage_service.dart` | Token storage | Menyimpan dan membaca token login secara aman dari device. | `SecureStorageService` `secure_storage_service.dart:3` |
| `Mobile/lib/core/errors/app_exception.dart` | Error app | Bentuk error internal yang bisa ditampilkan UI. | `AppException` `app_exception.dart:1` |
| `Mobile/lib/core/utils/formatters.dart` | Formatter aman | Format percent, score, rating, dan tanggal tanpa crash locale. | `percentLabel` `formatters.dart:1`, `dateLabel` `formatters.dart:16` |
| `Mobile/lib/core/utils/image_url.dart` | Helper gambar | Mengubah URL relatif/backend menjadi URL gambar yang bisa dimuat app. | `resolveImageUrl` `image_url.dart:3` |
| `Mobile/lib/core/constants/destination_categories.dart` | Kategori destinasi | Menyamakan kategori fixed dengan backend/web untuk filter search dan form visual. | `DestinationCategoryOption` `destination_categories.dart:1`, `destinationCategoryLabel` `destination_categories.dart:24` |
| `Mobile/lib/core/widgets/app_startup_splash.dart` | Tampilan startup | Loading awal brand dengan animasi dan fallback gambar. | `AppStartupSplash` `app_startup_splash.dart:9`, `_RingPainter` `app_startup_splash.dart:181` |
| `Mobile/lib/core/widgets/app_screen_scaffold.dart` | Layout wrapper | Memberi padding dan max width konsisten untuk screen. | `AppScreenScaffold` `app_screen_scaffold.dart:3` |
| `Mobile/lib/core/widgets/app_cached_image.dart` | Image component | Memuat image network dengan cache dan fallback. | `AppCachedImage` `app_cached_image.dart:7` |
| `Mobile/lib/core/widgets/destination_card.dart` | Card destinasi | Card reusable untuk home/search/favorite dengan image, metric, dan topic. | `DestinationCardData` `destination_card.dart:10`, `DestinationCard` `destination_card.dart:34` |
| `Mobile/lib/core/widgets/app_select_sheet.dart` | Bottom picker | Select bottom sheet dengan search untuk kota/destinasi/kategori. | `SelectOption` `app_select_sheet.dart:6`, `showAppSelectSheet` `app_select_sheet.dart:20` |
| `Mobile/lib/core/widgets/image_preview.dart` | Preview gambar | Menampilkan foto profile/galeri dalam preview circular atau full image sesuai konteks. | `showImagePreview` `image_preview.dart:7` |
| `Mobile/lib/core/widgets/app_error_panel.dart` | Error state | Panel error reusable dengan pesan dan retry. | `AppErrorPanel` `app_error_panel.dart:7` |
| `Mobile/lib/core/widgets/empty_state.dart` | Empty state | Tampilan kosong reusable untuk data yang belum ada. | `EmptyState` `empty_state.dart:5` |
| `Mobile/lib/core/widgets/app_inline_loader.dart` | Loading kecil | Loader inline untuk proses async di dalam halaman. | `AppInlineLoader` `app_inline_loader.dart:5` |
| `Mobile/lib/core/widgets/app_logo.dart` | Logo app | Menampilkan logo brand dengan fallback jika asset gagal. | `AppLogo` `app_logo.dart:6` |

### Auth

| Path | Posisi pada flow | Kegunaan | Referensi baris utama |
| --- | --- | --- | --- |
| `Mobile/lib/features/auth/data/auth_models.dart` | Model auth | Parser user dan session dari response backend. | `AuthUser` `auth_models.dart:1`, `AuthSession` `auth_models.dart:27` |
| `Mobile/lib/features/auth/data/auth_repository.dart` | Repository auth | Memanggil endpoint login/register/me/logout/refresh backend. | `authRepositoryProvider` `auth_repository.dart:9`, `AuthRepository` `auth_repository.dart:14` |
| `Mobile/lib/features/auth/data/auth_controller.dart` | State auth | Mengatur status login, restore token, login, register, logout, dan user aktif. | `AuthState` `auth_controller.dart:9`, `authControllerProvider` `auth_controller.dart:38`, `AuthController` `auth_controller.dart:45` |
| `Mobile/lib/features/auth/presentation/login_page.dart` | Tampilan login | Form login, validasi, loading, error, dan navigasi ke register. | `LoginPage` `login_page.dart:11` |
| `Mobile/lib/features/auth/presentation/register_page.dart` | Tampilan register | Form daftar user dan integrasi ke auth controller. | `RegisterPage` `register_page.dart:11` |

### Home dan Search

| Path | Posisi pada flow | Kegunaan | Referensi baris utama |
| --- | --- | --- | --- |
| `Mobile/lib/features/home/data/home_repository.dart` | Repository home | Mengambil trending/rekomendasi destinasi dari backend. | `homeRepositoryProvider` `home_repository.dart:6`, `HomeRepository` `home_repository.dart:11` |
| `Mobile/lib/features/home/presentation/home_page.dart` | Tampilan home | Hero, search CTA, signal cards, insight panel, action bento, dan rekomendasi. | `homeTrendingProvider` `home_page.dart:18`, `HomePage` `home_page.dart:44`, `_HeroLanding` `home_page.dart:121`, `_RecommendationSection` `home_page.dart:693` |
| `Mobile/lib/features/search/data/search_models.dart` | Model search | Parser destination summary dan topic filter dari response search. | `DestinationTopic` `search_models.dart:3`, `DestinationSummary` `search_models.dart:20`, `TopicFilter` `search_models.dart:85` |
| `Mobile/lib/features/search/data/search_repository.dart` | Repository search | Memanggil keyword/semantic search, daftar kota, dan history search. | `searchRepositoryProvider` `search_repository.dart:9`, `SearchRepository` `search_repository.dart:14` |
| `Mobile/lib/features/search/presentation/search_page.dart` | Tampilan search | Mengatur query, mode search, filter kota/kategori, history, loading, error, dan result card. | `citiesProvider` `search_page.dart:20`, `SearchPage` `search_page.dart:32`, `_SearchCommandSurface` `search_page.dart:249`, `_FilterButton` `search_page.dart:451` |

### Detail Destinasi

| Path | Posisi pada flow | Kegunaan | Referensi baris utama |
| --- | --- | --- | --- |
| `Mobile/lib/features/destination_detail/data/destination_models.dart` | Model detail | Parser detail destinasi, topic group, breakdown sentimen, review scrape, dan user review. | `DestinationDetail` `destination_models.dart:5`, `TopicGroupInsight` `destination_models.dart:124`, `ScrapedTopicReview` `destination_models.dart:187`, `UserReview` `destination_models.dart:219` |
| `Mobile/lib/features/destination_detail/data/destination_repository.dart` | Repository detail | Memanggil detail destinasi, favorite check/add/remove, review, dan review by topic/group. | `destinationRepositoryProvider` `destination_repository.dart:9`, `DestinationRepository` `destination_repository.dart:14` |
| `Mobile/lib/features/destination_detail/presentation/destination_detail_page.dart` | Tampilan detail | Hero, metric, deskripsi, peta topik, galeri, ulasan, review form, dan bottom sheet ulasan topik. | `destinationDetailProvider` `destination_detail_page.dart:25`, `DestinationDetailPage` `destination_detail_page.dart:31`, `_DetailContent` `destination_detail_page.dart:125`, `_TopicInsightSection` `destination_detail_page.dart:522`, `_GallerySection` `destination_detail_page.dart:1029`, `_ReviewForm` `destination_detail_page.dart:1434` |

### Compare

| Path | Posisi pada flow | Kegunaan | Referensi baris utama |
| --- | --- | --- | --- |
| `Mobile/lib/features/compare/data/compare_models.dart` | Model compare | Parser hasil compare, destination panel, sentiment, dan topik dominan. | `ComparedDestination` `compare_models.dart:2`, `CompareTopic` `compare_models.dart:64`, `CompareResult` `compare_models.dart:83` |
| `Mobile/lib/features/compare/data/compare_repository.dart` | Repository compare | Mengambil list destinasi compare dan hasil perbandingan backend. | `compareRepositoryProvider` `compare_repository.dart:11`, `CompareRepository` `compare_repository.dart:19` |
| `Mobile/lib/features/compare/presentation/compare_page.dart` | Tampilan compare | Picker destinasi, swap/reset, result view, chart sentiment, panel destinasi, dan topik. | `compareDestinationsProvider` `compare_page.dart:21`, `ComparePage` `compare_page.dart:26`, `_CompareResultView` `compare_page.dart:265`, `_DestinationPanel` `compare_page.dart:390` |

### Profile dan Favorite

| Path | Posisi pada flow | Kegunaan | Referensi baris utama |
| --- | --- | --- | --- |
| `Mobile/lib/features/profile/data/profile_models.dart` | Model profile | Parser favorite destination dan data yang tampil di profile/favorite. | `FavoriteDestination` `profile_models.dart:4` |
| `Mobile/lib/features/profile/data/profile_repository.dart` | Repository profile | Memanggil profile, update profile, avatar upload, favorite list/remove. | `profileRepositoryProvider` `profile_repository.dart:11`, `ProfileRepository` `profile_repository.dart:16` |
| `Mobile/lib/features/profile/presentation/profile_page.dart` | Tampilan profile/favorit | Header profile, preview avatar, form update, stats favorit, filter/sort, favorite card, dan compare tray. | `favoritesProvider` `profile_page.dart:27`, `ProfilePage` `profile_page.dart:32`, `_ProfileHeader` `profile_page.dart:325`, `_ProfileForm` `profile_page.dart:509`, `_FavoriteCard` `profile_page.dart:794`, `_CompareTray` `profile_page.dart:847` |

## Flow File ke Fungsi Mobile

1. **Startup**: `main.dart:7` menjalankan aplikasi, `app.dart:10` melakukan bootstrap auth/env, lalu `router.dart:17` menentukan halaman awal.
2. **Request backend**: repository memakai `dioProvider` `dio_client.dart:15`; `TokenInterceptor` `token_interceptor.dart:9` menambahkan token dari `SecureStorageService`.
3. **Auth restore**: `AuthController` `auth_controller.dart:45` membaca token, memanggil `/users/me`, lalu state dipakai route dan UI.
4. **Home/search**: `home_page.dart:44` menampilkan landing mobile, `search_page.dart:32` mengatur pencarian, dan `search_repository.dart:14` memanggil backend.
5. **Detail**: `destination_detail_page.dart:25` fetch detail, `destination_repository.dart:14` memanggil endpoint, dan `destination_models.dart:5` memetakan response ke class Dart.
6. **Compare**: `compare_page.dart:26` memilih destinasi, `compare_repository.dart:19` meminta hasil compare, lalu `compare_models.dart:83` memetakan hasil.
7. **Profile/favorite**: `profile_page.dart:32` mengatur UI profile/favorite, `profile_repository.dart:16` menjadi jalur data, dan `profile_models.dart:4` memetakan favorite card.
