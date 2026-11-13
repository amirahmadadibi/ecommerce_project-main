import 'package:dio/dio.dart';

import 'auth_manager.dart';

/// Supabase (self-hosted) connection settings.
class SupabaseConfig {
  static const String baseUrl = 'https://api.expertflutter.pro';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzkyNjExMDE2LCJleHAiOjE5NTAyOTEwMTZ9.FBp_VS-DHv4do8PkYX4I7yf7I8kaQ4lgNeX25Z80ZUg';
}

class DioProvider {
  static Dio createDio() {
    final token = AuthManager.readAuth();
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'apikey': SupabaseConfig.anonKey,
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    Dio dio = Dio(BaseOptions(baseUrl: SupabaseConfig.baseUrl, headers: headers));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // keep apikey always present; refresh Authorization from storage
        options.headers['apikey'] = SupabaseConfig.anonKey;
        final t = AuthManager.readAuth();
        if (t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        } else {
          options.headers.remove('Authorization');
        }
        return handler.next(options);
      },
    ));
    return dio;
  }

  static Dio createDioWithoutHeader() {
    Dio dio = Dio(BaseOptions(
      baseUrl: SupabaseConfig.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.anonKey,
      },
    ));
    return dio;
  }
}
