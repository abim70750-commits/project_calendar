import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../utils/color_logic.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final status = statusOf(project);
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(45),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        labelOf(AppLocalizations.of(context)!, status),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
