import 'package:apple_shop/util/api_exception.dart';
import 'package:apple_shop/util/auth_manager.dart';
import 'package:apple_shop/util/dio_provider.dart';
import 'package:dio/dio.dart';

abstract class IAuthenticationDatasource {
  Future<void> register(
      String username, String password, String passwordConfirm);

  Future<String> login(String username, String password);
}

class AuthenticationRemote implements IAuthenticationDatasource {
  final Dio _dio = DioProvider.createDioWithoutHeader();

  @override
  Future<void> register(
      String username, String password, String passwordConfirm) async {
    try {
      if (password != passwordConfirm) {
        throw ApiException(400, 'رمز عبور و تکرار آن یکسان نیست');
      }
      // Supabase Auth signup - username is stored as email-style local part
      final response = await _dio.post('auth/v1/signup', data: {
        'email': '$username@appleshop.local',
        'password': password,
        'data': {'username': username, 'name': username},
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        // If email confirmation is disabled the session comes back immediately
        final accessToken = response.data?['access_token'];
        final userId = response.data?['user']?['id'];
        if (accessToken != null && userId != null) {
          AuthManager.saveId(userId);
          AuthManager.saveToken(accessToken);
          return;
        }
        // otherwise fall through to auto login
        await login(username, password);
      }
    } on DioError catch (ex) {
      final data = ex.response?.data;
      String msg = data is Map ? (data['msg'] ?? data['message'] ?? data['error_description'] ?? '').toString() : '';
      if (msg.contains('already been registered') || msg.contains('already registered')) {
        throw ApiException(ex.response?.statusCode, 'این نام کاربری قبلا ثبت شده است');
      }
      throw ApiException(ex.response?.statusCode, msg.isNotEmpty ? msg : 'خطا در ثبت نام',
          response: ex.response);
    } catch (ex) {
      if (ex is ApiException) rethrow;
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<String> login(String username, String password) async {
    try {
      var response = await _dio.post('auth/v1/token?grant_type=password', data: {
        'email': '$username@appleshop.local',
        'password': password,
      });
      if (response.statusCode == 200) {
        final token = response.data?['access_token'] as String?;
        final userId = response.data?['user']?['id'] as String?;
        if (token == null || userId == null) {
          throw ApiException(0, 'خطایی در ورود پیش آمده!');
        }
        AuthManager.saveId(userId);
        AuthManager.saveToken(token);
        return token;
      }
    } on DioError catch (ex) {
      final data = ex.response?.data;
      String msg = data is Map
          ? (data['msg'] ?? data['error_description'] ?? data['message'] ?? '').toString()
          : '';
      if (msg.contains('Invalid login credentials')) {
        throw ApiException(ex.response?.statusCode, 'نام کاربری یا رمز عبور اشتباه است');
      }
      throw ApiException(ex.response?.statusCode, msg.isNotEmpty ? msg : 'خطا در ورود');
    } catch (ex) {
      if (ex is ApiException) rethrow;
      throw ApiException(0, 'unknown erorr');
    }
    return '';
  }
}
