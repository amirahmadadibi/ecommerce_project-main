import 'package:dio/dio.dart';

import '../../di/di.dart';
import '../../util/api_exception.dart';
import '../model/banner.dart';

abstract class IBannerDatasource {
  Future<List<BannerCampain>> getBanners();
}

class BannerRemoteDatasource extends IBannerDatasource {
  final Dio _dio = locator.get();
  @override
  Future<List<BannerCampain>> getBanners() async {
    try {
      var respones = await _dio.get('rest/v1/banner?select=*');
      return (respones.data as List)
          .map<BannerCampain>(
              (jsonObject) => BannerCampain.fromJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }
}
