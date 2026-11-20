import 'package:material_ui/material_ui.dart';

import '../data/vehicles.dart';
import '../theme.dart';

/// Shows `assets/brands/<id>.png`. If the file is not there, shows the
/// brand initials, so the app never breaks while you collect the logos.
class BrandLogo extends StatelessWidget {
  final VehicleBrand brand;
  final double size;

  const BrandLogo({super.key, required this.brand, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: AppColors.border),
      ),
      child: Image.asset(
        brand.logoAsset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Center(
          child: Text(
            brand.initials,
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              color: AppColors.teal,
            ),
          ),
        ),
      ),
    );
  }
}
