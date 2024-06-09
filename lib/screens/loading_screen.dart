import 'package:flutter/material.dart';
import 'package:gceditor/assets.dart';

class LoadingScreen extends StatelessWidget {
  static const appIconTag = 'AppIcon';

  const LoadingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: appIconTag,
        child: Image.asset(
          Assets.images.icon1024PNG,
          width: 400,
        ),
      ),
    );
  }
}
