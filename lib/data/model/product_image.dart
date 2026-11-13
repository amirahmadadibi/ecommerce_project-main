class ProductImage {
  String? imageUrl;
  String? productId;

  ProductImage(this.imageUrl, this.productId);

  factory ProductImage.fromJson(Map<String, dynamic> jsonObject) {
    return ProductImage(
        jsonObject['image'],
        jsonObject['product_id'],
    );
  }
}
