import 'package:flutter/material.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/domain/user_model.dart';
import '../../../family/data/family_service.dart';
import '../../../family/domain/family_model.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (r) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF1E88E5),
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 36, color: Colors.white),
                        )
                      : null,
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

          // Info
          Card(
            child: Column(
              children: [
                _tile(Icons.email_outlined, 'E-mail', user.email),
                const Divider(height: 1),
                _tile(
                  Icons.people_outline,
                  'Parentesco',
                  _relationLabel(user),
                ),
                const Divider(height: 1),
                _tile(
                  Icons.shield_outlined,
                  'Tipo de usuário',
                  user.role == 'admin' ? 'Administrador' : 'Membro',
                ),
                const Divider(height: 1),
                _tile(
                  Icons.family_restroom,
                  'Família',
                  _family?.name ?? '—',
                ),
                const Divider(height: 1),
                _tile(
                  Icons.calendar_today_outlined,
                  'Membro desde',
                  _formatDate(user.createdAt),
                ),
                const Divider(height: 1),
                _tile(
                  Icons.check_circle_outline,
                  'Status',
                  user.status == 'active' ? 'Ativo' : 'Suspenso',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sobre
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
                  const Text(
                    'Gerenciamento Financeiro Familiar',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
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

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600)),
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
}
