import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../services/catalog_service.dart';
import '../services/users_service.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.catalog,
    required this.users,
    required this.isAdmin,
  });

  final CatalogService catalog;
  final UsersService users;
  final bool isAdmin;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _loading = true;
  String? _error;
  int _cars = 0;
  int _brands = 0;
  int _models = 0;
  int _workshops = 0;
  int _insurance = 0;
  int _users = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final futures = <Future<List<dynamic>>>[
        widget.catalog.listCars(),
        widget.catalog.listBrands(),
        widget.catalog.listModels(),
        widget.catalog.listWorkshops(),
        widget.catalog.listInsurance(),
      ];
      if (widget.isAdmin) {
        futures.add(widget.users.listUsers());
      }
      final results = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _cars = results[0].length;
        _brands = results[1].length;
        _models = results[2].length;
        _workshops = results[3].length;
        _insurance = results[4].length;
        _users = widget.isAdmin && results.length > 5 ? results[5].length : 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Günaydın'
        : hour < 18
            ? 'İyi günler'
            : 'İyi akşamlar';

    return AdminPage(
      eyebrow: 'Konsol',
      title: greeting,
      subtitle: 'Katalog özeti — yönetmek için bir karta tıkla.',
      actions: [
        IconButton.ghost(
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: _load,
        ),
      ],
      child: AsyncBody(
        loading: _loading,
        error: _error,
        isEmpty: false,
        emptyMessage: '',
        onRetry: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 1200
                ? 6
                : w >= 900
                    ? 4
                    : w >= 600
                        ? 3
                        : 2;
            final cards = <_StatSpec>[
              _StatSpec('Araçlar', _cars, LucideIcons.car, '/cars',
                  'Plaka kayıtları'),
              _StatSpec('Markalar', _brands, LucideIcons.tag, '/brands',
                  'Logo & sıralama'),
              _StatSpec('Modeller', _models, LucideIcons.layers, '/models',
                  'Kasa & yıllar'),
              _StatSpec('Tamirhane', _workshops, LucideIcons.wrench,
                  '/workshops', 'Servis ağı'),
              _StatSpec('Sigorta', _insurance, LucideIcons.shield, '/insurance',
                  'Trafik & kasko'),
              if (widget.isAdmin)
                _StatSpec('Kullanıcılar', _users, LucideIcons.users, '/users',
                    'Hesap & roller'),
            ];

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 140,
              ),
              itemCount: cards.length,
              itemBuilder: (context, i) {
                final s = cards[i];
                return CardButton(
                  onPressed: () => context.go(s.path),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(s.icon, size: 18).iconMutedForeground(),
                            const Spacer(),
                            const Icon(LucideIcons.arrowUpRight, size: 14)
                                .iconMutedForeground(),
                          ],
                        ),
                        const Spacer(),
                        Text('${s.count}').h3().semiBold(),
                        const Gap(4),
                        Text(s.title).small().semiBold(),
                        const Gap(2),
                        Text(s.caption).xSmall().muted(),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatSpec {
  const _StatSpec(this.title, this.count, this.icon, this.path, this.caption);
  final String title;
  final int count;
  final IconData icon;
  final String path;
  final String caption;
}
