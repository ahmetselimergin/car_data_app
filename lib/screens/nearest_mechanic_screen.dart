import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// "En Yakın Tamirci" — Supabase'deki servisleri, kullanıcı konumuna göre
/// (adresten geocode ederek) en yakından uzağa sıralı liste hâlinde gösterir.
class NearestMechanicScreen extends StatefulWidget {
  const NearestMechanicScreen({super.key});

  @override
  State<NearestMechanicScreen> createState() => _NearestMechanicScreenState();
}

class _Workshop {
  _Workshop({
    required this.name,
    this.phone,
    this.address,
    this.city,
    this.lat,
    this.lng,
    this.distanceMeters,
  });
  final String name;
  final String? phone;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;
  final double? distanceMeters;
}

class _NearestMechanicScreenState extends State<NearestMechanicScreen> {
  List<_Workshop> _items = <_Workshop>[];
  List<String> _cities = <String>[]; // filtre için (sıralı, tekil iller)
  String? _selectedCity; // null = tüm iller
  bool _loading = true;
  String? _error;

  // Seçili ile göre süzülmüş liste (mesafe sırası korunur).
  List<_Workshop> get _visibleItems => _selectedCity == null
      ? _items
      : _items.where((_Workshop w) => w.city == _selectedCity).toList();

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
      final Position? me = await _resolveLocation();
      final List<dynamic> rows = await Supabase.instance.client
          .from('workshops')
          .select('name, phone, address, city, lat, lng, active')
          .eq('active', true);

      final List<_Workshop> list = <_Workshop>[];
      for (final dynamic row in rows) {
        final Map<String, dynamic> w = Map<String, dynamic>.from(row as Map);
        final String? address = w['address'] as String?;
        final String? city = (w['city'] as String?)?.trim();
        final double? lat = (w['lat'] as num?)?.toDouble();
        final double? lng = (w['lng'] as num?)?.toDouble();
        double? distance;
        if (me != null) {
          if (lat != null && lng != null) {
            // Kayıtlı kesin koordinat: anında, geocode'a gerek yok.
            distance = Geolocator.distanceBetween(
              me.latitude,
              me.longitude,
              lat,
              lng,
            );
          } else if (address != null && address.trim().isNotEmpty) {
            // Konumu olmayan eski kayıtlar için adresten geocode (yedek).
            distance = await _distanceTo(me, address);
          }
        }
        list.add(
          _Workshop(
            name: (w['name'] as String?) ?? 'Servis',
            phone: w['phone'] as String?,
            address: address,
            city: (city != null && city.isNotEmpty) ? city : null,
            lat: lat,
            lng: lng,
            distanceMeters: distance,
          ),
        );
      }

      // Filtre için tekil illeri topla, alfabetik (Türkçe) sırala.
      final List<String> cities = list
          .map((_Workshop w) => w.city)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort((String a, String b) =>
            a.toLowerCase().compareTo(b.toLowerCase()));

      // Mesafesi olanlar önce (yakından uzağa), olmayanlar sona.
      list.sort((a, b) {
        if (a.distanceMeters == null && b.distanceMeters == null) return 0;
        if (a.distanceMeters == null) return 1;
        if (b.distanceMeters == null) return -1;
        return a.distanceMeters!.compareTo(b.distanceMeters!);
      });

