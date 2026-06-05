import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/config/env.dart';
import '../../../core/errors/app_exception.dart';

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

class GoogleSignInService {
  GoogleSignInService();

  bool _initialized = false;

  Future<String> signInAndGetIdToken() async {
    final clientId = Env.googleWebClientId;
    if (clientId.isEmpty) {
      throw const AppException('Google client ID belum dikonfigurasi.');
    }

    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      await signIn.initialize(serverClientId: clientId);
      _initialized = true;
    }

    try {
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppException('Google tidak mengirim ID token.');
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AppException('Login Google dibatalkan.');
      }
      throw AppException(error.description ?? 'Login Google gagal.');
    }
  }
}
