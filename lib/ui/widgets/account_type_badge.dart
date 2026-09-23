import 'package:flutter/material.dart';
import '../../core/constants/account_types.dart';
import '../../core/theme/app_colors.dart';

class AccountTypeBadge extends StatelessWidget {
  final String type;

  const AccountTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case AccountTypes.asset:
        bg = AppColors.assetBlue.withOpacity(0.12);
        fg = AppColors.assetBlue;
        break;
      case AccountTypes.liability:
        bg = AppColors.creditRose.withOpacity(0.12);
        fg = AppColors.creditRose;
        break;
      case AccountTypes.equity:
        bg = AppColors.equityPurple.withOpacity(0.12);
        fg = AppColors.equityPurple;
        break;
      case AccountTypes.revenue:
        bg = AppColors.debitGreen.withOpacity(0.12);
        fg = AppColors.primaryGreen;
        break;
      case AccountTypes.expense:
        bg = AppColors.creditRose.withOpacity(0.12);
        fg = AppColors.creditRose;
        break;
      default:
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
