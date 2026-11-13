class Comment {
  String id;
  String text;
  String productId;
  String userId;
  String userThumbnailUrl;
  String username;
  String avatar;

  Comment(this.id, this.text, this.productId, this.userId,
      this.userThumbnailUrl, this.username, this.avatar);

  /// Parses PostgREST response using embedded user relation:
  /// /rest/v1/comment?select=*,user:users(username,name,avatar)&user_id=eq.X
  factory Comment.fromMapJson(Map<String, dynamic> jsonObject) {
    final user = jsonObject['user'];
    final Map<String, dynamic> userMap =
        user is Map<String, dynamic> ? user : const {};
    return Comment(
        jsonObject['id'],
        jsonObject['text'],
        jsonObject['product_id'],
        jsonObject['user_id'],
        userMap['avatar'] ?? '',
        (userMap['name'] ?? '').isNotEmpty
            ? userMap['name']
            : (userMap['username'] ?? ''),
        userMap['avatar'] ?? '');
  }
}
