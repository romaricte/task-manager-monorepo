import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MomentumBrand extends StatelessWidget {
  const MomentumBrand({super.key, this.light = false, this.compact = false});

  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -.06,
          child: Container(
            width: compact ? 31 : 36,
            height: compact ? 31 : 36,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.ink,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Task manager',
          style: TextStyle(
            color: light ? Colors.white : AppColors.ink,
            fontSize: compact ? 19 : 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
      ],
    );
  }
}
