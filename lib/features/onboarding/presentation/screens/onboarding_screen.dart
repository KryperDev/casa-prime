import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String prefsKey = 'onboarding_done';

  /// Retorna true se o usuário já viu o tutorial.
  static Future<bool> jaViu() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  /// Marca o tutorial como visto.
  static Future<void> marcarComoVisto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  /// Reseta (para debug / logout).
  static Future<void> resetar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _pagina = 0;

  static const _paginas = [
    _OnboardingPageData(
      icon: Icons.home_work,
      title: 'Bem-vindo ao Casa Prime',
      subtitle:
          'O jeito mais simples de organizar as finanças da sua família — juntos, em um só lugar.',
      color: Color(0xFF1E88E5),
    ),
    _OnboardingPageData(
      icon: Icons.people_alt,
      title: 'Toda a família participa',
      subtitle:
          'Convide pai, mãe, filhos ou qualquer membro com um código simples. '
          'Cada um lança o que quiser, e todos veem o resultado.',
      color: Color(0xFF43A047),
    ),
    _OnboardingPageData(
      icon: Icons.insights,
      title: 'Controle total, sem complicação',
      subtitle:
          'Acompanhe saldo, gastos por categoria, relatórios mensais e anuais. '
          'Tudo pronto para você tomar decisões melhores.',
      color: Color(0xFF8E24AA),
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _finalizar() async {
    await OnboardingScreen.marcarComoVisto();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _proxima() {
    if (_pagina < _paginas.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finalizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _pagina == _paginas.length - 1;

    return Scaffold(
      backgroundColor: _paginas[_pagina].color,
      body: SafeArea(
        child: Column(
          children: [
            // Botão "Pular" no topo
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finalizar,
                child: const Text(
                  'Pular',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),

            // Conteúdo
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _paginas.length,
                onPageChanged: (i) => setState(() => _pagina = i),
                itemBuilder: (_, i) => _OnboardingPage(data: _paginas[i]),
              ),
            ),

            // Indicador de páginas (bolinhas)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_paginas.length, (i) {
                final ativo = i == _pagina;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: ativo ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: ativo ? 1.0 : 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Botão principal
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _paginas[_pagina].color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _proxima,
                  child: Text(
                    ultima ? 'Começar agora' : 'Próximo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Modelo de página
// ============================================================
class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone dentro de um círculo translúcido
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),

          // Título
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Subtítulo
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
