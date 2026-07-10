import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../services/auth_service.dart';
import '../theme/theme_controller.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.child,
    required this.auth,
  });

  final Widget child;
  final AuthService auth;

  static const _allDestinations =
      <({String path, String label, IconData icon, bool adminOnly})>[
    (
      path: '/dashboard',
      label: 'Özet',
      icon: LucideIcons.layoutDashboard,
      adminOnly: false
    ),
    (path: '/brands', label: 'Markalar', icon: LucideIcons.tag, adminOnly: true),
    (
      path: '/models',
      label: 'Modeller',
      icon: LucideIcons.layers,
      adminOnly: true
    ),
    (path: '/cars', label: 'Araçlar', icon: LucideIcons.car, adminOnly: true),
    (
      path: '/workshops',
      label: 'Tamirhane',
      icon: LucideIcons.wrench,
      adminOnly: false
    ),
    (
      path: '/insurance',
      label: 'Sigorta',
      icon: LucideIcons.shield,
      adminOnly: false
    ),
    (
      path: '/users',
      label: 'Kullanıcılar',
      icon: LucideIcons.users,
      adminOnly: true
    ),
  ];

  List<({String path, String label, IconData icon, bool adminOnly})>
      _destinationsFor(UserType? type) {
    final admin = type?.isAdmin ?? false;
    return [
      for (final d in _allDestinations)
        if (admin || !d.adminOnly) d,
    ];
  }

  bool _isSelected(String location, String path) =>
      location == path || location.startsWith('$path/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).uri.path;
    final dests = _destinationsFor(auth.userType);

    return Scaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              border: Border(
                right: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.car,
                          size: 16,
                          color: theme.colorScheme.primaryForeground,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cardex').semiBold(),
                            const Text('Katalog').xSmall().muted(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: const Text('Menü').xSmall().muted(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final d in dests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Button(
                            style: _isSelected(location, d.path)
                                ? const ButtonStyle.secondary()
                                : const ButtonStyle.ghost(),
                            alignment: Alignment.centerLeft,
                            onPressed: () => context.go(d.path),
                            leading: Icon(d.icon, size: 16),
                            child: Text(d.label),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.instance,
                    builder: (context, mode, _) {
                      final dark = mode == ThemeMode.dark;
                      return Row(
                        children: [
                          Icon(
                            dark ? LucideIcons.moon : LucideIcons.sun,
                            size: 16,
                          ).iconMutedForeground(),
                          const Gap(8),
                          Expanded(
                            child: Text(dark ? 'Koyu tema' : 'Açık tema')
                                .small()
                                .muted(),
                          ),
                          Switch(
                            value: dark,
                            onChanged: (v) =>
                                ThemeController.instance.toggleDark(v),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Card(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(auth.username ?? auth.email ?? 'Oturum')
                            .small()
                            .semiBold(),
                        const Gap(2),
                        Text(auth.userType?.labelTr ?? '—').xSmall().muted(),
                        if (auth.email != null && auth.username != null) ...[
                          const Gap(2),
                          Text(auth.email!).xSmall().muted(),
                        ],
                        const Gap(10),
                        OutlineButton(
                          onPressed: () async {
                            await auth.logout();
                            if (context.mounted) context.go('/login');
                          },
                          leading: const Icon(LucideIcons.logOut, size: 14),
                          child: const Text('Çıkış'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
