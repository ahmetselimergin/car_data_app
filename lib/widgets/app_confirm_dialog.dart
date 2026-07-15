import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';

/// Ortak onay diyaloğu: Vazgeç + onay (isteğe bağlı yıkıcı stil).
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  IconData confirmIcon = Icons.check_rounded,
}) async {
  final AppLocalizations l10n = context.l10n;
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(l10n.dismiss),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: Icon(confirmIcon, size: 18),
                  label: Text(confirmLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor:
                        destructive ? const Color(0xFFB91C1C) : null,
                    foregroundColor: destructive ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  return ok == true;
}
