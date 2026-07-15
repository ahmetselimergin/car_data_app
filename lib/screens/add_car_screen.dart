import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../data/car_catalog.dart';
import '../l10n/l10n_ext.dart';
import '../models/car_model.dart';
import '../repositories/car_repository.dart';
import '../repositories/supabase_car_repository.dart';
import '../services/background_removal_service.dart';
import '../services/distance_unit_controller.dart';
import '../services/image_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/car_card_palette.dart';
import '../utils/distance_format.dart';
import '../utils/turkish_plate.dart';
import '../utils/user_facing_error.dart';
import '../widgets/app_confirm_dialog.dart';

int _colorToArgb32(Color c) {
  final int a = (c.a * 255).round().clamp(0, 255);
  final int r = (c.r * 255).round().clamp(0, 255);
  final int g = (c.g * 255).round().clamp(0, 255);
  final int b = (c.b * 255).round().clamp(0, 255);
  return (a << 24) | (r << 16) | (g << 8) | b;
}

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key, this.existing});

  final Car? existing;

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CarRepository _repo = SupabaseCarRepository();

  late final TextEditingController _plaka;
  // Marka katalogda yoksa kullanıcının elle girmesi için.
  late final TextEditingController _customMarka;
  late final TextEditingController _customModel;
  late final TextEditingController _km;

  String? _selectedBrand;
  String? _selectedModel;
  int? _selectedYear;
  String? _selectedTransmission;
  String? _selectedFuel;

  bool _saving = false;
  DistanceUnit _distanceUnit = DistanceUnitController.instance.value;

  /// Mevcut araçtan gelen fotoğraf yolu (DB'de kayıtlı, göreli veya eski mutlak).
  String? _existingImagePath;

  /// Önizleme için çözülmüş mutlak yol.
  String? _resolvedExistingAbsolute;

  /// Bu oturumda image_picker ile seçilmiş ama henüz kaydedilmemiş fotoğraf.
  /// Kalıcı dizine ancak "Kaydet"e basınca kopyalanır.
  XFile? _pickedImage;

  /// Seçilen fotoğraf için arka plan silinmiş önizleme (kaydetmeden önce dairede).
  Uint8List? _previewProcessedBytes;

  /// Önizleme için model çalışıyor.
  bool _previewLoading = false;

  /// Kullanıcı bu oturumda fotoğrafı kaldırmak istedi mi?
  bool _imageCleared = false;

  /// Yeni seçilen fotoğrafın arka planı silinsin mi?
  /// Varsayılan: true — uygulamanın "stüdyo" görünümü için.
  bool _removeBackground = true;

  /// "Kaydet"e basıldığında arka plan kaldırma çalışıyorsa kullanıcıya
  /// gösterilen mesaj. UI'daki progress overlay buna bakıyor.
  String? _processingMessage;

  /// Kahraman kart rengi; null = araç id’sine göre otomatik palet.
  Color? _selectedCardColor;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Car? c = widget.existing;
    _plaka = TextEditingController(text: c?.plaka ?? '');
    _customMarka = TextEditingController();
    _customModel = TextEditingController();
    _km = TextEditingController(
      text: c != null && c.km > 0
          ? DistanceFormat.toInputText(
              c.km,
              DistanceUnitController.instance.value,
            )
          : '',
    );
    _distanceUnit = DistanceUnitController.instance.value;
    _existingImagePath = c?.imagePath;
    _selectedCardColor =
        c?.cardColor != null ? Color(c!.cardColor!) : null;
    _selectedTransmission = c?.transmission;
    _selectedFuel = c?.fuelType;

    if (c != null) {
      final List<String> brands = CarCatalog.brandNames;
      if (brands.contains(c.marka)) {
        _selectedBrand = c.marka;
        final List<String> models = CarCatalog.modelsFor(c.marka);
        if (models.contains(c.model)) {
          _selectedModel = c.model;
        } else {
          _selectedModel = CarCatalog.otherModel;
          _customModel.text = c.model;
        }
      } else {
        _selectedBrand = CarCatalog.otherBrand;
        _customMarka.text = c.marka;
        _selectedModel = CarCatalog.otherModel;
        _customModel.text = c.model;
      }
      _selectedYear = c.yil;
    }
    DistanceUnitController.instance.addListener(_onDistanceUnitChanged);
    _resolveExistingImage();
    // Eski "Petrol" kaydını yerelleştirilmiş Benzin’e çevir (çift seçenek olmasın).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final String? normalized = normalizeFuelType(_selectedFuel, context.l10n);
      if (normalized != _selectedFuel) {
        setState(() => _selectedFuel = normalized);
      }
    });
  }

  Future<void> _resolveExistingImage() async {
    final String? raw = _existingImagePath?.trim();
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() => _resolvedExistingAbsolute = null);
      return;
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      if (!mounted) return;
      setState(() => _resolvedExistingAbsolute = raw);
      return;
    }
    final String? resolved =
        await ImageStorageService.instance.resolvePath(raw);
    if (!mounted) return;
    setState(() => _resolvedExistingAbsolute = resolved);
  }

  void _onDistanceUnitChanged() {
    final DistanceUnit next = DistanceUnitController.instance.value;
    if (next == _distanceUnit) return;
    setState(() {
      _km.text = DistanceFormat.convertInputText(_km.text, _distanceUnit, next);
      _distanceUnit = next;
    });
  }

  @override
  void dispose() {
    DistanceUnitController.instance.removeListener(_onDistanceUnitChanged);
    _plaka.dispose();
    _customMarka.dispose();
    _customModel.dispose();
    _km.dispose();
    super.dispose();
  }

  List<String> _transmissionItems(AppLocalizations l10n) {
    final List<String> list =
        List<String>.from(localizedTransmissionOptions(l10n));
    final String? t = _selectedTransmission;
    if (t != null && t.isNotEmpty && !list.contains(t)) {
      list.insert(0, t);
    }
    return list;
  }

  List<String> _fuelItems(AppLocalizations l10n) {
    final List<String> list = List<String>.from(localizedFuelOptions(l10n));
    final String? f = normalizeFuelType(_selectedFuel, l10n);
    if (f != null && f.isNotEmpty && !list.contains(f)) {
      list.insert(0, f);
    }
    return list;
  }

  int _parseKmInput() =>
      DistanceFormat.parseInput(_km.text.trim(), _distanceUnit);

  Future<void> _confirmDelete() async {
    final Car? c = widget.existing;
    if (c?.id == null) return;
    final AppLocalizations l10n = context.l10n;
    final bool ok = await showAppConfirmDialog(
      context: context,
      title: l10n.deleteCarTitle,
      message: l10n.deleteCarMessage(c!.marka, c.model),
      confirmLabel: l10n.delete,
      destructive: true,
      confirmIcon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    try {
      await ImageStorageService.instance.deleteIfExists(_existingImagePath);
      await _repo.deleteCar(c.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.carDeleted)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _resolvedBrand {
    if (_selectedBrand == CarCatalog.otherBrand) {
      return _customMarka.text.trim();
    }
    return _selectedBrand?.trim() ?? '';
  }

  String get _resolvedModel {
    if (_selectedBrand == CarCatalog.otherBrand ||
        _selectedModel == CarCatalog.otherModel) {
      return _customModel.text.trim();
    }
    return _selectedModel?.trim() ?? '';
  }

  /// `image_cropper` yalnızca Android / iOS native’de kayıtlıdır (web ve masaüstü yok).
  static bool get _supportsNativeCrop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Web veya masaüstünde kırpma yok; mobilde plugin yoksa [MissingPluginException] —
  /// uygulamayı tamamen durdurup `flutter run` ile yeniden derleyin (hot reload yetmez).
  Future<XFile?> _cropPickedFile(XFile picked) async {
    if (!_supportsNativeCrop) return picked;
    final AppLocalizations l10n = context.l10n;
    try {
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        maxWidth: 2048,
        maxHeight: 2048,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        uiSettings: <PlatformUiSettings>[
          AndroidUiSettings(
            toolbarTitle: l10n.cropPhotoTitle,
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.white,
            statusBarLight: false,
            navBarLight: false,
            lockAspectRatio: false,
            aspectRatioPresets: const <CropAspectRatioPresetData>[
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: l10n.cropTitle,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
          ),
        ],
      );
      if (cropped == null) return null;
      return XFile(cropped.path);
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cropPluginMissing)),
        );
      }
      return picked;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingError(e, l10n))),
        );
      }
      return picked;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file == null || !mounted) return;
      final XFile? cropped = await _cropPickedFile(file);
      if (!mounted || cropped == null) return;
      setState(() {
        _pickedImage = cropped;
        _imageCleared = false;
        _previewProcessedBytes = null;
        _previewLoading = false;
      });
      await _runBackgroundPreviewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(e, context.l10n))),
      );
    }
  }

  Future<void> _showImagePickerSheet() async {
    final AppLocalizations l10n = context.l10n;
    final bool hasImage = _pickedImage != null ||
        (!_imageCleared &&
            (_resolvedExistingAbsolute?.isNotEmpty ?? false));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext c) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.of(c).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chooseFromGallery),
                onTap: () {
                  Navigator.of(c).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_pickedImage != null && _supportsNativeCrop)
                ListTile(
                  leading: const Icon(Icons.crop_outlined),
                  title: Text(l10n.recrop),
                  onTap: () async {
                    Navigator.of(c).pop();
                    final XFile? cropped =
                        await _cropPickedFile(_pickedImage!);
                    if (!mounted || cropped == null) return;
                    setState(() {
                      _pickedImage = cropped;
                      _previewProcessedBytes = null;
                      _previewLoading = false;
                    });
                    await _runBackgroundPreviewIfNeeded();
                  },
                ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: Text(l10n.removePhoto,
                      style: const TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.of(c).pop();
                    setState(() {
                      _pickedImage = null;
                      _imageCleared = true;
                      _previewProcessedBytes = null;
                      _previewLoading = false;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final AppLocalizations l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.yearNotSelected)),
      );
      return;
    }
    if (_selectedTransmission == null || _selectedTransmission!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transmissionNotSelected)),
      );
      return;
    }
    if (_selectedFuel == null || _selectedFuel!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fuelNotSelected)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String? finalImagePath = _existingImagePath;

      if (_pickedImage != null) {
        String saved;
        if (_removeBackground) {
          if (mounted) {
            setState(() => _processingMessage = l10n.removingBackground);
          }
          final List<int> rawBytes =
              await File(_pickedImage!.path).readAsBytes();
          final Uint8List? cutout = await BackgroundRemovalService.instance
              .removeBackground(Uint8List.fromList(rawBytes));
          if (cutout != null) {
            saved = await ImageStorageService.instance
                .saveCarImageBytes(cutout, extension: '.png');
          } else {
            // Model başarısızsa orijinal fotoğrafa fallback yap.
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.backgroundRemovalFailed)),
              );
            }
            saved = await ImageStorageService.instance
                .saveCarImage(_pickedImage!.path);
          }
        } else {
          saved = await ImageStorageService.instance
              .saveCarImage(_pickedImage!.path);
        }
        if (_existingImagePath != null && _existingImagePath != saved) {
          await ImageStorageService.instance
              .deleteIfExists(_existingImagePath);
        }
        finalImagePath = saved;
      } else if (_imageCleared) {
        await ImageStorageService.instance.deleteIfExists(_existingImagePath);
        finalImagePath = null;
      } else if (finalImagePath != null &&
          finalImagePath.isNotEmpty &&
          !ImageStorageService.isRemoteUrl(finalImagePath)) {
        // Eski mutlak yolu göreli forma çevir (HTTP URL'lere dokunma).
        final String? resolved =
            await ImageStorageService.instance.resolvePath(finalImagePath);
        if (resolved != null) {
          finalImagePath =
              ImageStorageService.instance.toRelative(resolved);
        }
      }

      final Car car = Car(
        id: widget.existing?.id,
        plaka: TurkishPlateValidator.normalize(_plaka.text),
        marka: _resolvedBrand,
        model: _resolvedModel,
        yil: _selectedYear!,
        imagePath: finalImagePath,
        cardColor: _selectedCardColor != null
            ? _colorToArgb32(_selectedCardColor!)
            : null,
        km: _parseKmInput(),
        transmission: _selectedTransmission,
        fuelType: _selectedFuel,
      );

      if (_isEdit) {
        await _repo.updateCar(car);
      } else {
        await _repo.addCar(car);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEdit ? l10n.carUpdated : l10n.carAdded)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(e, l10n))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _processingMessage = null;
        });
      }
    }
  }

  Widget _buildColorPicker() {
    final AppLocalizations l10n = context.l10n;
    final int? autoSeed = widget.existing?.id;
    final Color autoColor = CarCardPalette.autoFor(autoSeed);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.palette_outlined,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.cardColorLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              if (_selectedCardColor != null)
                TextButton(
                  onPressed: () =>
                      setState(() => _selectedCardColor = null),
                  child: Text(l10n.cardColorAuto),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CarCardPalette.colors.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (BuildContext c, int i) {
                if (i == 0) {
                  final bool selected = _selectedCardColor == null;
                  return _ColorDot(
                    color: autoColor,
                    selected: selected,
                    showAutoBadge: true,
                    onTap: () => setState(() => _selectedCardColor = null),
                  );
                }
                final Color color = CarCardPalette.colors[i - 1];
                final bool selected = _selectedCardColor != null &&
                    _colorToArgb32(_selectedCardColor!) ==
                        _colorToArgb32(color);
                return _ColorDot(
                  color: color,
                  selected: selected,
                  onTap: () => setState(() => _selectedCardColor = color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgRemovalToggle() {
    final AppLocalizations l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.auto_fix_high,
              color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.autoRemoveBackground,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Switch.adaptive(
            value: _removeBackground,
            onChanged: (bool v) async {
              setState(() => _removeBackground = v);
              await _runBackgroundPreviewIfNeeded();
            },
          ),
        ],
      ),
    );
  }

  ImageProvider? _effectiveImageProvider() {
    if (_pickedImage != null) {
      if (_removeBackground) {
        if (_previewLoading) {
          return null;
        }
        if (_previewProcessedBytes != null) {
          return MemoryImage(_previewProcessedBytes!);
        }
        return FileImage(File(_pickedImage!.path));
      }
      return FileImage(File(_pickedImage!.path));
    }
    if (!_imageCleared &&
        (_resolvedExistingAbsolute?.isNotEmpty ?? false)) {
      final String path = _resolvedExistingAbsolute!;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return NetworkImage(path);
      }
      if (File(path).existsSync()) {
        return FileImage(File(path));
      }
    }
    return null;
  }

  Future<void> _runBackgroundPreviewIfNeeded() async {
    final XFile? pick = _pickedImage;
    if (pick == null || !mounted) {
      return;
    }
    if (!_removeBackground) {
      if (mounted) {
        setState(() {
          _previewProcessedBytes = null;
          _previewLoading = false;
        });
      }
      return;
    }

    setState(() {
      _previewLoading = true;
      _previewProcessedBytes = null;
    });

    try {
      final Uint8List rawBytes = await File(pick.path).readAsBytes();
      final Uint8List? cutout =
          await BackgroundRemovalService.instance.removeBackground(rawBytes);
      if (!mounted || _pickedImage?.path != pick.path) {
        return;
      }
      setState(() {
        _previewLoading = false;
        _previewProcessedBytes = cutout;
      });
      if (cutout == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.backgroundPreviewFailed)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Widget _buildImagePicker() {
    final ImageProvider? provider = _effectiveImageProvider();
    final DecorationImage? plateDeco = provider != null && !_previewLoading
        ? DecorationImage(
            image: provider,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          )
        : null;
    final bool hasPhoto = plateDeco != null;

    final double frameW = (MediaQuery.sizeOf(context).width - 40)
        .clamp(260.0, 400.0);
    final double frameH = frameW * 0.56;

    return GestureDetector(
      onTap: _showImagePickerSheet,
      child: Container(
        width: frameW,
        height: frameH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppTheme.primary.withValues(alpha: 0.10),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          image: plateDeco,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (_previewLoading)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else if (!hasPhoto)
              Icon(
                Icons.directions_car_rounded,
                size: 64,
                color: AppTheme.primary.withValues(alpha: 0.42),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasPhoto
                      ? Icons.edit_outlined
                      : Icons.add_photo_alternate_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> brandItems = <String>[
      ...CarCatalog.brandNames,
      CarCatalog.otherBrand,
    ];

    final bool brandIsOther = _selectedBrand == CarCatalog.otherBrand;
    final List<String> modelItems = brandIsOther
        ? const <String>[]
        : <String>[
            if (_selectedBrand != null)
              ...CarCatalog.modelsFor(_selectedBrand!),
            CarCatalog.otherModel,
          ];
    final bool modelIsOther =
        brandIsOther || _selectedModel == CarCatalog.otherModel;

    String catalogLabel(String value) =>
        value == CarCatalog.otherBrand || value == CarCatalog.otherModel
            ? l10n.catalogOther
            : value;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editCarTitle : l10n.newCarTitle),
        actions: _isEdit
            ? <Widget>[
                IconButton(
                  tooltip: l10n.deleteCarTooltip,
                  onPressed: _saving ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ]
            : null,
      ),
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Center(child: _buildImagePicker()),
              const SizedBox(height: 12),
              if (_pickedImage != null) ...<Widget>[
                _buildBgRemovalToggle(),
                const SizedBox(height: 12),
              ],
              _buildColorPicker(),
              const SizedBox(height: 14),
              TextFormField(
                controller: _plaka,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: <TextInputFormatter>[
                  TurkishPlateInputFormatter(maxLength: 12),
                ],
                decoration: InputDecoration(
                  labelText: l10n.plateLabel,
                  hintText: l10n.plateHint,
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                ),
                validator: (String? value) => plateFormError(
                  l10n,
                  value,
                  TurkishPlateValidator.isValid,
                  (String c) =>
                      RegExp(r'[ÇŞİÖÜĞçşıöüğı]').hasMatch(c),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedBrand,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.brandLabel,
                  prefixIcon: const Icon(Icons.factory_outlined),
                ),
                items: brandItems
                    .map((String b) => DropdownMenuItem<String>(
                          value: b,
                          child: Text(catalogLabel(b)),
                        ))
                    .toList(),
                onChanged: (String? v) {
                  setState(() {
                    _selectedBrand = v;
                    _selectedModel = null;
                    _customModel.clear();
                    if (v != CarCatalog.otherBrand) {
                      _customMarka.clear();
                    }
                  });
                },
                validator: (String? v) =>
                    v == null || v.isEmpty ? l10n.selectBrand : null,
              ),
              if (brandIsOther) ...<Widget>[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _customMarka,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.customBrandLabel,
                    hintText: l10n.customBrandHint,
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                  validator: (String? v) => (v ?? '').trim().isEmpty
                      ? l10n.customBrandRequired
                      : null,
                ),
              ],
              const SizedBox(height: 14),
              if (!brandIsOther)
                DropdownButtonFormField<String>(
                  initialValue: _selectedModel,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.modelLabel,
                    prefixIcon: const Icon(Icons.directions_car_outlined),
                  ),
                  items: modelItems
                      .map((String m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(catalogLabel(m)),
                          ))
                      .toList(),
                  onChanged: _selectedBrand == null
                      ? null
                      : (String? v) {
                          setState(() {
                            _selectedModel = v;
                            if (v != CarCatalog.otherModel) {
                              _customModel.clear();
                            }
                          });
                        },
                  validator: (String? v) =>
                      v == null || v.isEmpty ? l10n.selectModel : null,
                ),
              if (modelIsOther) ...<Widget>[
                if (!brandIsOther) const SizedBox(height: 14),
                TextFormField(
                  controller: _customModel,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.customModelLabel,
                    hintText: l10n.customModelHint,
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                  validator: (String? v) => (v ?? '').trim().isEmpty
                      ? l10n.customModelRequired
                      : null,
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.yearLabel,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                items: CarCatalog.yearOptions()
                    .map((int y) => DropdownMenuItem<int>(
                          value: y,
                          child: Text(y.toString()),
                        ))
                    .toList(),
                onChanged: (int? v) => setState(() => _selectedYear = v),
                validator: (int? v) => v == null ? l10n.selectYear : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _km,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s.,]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: InputDecoration(
                  labelText: DistanceFormat.fieldLabel(l10n, _distanceUnit),
                  hintText: DistanceFormat.fieldHint(l10n, _distanceUnit),
                  prefixIcon: const Icon(Icons.speed_outlined),
                ),
                validator: (String? v) {
                  final String t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final String digits = t.replaceAll(RegExp(r'[^\d]'), '');
                  if (digits.isEmpty) return l10n.mileageInvalid;
                  if (int.tryParse(digits) == null) return l10n.mileageInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedTransmission,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.transmissionLabel,
                  prefixIcon: const Icon(Icons.settings_suggest_outlined),
                ),
                items: _transmissionItems(l10n)
                    .map(
                      (String t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(t),
                      ),
                    )
                    .toList(),
                onChanged: (String? v) =>
                    setState(() => _selectedTransmission = v),
                validator: (String? v) =>
                    v == null || v.isEmpty ? l10n.selectTransmission : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedFuel,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.fuelTypeLabel,
                  prefixIcon: const Icon(Icons.local_gas_station_outlined),
                ),
                items: _fuelItems(l10n)
                    .map(
                      (String t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(t),
                      ),
                    )
                    .toList(),
                onChanged: (String? v) => setState(() => _selectedFuel = v),
                validator: (String? v) =>
                    v == null || v.isEmpty ? l10n.selectFuel : null,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isEdit ? l10n.updateButton : l10n.saveButton),
              ),
            ],
          ),
            ),
          ),
          if (_processingMessage != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _processingMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    this.showAutoBadge = false,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool showAutoBadge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: selected ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: showAutoBadge
            ? const Icon(Icons.auto_awesome, color: Colors.white, size: 18)
            : (selected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null),
      ),
    );
  }
}
