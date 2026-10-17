import 'package:flutter/material.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/domain/user_model.dart';
import '../../../../app/app.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';
import '../../../notifications/presentation/screens/notification_settings_screen.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../accounts/presentation/screens/accounts_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../../app/routes.dart';
import '../../../family/presentation/screens/my_family_screen.dart';
import '../../../settings/presentation/screens/appearance_screen.dart';
import 'edit_profile_screen.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _familyService = FamilyService();

  UserModel? _user;
  FamilyModel? _family;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _auth.fetchCurrentUser();
    FamilyModel? f;
    if (u?.familyId != null) {
      f = await _familyService.fetchMyFamily();
    }
    if (!mounted) return;
    setState(() {
      _user = u;
      _family = f;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sessão encerrada.')));
    }

    final isAdmin = user.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF1E88E5),
                      backgroundImage: user.photoUrl != null &&
                              user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: (user.photoUrl == null ||
                              user.photoUrl!.isEmpty)
                          ? Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 36, color: Colors.white),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: const Color(0xFF1E88E5),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                            _load();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(user.displayName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('@${user.username}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Card(
            child: Column(
              children: [
                _actionTile(
                  icon: Icons.people_outline,
                  title: 'Minha Família',
                  subtitle: 'Membros, convites e gestão',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyFamilyScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _actionTile(
                  icon: Icons.person_outline,
                  title: 'Editar perfil',
                  subtitle: 'Nome e foto',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                    _load();
                  },
                ),
                const Divider(height: 1),
                _actionTile(
                  icon: Icons.email_outlined,
                  title: 'Alterar e-mail',
                  subtitle: user.email,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangeEmailScreen(),
                      ),
                    );
                    _load();
                  },
                ),
                const Divider(height: 1),
                _actionTile(
                  icon: Icons.lock_outline,
                  title: 'Alterar senha',
                  subtitle: 'Toque para trocar',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _actionTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificações',
                  subtitle: 'Escolha o que deseja receber',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationSettingsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _actionTile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Aparência',
                  subtitle: 'Claro, escuro ou automático',
                  onTap: () {
                    final controller = ThemeControllerProvider.of(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AppearanceScreen(controller: controller),
                      ),
                    );
                  },
                ),
                if (isAdmin) ...[
                  const Divider(height: 1),
                  _actionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Contas',
                    subtitle: 'Contas financeiras da família',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountsScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _actionTile(
                    icon: Icons.category_outlined,
                    title: 'Categorias',
                    subtitle: 'Criar, editar e excluir categorias',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                _infoTile(Icons.people_outline, 'Parentesco',
                    _relationLabel(user)),
                const Divider(height: 1),
                _infoTile(
                  Icons.shield_outlined,
                  'Tipo de usuário',
                  user.role == 'admin' ? 'Administrador' : 'Membro',
                ),
                const Divider(height: 1),
                _infoTile(Icons.family_restroom, 'Família',
                    _family?.name ?? '—', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const MyFamilyScreen())); }),
                const Divider(height: 1),
                _infoTile(Icons.calendar_today_outlined, 'Membro desde',
                    _formatDate(user.createdAt)),
                const Divider(height: 1),
                _infoTile(Icons.check_circle_outline, 'Status',
                    user.status == 'active' ? 'Ativo' : 'Suspenso'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Ver tutorial novamente'),
              subtitle: const Text('Reveja as telas de boas-vindas'),
              onTap: () async {
                await OnboardingScreen.resetar();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.onboarding,
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Excluir minha conta',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text(
                  'Remove seus dados. Lançamentos ficam no histórico.'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeleteAccountScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text('Sobre o aplicativo',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Casa Prime',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Gerenciamento Financeiro Familiar',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  const Text('Criado por Anderson Scantamburlo',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Versão 1.0.0',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  String _relationLabel(UserModel u) {
    if (u.relationship == null) return '—';
    if (u.relationship == 'outro' && u.customRelationship != null) {
      return u.customRelationship!;
    }
    final r = u.relationship!;
    return r[0].toUpperCase() + r.substring(1);
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _auth.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      }
    }
  }
}





