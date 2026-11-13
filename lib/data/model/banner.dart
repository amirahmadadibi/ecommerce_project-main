class BannerCampain {
  String? id;
  String? collectionId;
  String? thumbnail;
  String? categoryId;

  BannerCampain(this.id, this.collectionId, this.thumbnail, this.categoryId);

  factory BannerCampain.fromJson(Map<String, dynamic> jsonObject) {
    return BannerCampain(
      jsonObject['id'],
      'shop',
      jsonObject['thumbnail'],
      jsonObject['category_id'],
    );
  }
}
