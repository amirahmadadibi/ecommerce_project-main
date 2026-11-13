import 'package:dio/dio.dart';

class ApiException implements Exception {
  int? code;
  String? message;
  Response<dynamic>? response;
  ApiException(this.code, this.message, {this.response}) {
    if (code == 400) {
      if (message == 'Invalid login credentials') {
        message = 'نام کاربری یا رمز عبور اشتباه است';
      }
      if (message == 'User already registered') {
        message = 'نام‌کاربری نامعتبر است یا قبلا گرفته شده';
      }
    }
    if (code == 422) {
      if (message == 'Validation failed') {
        message = 'نام‌کاربری نامعتبر است یا قبلا گرفته شده';
      }
    }
  }
}
