part of 'package:car_data_app/screens/home_screen.dart';

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final List<_NavItem> items = const <_NavItem>[
      _NavItem(icon: Icons.directions_car_outlined, label: 'Araçlarım'),
      _NavItem(icon: Icons.notifications_none_rounded, label: 'Hatırlatıcılar'),
      _NavItem(icon: Icons.settings_outlined, label: 'Ayarlar'),
    ];

    final AppTokens tokens = context.tokens;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
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
            final _NavItem item = items[i];
            // Seçili sekme ikon + etiket gösterdiği için daha geniş pay verilir;
            // aksi halde "Hatırlatıcılar" gibi uzun metinler kesilir.
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
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        color:
                            selected ? AppTheme.primary : tokens.mutedText,
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
                              style: const TextStyle(
                                color: AppTheme.primary,
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

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
