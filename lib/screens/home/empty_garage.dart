part of 'package:car_data_app/screens/home_screen.dart';

class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage({required this.onAddCar});
  final VoidCallback onAddCar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car,
                  size: 60, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text('Garaja hoş geldin',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Araçlarını ekle, sigorta, kasko, muayene gibi tarihleri '
                'takip et ve bakım geçmişini tek yerde tut.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              child: FilledButton.icon(
                onPressed: onAddCar,
                icon: const Icon(Icons.add),
                label: const Text('İlk aracını ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
