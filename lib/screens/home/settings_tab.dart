part of 'package:car_data_app/screens/home_screen.dart';

Color _settingsIconColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9);

Color _settingsSelectedBg(BuildContext context) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final bool dark = Theme.of(context).brightness == Brightness.dark;
  return dark
      ? Colors.white.withValues(alpha: 0.12)
      : scheme.onSurface.withValues(alpha: 0.08);
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _notificationsOn = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationsPref();
  }

  Future<void> _loadNotificationsPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsOn = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsOn = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _confirmSignOut() async {
    final AppLocalizations l10n = context.l10n;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.signOutDialogTitle),
        content: Text(l10n.signOutConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await SessionController.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppTokens tokens = context.tokens;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: <Widget>[
        Text(
          l10n.settingsTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),

        ValueListenableBuilder<Session?>(
          valueListenable: SessionController.instance,
          builder: (BuildContext context, Session? session, Widget? _) {
            if (session == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SettingsCard(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: tokens.surfaceMuted,
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: _settingsIconColor(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              session.greetingName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: tokens.mutedText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.signOut,
                        onPressed: _confirmSignOut,
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SectionHeader(
                  icon: Icons.wb_sunny_outlined,
                  label: l10n.themeLabel,
                ),
                const SizedBox(height: 10),
                const _ThemeModeList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SectionHeader(
                  icon: Icons.language_outlined,
                  label: l10n.languageLabel,
                ),
                const SizedBox(height: 10),
                const _LanguageList(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SectionHeader(
                  icon: Icons.straighten_outlined,
                  label: l10n.unitsLabel,
                ),
                const SizedBox(height: 10),
                const _DistanceUnitRow(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.notifications_active_outlined,
                  color: _settingsIconColor(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.notificationsLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.notificationsSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.mutedText,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _notificationsOn,
                  onChanged: _setNotifications,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline, color: _settingsIconColor(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${l10n.versionLabel} 1.0.0',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'STABLE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.tokens.border),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: _settingsIconColor(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: context.tokens.mutedText,
                ),
          ),
        ),
      ],
    );
  }
}

class _ThemeModeList extends StatelessWidget {
  const _ThemeModeList();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeMode mode = ThemeController.instance.value;

    return Row(
      children: <Widget>[
        Expanded(
          child: _CompactChoice(
            label: l10n.themeLight,
            icon: Icons.wb_sunny_outlined,
            selected: mode == ThemeMode.light,
            onTap: () => ThemeController.instance.set(ThemeMode.light),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactChoice(
            label: l10n.themeDark,
            icon: Icons.dark_mode_outlined,
            selected: mode == ThemeMode.dark,
            onTap: () => ThemeController.instance.set(ThemeMode.dark),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactChoice(
            label: l10n.themeSystem,
            icon: Icons.phone_iphone_outlined,
            selected: mode == ThemeMode.system,
            onTap: () => ThemeController.instance.set(ThemeMode.system),
          ),
        ),
      ],
    );
  }
}

class _LanguageList extends StatelessWidget {
  const _LanguageList();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.instance,
      builder: (BuildContext context, Locale? current, Widget? _) {
        final Locale effective = current ?? LocaleController.resolve(null);
        final String tag = effective.languageCode;

        return Row(
          children: <Widget>[
            Expanded(
              child: _CompactChoice(
                label: l10n.languageEnglish,
                selected: tag == 'en',
                onTap: () =>
                    LocaleController.instance.set(const Locale('en')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactChoice(
                label: l10n.languageTurkish,
                selected: tag == 'tr',
                onTap: () =>
                    LocaleController.instance.set(const Locale('tr')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactChoice extends StatelessWidget {
  const _CompactChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Material(
      color: selected ? _settingsSelectedBg(context) : tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : tokens.mutedText,
                ),
                const SizedBox(height: 6),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistanceUnitRow extends StatelessWidget {
  const _DistanceUnitRow();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DistanceUnit>(
      valueListenable: DistanceUnitController.instance,
      builder: (BuildContext context, DistanceUnit current, Widget? _) {
        return Row(
          children: <Widget>[
            Expanded(
              child: _UnitButton(
                label: 'km',
                icon: Icons.speed_outlined,
                selected: current == DistanceUnit.metric,
                onTap: () => DistanceUnitController.instance
                    .set(DistanceUnit.metric),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UnitButton(
                label: 'mi',
                icon: Icons.social_distance_outlined,
                selected: current == DistanceUnit.imperial,
                onTap: () => DistanceUnitController.instance
                    .set(DistanceUnit.imperial),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UnitButton extends StatelessWidget {
  const _UnitButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Material(
      color: selected ? _settingsSelectedBg(context) : tokens.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : tokens.mutedText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
