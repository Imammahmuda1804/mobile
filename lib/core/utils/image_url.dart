import '../../app/config/env.dart';

String resolveImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.isEmpty) return '';
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  final slash = rawUrl.startsWith('/') ? '' : '/';
  return '${Env.apiBaseUrl}$slash$rawUrl';
}
