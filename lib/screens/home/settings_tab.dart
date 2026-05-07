part of 'package:car_data_app/screens/home_screen.dart';

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Ayarlar',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),

        // Theme selector
        _settingsCard(context, <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: <Widget>[
                Icon(Icons.brightness_6_outlined, color: AppTheme.primary),
                SizedBox(width: 12),
                Text(
                  'Tema',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
          ),
          const _ThemeModeSelector(),
          const SizedBox(height: 12),
        ]),

        const SizedBox(height: 12),

        _settingsCard(context, const <Widget>[
          ListTile(
            leading: Icon(Icons.notifications_active_outlined,
                color: AppTheme.primary),
            title: Text('Bildirimler'),
            subtitle: Text(
                'Hatırlatıcı tarihinden 7 gün önce bildirim gönderilir.'),
          ),
        ]),
        const SizedBox(height: 12),
        _settingsCard(context, const <Widget>[
          ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.primary),
            title: Text('Sürüm'),
            subtitle: Text('1.0.0'),
          ),
        ]),
      ],
    );
  }

  Widget _settingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  static Widget _segmentLabel(String text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle segmentTextStyle =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 13);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (BuildContext context, ThemeMode mode, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined, size: 18),
                label: _segmentLabel('Aydınlık'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined, size: 18),
                label: _segmentLabel('Karanlık'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                label: _segmentLabel('Sistem'),
              ),
            ],
            selected: <ThemeMode>{mode},
            onSelectionChanged: (Set<ThemeMode> set) {
              ThemeController.instance.set(set.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              ),
              textStyle: WidgetStatePropertyAll<TextStyle>(segmentTextStyle),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
