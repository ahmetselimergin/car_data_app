part of 'package:car_data_app/screens/home_screen.dart';

class _EmptyGarage extends StatelessWidget {
  const _EmptyGarage({required this.onAddCar});
  final VoidCallback onAddCar;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Center(
      child: UndrawEmptyState(
        illustration: UnDrawIllustration.electric_car,
        title: l10n.emptyGarageTitle,
        subtitle: l10n.emptyGarageSubtitle,
        height: 210,
        action: SizedBox(
          width: 240,
          child: FilledButton.icon(
            onPressed: onAddCar,
            icon: const Icon(Icons.add),
            label: Text(l10n.addFirstCar),
          ),
        ),
      ),
    );
  }
}
