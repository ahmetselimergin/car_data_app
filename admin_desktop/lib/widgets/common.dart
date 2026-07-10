import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'empty_state.dart';

/// Supabase / PostgREST hatalarını kullanıcıya okunur hale getirir.
String formatCatalogError(Object error) {
  final s = error.toString();
  final lower = s.toLowerCase();
  if (lower.contains('jwt issued at future') || lower.contains('pgrst303')) {
    return 'Oturum jetonu geçersiz (cihaz saati kaymış olabilir). '
        'Mac’te Tarih & Saat → “Otomatik ayarla”yı aç, sonra çıkış yapıp '
        'yeniden giriş yap.';
  }
  if (lower.contains('jwt expired') || lower.contains('pgrst301')) {
    return 'Oturum süresi dolmuş. Çıkış yapıp yeniden giriş yap.';
  }
  if (lower.contains('invalid jwt') || lower.contains('not authenticated')) {
    return 'Oturum doğrulanamadı. Yeniden giriş yap.';
  }
  return s;
}

bool isAuthTokenError(Object? error) {
  if (error == null) return false;
  final lower = error.toString().toLowerCase();
  return lower.contains('jwt issued at future') ||
      lower.contains('pgrst303') ||
      lower.contains('jwt expired') ||
      lower.contains('pgrst301') ||
      lower.contains('invalid jwt');
}

class AsyncBody extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.loading,
    this.error,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
    this.onRetry,
    this.emptyIcon = LucideIcons.inbox,
    this.emptySubtitle,
  });

  final bool loading;
  final String? error;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;
  final VoidCallback? onRetry;
  final IconData emptyIcon;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(),
            ),
            Gap(14),
            Text('Yükleniyor'),
          ],
        ),
      );
    }

    if (error != null) {
      final friendly = formatCatalogError(error!);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Alert(
            destructive: true,
            leading: const Icon(LucideIcons.circleAlert),
            title: const Text('Bir şeyler ters gitti'),
            content: Text(friendly),
            trailing: onRetry == null
                ? null
                : PrimaryButton(
                    onPressed: onRetry,
                    leading: const Icon(LucideIcons.refreshCw, size: 14),
                    child: const Text('Yenile'),
                  ),
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: EmptyStateView(
          icon: emptyIcon,
          title: emptyMessage,
          subtitle: emptySubtitle,
        ),
      );
    }

    return child;
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.toolbar,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? toolbar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow).xSmall().muted(),
                    const Gap(6),
                    Text(title).h3().semiBold(),
                    if (subtitle != null) ...[
                      const Gap(6),
                      Text(subtitle!).small().muted(),
                    ],
                  ],
                ),
              ),
              ..._spaced(actions),
            ],
          ),
          if (toolbar != null) ...[
            const Gap(18),
            toolbar!,
          ],
          const Gap(18),
          Expanded(child: child),
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> items) {
    if (items.isEmpty) return const [];
    return [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const Gap(8),
        items[i],
      ],
    ];
  }
}

class DataPanel extends StatelessWidget {
  const DataPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: Theme.of(context).borderRadiusMd,
        child: child,
      ),
    );
  }
}

class CatalogRow extends StatelessWidget {
  const CatalogRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.meta,
    required this.onEdit,
    required this.onDelete,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? meta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          leading,
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title).semiBold(),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const Gap(2),
                  Text(subtitle!).small().muted(),
                ],
              ],
            ),
          ),
          if (meta != null) ...[
            meta!,
            const Gap(12),
          ],
          IconButton.ghost(
            icon: const Icon(LucideIcons.pencil, size: 16),
            onPressed: onEdit,
          ),
          IconButton.ghost(
            icon: const Icon(LucideIcons.trash2, size: 16),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    if (active) {
      return const PrimaryBadge(child: Text('Aktif'));
    }
    return const SecondaryBadge(child: Text('Pasif'));
  }
}

class MetaChip extends StatelessWidget {
  const MetaChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SecondaryBadge(child: Text(label));
  }
}

class AvatarTile extends StatelessWidget {
  const AvatarTile({
    super.key,
    this.imageUrl,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child;
    if (imageUrl != null) {
      child = Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(fallbackIcon).iconMutedForeground(),
      );
    } else {
      child = Icon(fallbackIcon, color: theme.colorScheme.primary, size: 20);
    }

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: child,
    );
  }
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        OutlineButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('İptal'),
        ),
        DestructiveButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );
  return result == true;
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  showToast(
    context: context,
    builder: (context, overlay) => SurfaceCard(
      child: Basic(
        title: Text(error ? 'Hata' : 'Bilgi'),
        content: Text(message),
        trailing: IconButton.ghost(
          icon: const Icon(LucideIcons.x, size: 14),
          onPressed: overlay.close,
        ),
      ),
    ),
  );
}
