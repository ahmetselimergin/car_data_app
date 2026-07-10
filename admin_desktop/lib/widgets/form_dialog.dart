import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Tema uyumlu form modalı (Material AlertDialog yerine).
Future<bool?> showFormDialog({
  required BuildContext context,
  required String title,
  String? description,
  required Widget Function(
    BuildContext context,
    void Function(VoidCallback fn) setLocal,
  ) builder,
  String confirmLabel = 'Kaydet',
  String cancelLabel = 'İptal',
  double width = 440,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final theme = Theme.of(ctx);
        final scaling = theme.scaling;
        return ModalBackdrop(
          borderRadius: theme.borderRadiusXxl,
          barrierColor: Colors.black.withValues(alpha: 0.55),
          surfaceClip: ModalBackdrop.shouldClipSurface(theme.surfaceOpacity),
          child: ModalContainer(
            fillColor: theme.colorScheme.popover,
            filled: true,
            borderRadius: theme.borderRadiusXxl,
            borderWidth: 1 * scaling,
            borderColor: theme.colorScheme.border,
            padding: EdgeInsets.all(theme.density.baseContainerPadding * 1.5 * scaling),
            surfaceBlur: theme.surfaceBlur,
            surfaceOpacity: theme.surfaceOpacity,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width, maxHeight: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title).large().semiBold(),
                  if (description != null) ...[
                    const Gap(6),
                    Text(description).small().muted(),
                  ],
                  const Gap(18),
                  Flexible(
                    child: SingleChildScrollView(
                      child: builder(ctx, setLocal),
                    ),
                  ),
                  const Gap(20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlineButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(cancelLabel),
                      ),
                      const Gap(8),
                      PrimaryButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(confirmLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class FormLabeledField extends StatelessWidget {
  const FormLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final String? helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label).small().semiBold(),
        const Gap(6),
        child,
        if (helper != null) ...[
          const Gap(6),
          Text(helper!).xSmall().muted(),
        ],
      ],
    );
  }
}

/// Basit tek seçimli dropdown.
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.placeholder = 'Seç…',
    this.canUnselect = false,
  });

  final T? value;
  final List<(T value, String label)> items;
  final ValueChanged<T?> onChanged;
  final String placeholder;
  final bool canUnselect;

  String _labelOf(T v) {
    for (final item in items) {
      if (item.$1 == v) return item.$2;
    }
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    return Select<T>(
      value: value,
      onChanged: onChanged,
      canUnselect: canUnselect,
      placeholder: Text(placeholder).muted(),
      itemBuilder: (context, item) => Text(_labelOf(item)),
      popup: SelectPopup.noVirtualization(
        items: SelectItemList(
          children: [
            for (final item in items)
              SelectItemButton(
                value: item.$1,
                child: Text(item.$2),
              ),
          ],
        ),
      ).call,
    );
  }
}

class FormActiveSwitch extends StatelessWidget {
  const FormActiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      trailing: const Text('Aktif').small(),
    );
  }
}
