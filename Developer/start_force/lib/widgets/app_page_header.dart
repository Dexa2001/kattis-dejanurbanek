import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: onBack ?? () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
            if (showBack) const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.whiteSoft,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