      if (!mounted) return;
      setState(() {
        _items = list;
        _cities = cities;
        // Seçili il artık listede yoksa filtreyi sıfırla.
        if (_selectedCity != null && !cities.contains(_selectedCity)) {
          _selectedCity = null;
        }
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

  Future<Position?> _resolveLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<double?> _distanceTo(Position me, String address) async {
    try {
      final List<Location> locs = await locationFromAddress(address);
      if (locs.isEmpty) return null;
      return Geolocator.distanceBetween(
        me.latitude,
        me.longitude,
        locs.first.latitude,
        locs.first.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _call(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // Tarayıcı yerine cihazın harita uygulamasını aç. Önce kesin koordinat
  // (varsa), yoksa adres. iOS -> Apple Maps, Android -> geo: (harita seçici).
  Future<void> _directions(_Workshop w) async {
    final bool hasCoord = w.lat != null && w.lng != null;
    final String coord = hasCoord ? '${w.lat},${w.lng}' : '';
    final String label = Uri.encodeComponent(w.name);
    final String query =
        hasCoord ? coord : Uri.encodeComponent(w.address ?? w.name);

    final Uri primary = Platform.isIOS
        ? Uri.parse(hasCoord
            ? 'https://maps.apple.com/?daddr=$coord&dirflg=d'
            : 'https://maps.apple.com/?q=$query')
        : Uri.parse(hasCoord
            ? 'geo:$coord?q=$coord($label)'
            : 'geo:0,0?q=$query');

    if (await canLaunchUrl(primary)) {
      await launchUrl(primary, mode: LaunchMode.externalApplication);
      return;
    }
    // Harita uygulaması yoksa son çare: Google Maps web.
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  String _distanceLabel(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // Karta basınca sağdan kayarak açılan detay paneli.
  void _showDetails(_Workshop w) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kapat',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (BuildContext context, _, _) => Align(
        alignment: Alignment.centerRight,
        child: _WorkshopDetailSheet(
          w: w,
          distanceLabel: w.distanceMeters == null
              ? null
              : _distanceLabel(w.distanceMeters!),
          onCall: w.phone == null ? null : () => _call(w.phone!),
          onDirections: (w.address == null && w.lat == null)
              ? null
              : () => _directions(w),
        ),
      ),
      transitionBuilder: (BuildContext context, Animation<double> anim, _,
          Widget child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('En Yakın Tamirci'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        title: 'Servisler yüklenemedi',
        subtitle: 'Bağlantını kontrol edip tekrar dene.',
        onRetry: _load,
      );
    }
    if (_items.isEmpty) {
      return _CenteredMessage(
        icon: Icons.build_circle_outlined,
        title: 'Kayıtlı servis yok',
        subtitle: 'Yakında buraya tamirciler eklenecek.',
        onRetry: _load,
      );
    }
    final List<_Workshop> items = _visibleItems;
    return Column(
      children: <Widget>[
        if (_cities.isNotEmpty) _buildCityFilter(context, items.length),
        Expanded(
          child: items.isEmpty
              ? _CenteredMessage(
                  icon: Icons.location_city_outlined,
                  title: 'Bu ilde servis yok',
                  subtitle: 'Farklı bir il seç veya filtreyi temizle.',
                  onRetry: () => setState(() => _selectedCity = null),
                  retryLabel: 'Filtreyi temizle',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) => _WorkshopCard(
                      w: items[i],
                      distanceLabel: items[i].distanceMeters == null
                          ? null
                          : _distanceLabel(items[i].distanceMeters!),
                      onTap: () => _showDetails(items[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCityFilter(BuildContext context, int visibleCount) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: <Widget>[
          Icon(Icons.filter_alt_outlined,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: _selectedCity,
                hint: const Text('Tüm iller'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    child: Text('Tüm iller'),
                  ),
                  ..._cities.map(
                    (String c) => DropdownMenuItem<String?>(
                      value: c,
                      child: Text(c),
                    ),
                  ),
                ],
                onChanged: (String? v) => setState(() => _selectedCity = v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$visibleCount servis',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Kompakt, tıklanabilir satır kart. Ayrıntılar (adres/telefon/yol tarifi)
/// tıklayınca açılan [_WorkshopDetailSheet]'te gösterilir.
class _WorkshopCard extends StatelessWidget {
  const _WorkshopCard({
    required this.w,
    required this.distanceLabel,
    required this.onTap,
  });

  final _Workshop w;
  final String? distanceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset('assets/images/favicon.png',
                    width: 22, height: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (w.city != null)
                      Text(
                        w.city!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (distanceLabel != null)
                Text(
                  distanceLabel!,
                  style: const TextStyle(
                    color: Color(0xFF0E7C63),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sağdan açılan detay paneli: adres, telefon ve yol tarifi.
class _WorkshopDetailSheet extends StatelessWidget {
  const _WorkshopDetailSheet({
    required this.w,
    required this.distanceLabel,
    required this.onCall,
    required this.onDirections,
  });

  final _Workshop w;
  final String? distanceLabel;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double width =
        (MediaQuery.of(context).size.width * 0.86).clamp(280.0, 380.0);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset('assets/images/favicon.png',
                          width: 26, height: 26),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  w.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    if (w.city != null) ...<Widget>[
                      const Icon(Icons.location_city,
                          size: 15, color: Color(0xFF0E7C63)),
                      const SizedBox(width: 4),
                      Text(w.city!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF0E7C63))),
                    ],
                    if (distanceLabel != null) ...<Widget>[
                      const SizedBox(width: 12),
                      const Icon(Icons.near_me,
                          size: 14, color: Color(0xFF0E7C63)),
                      const SizedBox(width: 4),
                      Text(distanceLabel!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF0E7C63))),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      if (w.address != null && w.address!.trim().isNotEmpty)
                        _InfoRow(
                          icon: Icons.place_outlined,
                          label: 'Adres',
                          value: w.address!,
                        ),
                      if (w.phone != null && w.phone!.trim().isNotEmpty)
                        _InfoRow(
                          icon: Icons.call_outlined,
                          label: 'Telefon',
                          value: w.phone!,
                          onTap: onCall,
                        ),
                    ],
                  ),
                ),
                if (onCall != null) ...<Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Ara'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Yol Tarifi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: onTap != null ? const Color(0xFF0E7C63) : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
    this.retryLabel = 'Yenile',
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
