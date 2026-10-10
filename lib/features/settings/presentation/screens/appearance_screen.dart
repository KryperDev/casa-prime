import 'package:flutter/material.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/theme_service.dart';

class AppearanceScreen extends StatelessWidget {
  final ThemeController controller;

  const AppearanceScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Aparência')),
          body: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Escolha como o Casa Prime deve aparecer:',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              _ThemeOption(
                icon: Icons.brightness_auto,
                title: 'Automático',
                subtitle: 'Segue o tema do seu celular',
                selected: controller.mode == ThemeMode.system,
                onTap: () => _apply(ThemeMode.system),
              ),
              _ThemeOption(
                icon: Icons.light_mode,
                title: 'Claro',
                subtitle: 'Sempre com fundo branco',
                selected: controller.mode == ThemeMode.light,
                onTap: () => _apply(ThemeMode.light),
              ),
              _ThemeOption(
                icon: Icons.dark_mode,
                title: 'Escuro',
                subtitle: 'Sempre com fundo escuro',
                selected: controller.mode == ThemeMode.dark,
                onTap: () => _apply(ThemeMode.dark),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'A preferência é salva no seu aparelho e '
                            'sincronizada com sua conta.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _apply(ThemeMode mode) async {
    await controller.setMode(mode);
    await ThemeService().saveToFirestore(mode);
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: selected
            ? Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary)
            : const Icon(Icons.radio_button_unchecked),
        onTap: onTap,
      ),
    );
  }
}
