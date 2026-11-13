import 'package:apple_shop/data/model/product.dart';
import 'package:dio/dio.dart';

import '../../di/di.dart';
import '../../util/api_exception.dart';

abstract class IProductDataSource {
  Future<List<Product>> getProducts();
  Future<List<Product>> getHotest();
  Future<List<Product>> getBestSeller();
}

class ProductRemoteDataSource extends IProductDataSource {
  final Dio _dio = locator.get();

  @override
  Future<List<Product>> getProducts() async {
    try {
      var respones = await _dio.get('rest/v1/products?select=*');
      return (respones.data as List)
          .map<Product>((jsonObject) => Product.fromJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<List<Product>> getHotest() async {
    try {
      var respones =
          await _dio.get('rest/v1/products?select=*&popularity=eq.Hotest');
      return (respones.data as List)
          .map<Product>((jsonObject) => Product.fromJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<List<Product>> getBestSeller() async {
    try {
      var respones =
          await _dio.get('rest/v1/products?select=*&popularity=eq.Best Seller');
      return (respones.data as List)
          .map<Product>((jsonObject) => Product.fromJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }
}
