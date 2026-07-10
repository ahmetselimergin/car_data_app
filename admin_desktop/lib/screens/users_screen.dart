import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/users_service.dart';
import '../widgets/common.dart';
import '../widgets/form_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, required this.users});

  final UsersService users;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  var _loading = true;
  String? _error;
  List<ProfileUser> _items = [];

  String? get _selfId => Supabase.instance.client.auth.currentUser?.id;

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
      final items = await widget.users.listUsers();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _openCreate() async {
    final email = TextEditingController();
    final username = TextEditingController();
    final password = TextEditingController();
    var userType = 'normal_user';

    final saved = await showFormDialog(
      context: context,
      title: 'Yeni kullanıcı',
      confirmLabel: 'Oluştur',
      builder: (ctx, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormLabeledField(
            label: 'E-posta',
            child: TextField(
              controller: email,
              placeholder: const Text('ornek@mail.com'),
              keyboardType: TextInputType.emailAddress,
              features: const [
                InputLeadingFeature(Icon(LucideIcons.mail, size: 16)),
              ],
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Kullanıcı adı',
            helper: 'a-z, 0-9, _ · 3–32 karakter',
            child: TextField(
              controller: username,
              placeholder: const Text('kullanici_adi'),
              features: const [
                InputLeadingFeature(Icon(LucideIcons.user, size: 16)),
              ],
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Şifre',
            helper: 'En az 6 karakter',
            child: TextField(
              controller: password,
              obscureText: true,
              placeholder: const Text('••••••••'),
              features: const [
                InputLeadingFeature(Icon(LucideIcons.lock, size: 16)),
                InputPasswordToggleFeature(),
              ],
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Tip',
            child: AppSelect<String>(
              value: userType,
              items: [
                for (final t in ProfileUser.typeOptions) (t.$1, t.$2),
              ],
              onChanged: (v) => setLocal(() => userType = v ?? 'normal_user'),
            ),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await widget.users.createUser(
        email: email.text,
        password: password.text,
        username: username.text,
        userType: userType,
      );
      await _load();
      if (mounted) showSnack(context, 'Kullanıcı oluşturuldu.');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _openEdit(ProfileUser user) async {
    final username = TextEditingController(text: user.username);
    var userType = user.userType;
    final isSelf = user.id == _selfId;

    final saved = await showFormDialog(
      context: context,
      title: 'Kullanıcıyı düzenle',
      description: user.email,
      builder: (ctx, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormLabeledField(
            label: 'Kullanıcı adı',
            helper: 'a-z, 0-9, _ · 3–32 karakter',
            child: TextField(
              controller: username,
              placeholder: const Text('kullanici_adi'),
            ),
          ),
          const Gap(14),
          FormLabeledField(
            label: 'Tip',
            helper: isSelf ? 'Kendi tipini düşürmek paneli kilitler.' : null,
            child: AppSelect<String>(
              value: userType,
              items: [
                for (final t in ProfileUser.typeOptions) (t.$1, t.$2),
              ],
              onChanged: (v) => setLocal(() => userType = v ?? 'normal_user'),
            ),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      final nextUsername = username.text.trim().toLowerCase();
      if (nextUsername != user.username) {
        await widget.users.updateUsername(user.id, nextUsername);
      }
      if (userType != user.userType) {
        await widget.users.updateUserType(user.id, userType);
      }
      await _load();
      if (mounted) showSnack(context, 'Kaydedildi.');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _delete(ProfileUser user) async {
    if (user.id == _selfId) {
      showSnack(context, 'Kendi hesabını silemezsin.', error: true);
      return;
    }
    final ok = await confirmDelete(
      context,
      title: 'Kullanıcıyı sil',
      message:
          '"${user.username}" (${user.email}) kalıcı olarak silinsin mi?\n'
          'Auth hesabı ve profil birlikte silinir.',
    );
    if (!ok) return;
    try {
      await widget.users.deleteUser(user.id);
      await _load();
      if (mounted) showSnack(context, 'Kullanıcı silindi.');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      eyebrow: 'Hesaplar',
      title: 'Kullanıcılar',
      subtitle: '${_items.length} hesap',
      actions: [
        IconButton.ghost(
          onPressed: _load,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
        ),
        PrimaryButton(
          onPressed: _openCreate,
          leading: const Icon(LucideIcons.plus, size: 14),
          child: const Text('Ekle'),
        ),
      ],
      child: AsyncBody(
        loading: _loading,
        error: _error,
        isEmpty: _items.isEmpty,
        emptyMessage: 'Kullanıcı yok.',
        emptySubtitle: 'Yeni hesap ekleyerek başla.',
        emptyIcon: LucideIcons.users,
        onRetry: _load,
        child: DataPanel(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final u = _items[i];
              final self = u.id == _selfId;
              return CatalogRow(
                leading: const AvatarTile(fallbackIcon: LucideIcons.user),
                title: u.username,
                subtitle: u.email,
                meta: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MetaChip(u.typeLabel),
                    if (self) ...[
                      const Gap(8),
                      const MetaChip('Sen'),
                    ],
                  ],
                ),
                onEdit: () => _openEdit(u),
                onDelete: () => _delete(u),
              );
            },
          ),
        ),
      ),
    );
  }
}
