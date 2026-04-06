import 'package:flutter/widgets.dart';

class FanBranding {
  static const String appName = 'FAN';
  static const String organizationName =
      'Fundación Argentina de Nanotecnología';
  static const String fullLogoAsset = 'assets/branding/fan_logo.png';
}

class FanBrandLogo extends StatelessWidget {
  const FanBrandLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel = FanBranding.organizationName,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      FanBranding.fullLogoAsset,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
    );
  }
}
