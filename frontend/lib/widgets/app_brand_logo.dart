import 'package:flutter/material.dart';

class AppBrandLogo extends StatelessWidget {
  static const String assetPath = 'assets/images/logo_exspan.png';

  final double size;
  final BoxFit fit;
  final bool withWhiteBadge;
  final double padding;

  const AppBrandLogo({
    super.key,
    this.size = 28,
    this.fit = BoxFit.contain,
    this.withWhiteBadge = true,
    this.padding = 4,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );

    if (!withWhiteBadge) {
      return image;
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: image,
    );
  }
}
