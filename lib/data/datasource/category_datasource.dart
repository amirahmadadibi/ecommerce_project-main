import 'package:apple_shop/data/model/category.dart';
import 'package:dio/dio.dart';

import '../../di/di.dart';
import '../../util/api_exception.dart';

abstract class ICategoryDatasource {
  Future<List<Category>> getGategories();
}

class CategoryRemoteDatasource extends ICategoryDatasource {
  final Dio _dio = locator.get();
  @override
  Future<List<Category>> getGategories() async {
    try {
      var respones = await _dio.get('rest/v1/category?select=*');
      return (respones.data as List)
          .map<Category>((jsonObject) => Category.fromMapJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }
}
