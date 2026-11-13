class Product {
  String id;
  String collectionId;
  String thumbnail;
  String description;
  int discountPrice;
  int price;
  String popularity;
  String name;
  int quantity;
  String categoryId;
  int? realPrice;
  num? persent;
  Product(
      this.id,
      this.collectionId,
      this.thumbnail,
      this.description,
      this.discountPrice,
      this.price,
      this.popularity,
      this.name,
      this.quantity,
      this.categoryId) {
    realPrice = price - discountPrice;
    persent = ((price - realPrice!) / price) * 100;
  }

  factory Product.fromJson(Map<String, dynamic> jsonObject) {
    return Product(
        jsonObject['id'],
        'shop',
        jsonObject['thumbnail'] ?? '',
        jsonObject['description'] ?? '',
        jsonObject['discount_price'] ?? 0,
        jsonObject['price'] ?? 0,
        jsonObject['popularity'] ?? '',
        jsonObject['name'] ?? '',
        jsonObject['quantity'] ?? 0,
        jsonObject['category']);
  }
}
