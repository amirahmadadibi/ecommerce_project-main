import 'package:apple_shop/data/model/comment.dart';
import 'package:apple_shop/util/auth_manager.dart';
import 'package:dio/dio.dart';

import '../../di/di.dart';
import '../../util/api_exception.dart';

abstract class ICommentDatasource {
  Future<List<Comment>> getComments(String productId);
  Future<void> postComment(String productId, String comment);
}

class CommentRemoteDatasource extends ICommentDatasource {
  final Dio _dio = locator.get();
  final String userId = AuthManager.getId();
  @override
  Future<List<Comment>> getComments(String productId) async {
    try {
      var respones = await _dio.get(
          'rest/v1/comment?select=id,text,user_id,product_id,user:users(id,username,name,avatar)&product_id=eq.$productId&order=created_at.desc&limit=100');
      return (respones.data as List)
          .map<Comment>((jsonObject) => Comment.fromMapJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<void> postComment(String productId, String comment) async {
    try {
      // AuthManager.getId() stores the Supabase auth user id (uuid string)
      await _dio.post('rest/v1/comment', data: {
        'text': comment,
        'user_id': AuthManager.getId(),
        'product_id': productId
      });
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }
}
