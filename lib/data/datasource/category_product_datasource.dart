import 'package:dio/dio.dart';

import '../../di/di.dart';
import '../../util/api_exception.dart';
import '../model/product.dart';

abstract class ICategoryProductDatasource {
  Future<List<Product>> getProductByCategoryId(String categoryId);
}

class CategoryProductRemoteDatasource extends ICategoryProductDatasource {
  final Dio _dio = locator.get();

  @override
  Future<List<Product>> getProductByCategoryId(String categoryId) async {
    try {
      // 'qnbj8d6b9lzzpn8' is the legacy "همه" (all) category - return everything
      final String url = (categoryId == 'qnbj8d6b9lzzpn8')
          ? 'rest/v1/products?select=*'
          : 'rest/v1/products?select=*&category=eq.$categoryId';
      var respones = await _dio.get(url);
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
