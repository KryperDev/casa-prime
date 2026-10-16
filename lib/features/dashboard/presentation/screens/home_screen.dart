import 'package:flutter/material.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/domain/user_model.dart';
import '../../../family/data/family_service.dart';
import '../../../family/presentation/screens/create_family_screen.dart';
import '../../../family/presentation/screens/join_family_screen.dart';
import '../../../recurring/data/recurring_service.dart';
import 'main_navigation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await _auth.fetchCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = u;
      _loading = false;
    });

    // Processa recorrências vencidas em background
    if (u?.familyId != null) {
      _processarRecorrencias(u!.familyId!);
    }
  }

  Future<void> _processarRecorrencias(String familyId) async {
    try {
      final service = RecurringService();
      final total = await service.processarVencidas(familyId);
      if (total > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$total lançamento(s) recorrente(s) criado(s).',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      // silencioso
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    if (user.familyId == null) {
      return _NoFamilyScreen(onRefresh: _load);
    }

    return const MainNavigationScreen();
  }
}

class _NoFamilyScreen extends StatelessWidget {
  final VoidCallback onRefresh;
  const _NoFamilyScreen({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Casa Prime'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom,
                  size: 80, color: Color(0xFF1E88E5)),
              const SizedBox(height: 24),
              const Text('Bem-vindo!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Você deseja criar uma nova família ou entrar em uma existente?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_home),
                  label: const Text('Criar nova família'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateFamilyScreen(),
                      ),
                    );
                    onRefresh();
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Entrar com convite'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const JoinFamilyScreen(),
                      ),
                    );
                    onRefresh();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
