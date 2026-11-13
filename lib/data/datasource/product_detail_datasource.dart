import 'package:apple_shop/data/model/product_image.dart';
import 'package:apple_shop/data/model/product_peroperty.dart';
import 'package:apple_shop/data/model/product_variant.dart';
import 'package:apple_shop/data/model/variant.dart';
import 'package:apple_shop/data/model/variant_type.dart';
import 'package:apple_shop/di/di.dart';
import 'package:dio/dio.dart';

import '../../util/api_exception.dart';
import '../model/category.dart';

abstract class IDetailProductDatasource {
  Future<List<ProductImage>> getGallery(String productId);
  Future<List<VariantType>> getVariantTypes();
  Future<List<Variant>> getVariant(String productId);
  Future<List<ProductVarint>> getProductVariants(String productId);
  Future<Category> getProductCategory(String categoryId);
  Future<List<Property>> getProductProperties(String productId);
}

class DetailProductRemoteDatasource extends IDetailProductDatasource {
  final Dio _dio = locator.get();

  @override
  Future<List<ProductImage>> getGallery(String productId) async {
    try {
      var respones = await _dio
          .get('rest/v1/gallery?select=*&product_id=eq.$productId');

      return (respones.data as List)
          .map<ProductImage>((jsonObject) => ProductImage.fromJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<List<VariantType>> getVariantTypes() async {
    try {
      var respones = await _dio.get('rest/v1/variants_type?select=*');

      return (respones.data as List)
          .map<VariantType>((jsonObject) => VariantType.fromjson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<List<Variant>> getVariant(String productId) async {
    try {
      var respones = await _dio
          .get('rest/v1/variants?select=*&product_id=eq.$productId');

      return (respones.data as List)
          .map<Variant>((jsonObject) => Variant.fromJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<List<ProductVarint>> getProductVariants(String productId) async {
    var variantTypeList = await getVariantTypes();
    var variantList = await getVariant(productId);

    List<ProductVarint> productVariantList = [];

    try {
      for (var variantType in variantTypeList) {
        var variant = variantList
            .where((element) => element.typeId == variantType.id)
            .toList();
        productVariantList.add(ProductVarint(variantType, variant));
      }

      return productVariantList;
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<Category> getProductCategory(String categoryId) async {
    try {
      var reponse = await _dio
          .get('rest/v1/category?select=*&id=eq.$categoryId');
      return Category.fromMapJson(reponse.data[0]);
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }

  @override
  Future<List<Property>> getProductProperties(String productId) async {
    try {
      var respones = await _dio
          .get('rest/v1/properties?select=*&product_id=eq.$productId');

      return (respones.data as List)
          .map<Property>((jsonObject) => Property.fromJson(jsonObject))
          .toList();
    } on DioError catch (ex) {
      throw ApiException(ex.response?.statusCode,
          ex.response?.data is Map ? ex.response?.data['message'] : null);
    } catch (ex) {
      throw ApiException(0, 'unknown erorr');
    }
  }
}
