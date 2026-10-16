import 'package:flutter/material.dart';

/// Bloco cinza animado (shimmer) para placeholder de carregamento.
class Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final alpha = 0.4 + (_ctrl.value * 0.6);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: base.a * alpha),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Skeleton pronto para o dashboard.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de saldo
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 12),

        // 2 stat cards
        Row(
          children: const [
            Expanded(child: Skeleton(height: 90, borderRadius: 16)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 90, borderRadius: 16)),
          ],
        ),
        const SizedBox(height: 12),

        // Destaques
        const Skeleton(height: 100, borderRadius: 16),
        const SizedBox(height: 20),

        // Gráfico de barras
        const Skeleton(height: 220, borderRadius: 16),
        const SizedBox(height: 20),

        // Gráfico de pizza
        const Skeleton(height: 180, borderRadius: 16),
      ],
    );
  }
}

/// Skeleton para lista de itens (lançamentos, metas, etc.).
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  const ListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Skeleton(width: 44, height: 44, borderRadius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(height: 14, width: 160),
                      SizedBox(height: 6),
                      Skeleton(height: 12, width: 100),
                    ],
                  ),
                ),
                const Skeleton(width: 70, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
