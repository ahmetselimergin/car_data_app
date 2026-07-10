part of 'package:car_data_app/screens/home_screen.dart';

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<({IconData icon, String label})> items =
        <({IconData icon, String label})>[
      (icon: Icons.directions_car_outlined, label: l10n.navMyCars),
      (icon: Icons.notifications_none_rounded, label: l10n.navReminders),
      (icon: Icons.settings_outlined, label: l10n.navSettings),
    ];

    final AppTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;
    final Color onNav = scheme.onSurface;
    final Color selectedPill = dark
        ? Colors.white.withValues(alpha: 0.12)
        : onNav.withValues(alpha: 0.08);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(36),
          border: dark ? Border.all(color: tokens.border) : null,
          boxShadow: dark
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: List<Widget>.generate(items.length, (int i) {
            final bool selected = i == index;
            final ({IconData icon, String label}) item = items[i];
            return Expanded(
              flex: selected ? 2 : 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 8 : 6,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedPill : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        color: selected ? onNav : tokens.mutedText,
                        size: 20,
                      ),
                      if (selected) ...<Widget>[
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              style: TextStyle(
                                color: onNav,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
