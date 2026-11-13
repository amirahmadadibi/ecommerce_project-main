import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class CachedImage extends StatelessWidget {
  String? imageUrl;
  double radius;
  BoxFit fit;
  CachedImage(
      {super.key, this.imageUrl, this.radius = 0, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: CachedNetworkImage(
          fit: fit,
          imageUrl: imageUrl ??
              'https://api.expertflutter.pro/storage/v1/object/public/shop-images/category_qnbj8d6b9lzzpn8_thumbnail_rectangle_63_OHpTjZfdL4.png',
          errorWidget: (context, url, error) => Container(
                color: Colors.red[100],
              ),
          placeholder: (context, url) => Container(
                color: Colors.grey,
              )),
    );
  }
}
