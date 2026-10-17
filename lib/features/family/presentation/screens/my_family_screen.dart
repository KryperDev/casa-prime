import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/error_translator.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../auth/data/auth_service.dart';
import '../../../transactions/presentation/screens/transactions_list_screen.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../data/family_service.dart';
import '../../domain/family_model.dart';
import '../../domain/invite_model.dart';
import 'create_family_screen.dart';
import 'join_family_screen.dart';
import '../../../transactions/data/default_categories.dart';

class MyFamilyScreen extends StatelessWidget {
  const MyFamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FamilyService();
    final auth = AuthService();

    return StreamBuilder<FamilyModel?>(
      stream: service.watchMyFamily(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: ListSkeleton());
        }

        final family = snapshot.data;
        if (family == null) {
          return _EmptyFamily(
            onCreate: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateFamilyScreen()),
            ),
            onJoin: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinFamilyScreen()),
            ),
          );
        }

        final uid = auth.currentUser?.uid;
        final isAdmin = family.adminId == uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(family.name),
            actions: [
              // Lançamentos
              IconButton(
                icon: const Icon(Icons.receipt_long),
                tooltip: 'Lançamentos',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionsListScreen(),
                  ),
                ),
              ),

              // Renomear (só admin)
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Renomear família',
                  onPressed: () => _renameFamily(context, service, family),
                ),

              // Menu de conta
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'logout') {
                    final confirm = await showDialog<bool>(
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
                    if (confirm == true) {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (r) => false,
                        );
                      }
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Sair da conta'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FamilyHeader(family: family),
              const SizedBox(height: 16),
              const _SectionTitle('Membros'),
              _MembersList(
                service: service,
                family: family,
                isAdmin: isAdmin,
                currentUid: uid ?? '',
              ),
              if (isAdmin) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Convites'),
                _InvitesSection(service: service, family: family),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameFamily(
      BuildContext context, FamilyService service, FamilyModel family) async {
    final ctrl = TextEditingController(text: family.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renomear família'),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (newName != null && newName.trim().length >= 3) {
      await service.renameFamily(family.id, newName);
    }
  }
}

// ============================================================
//  Tela vazia (quando usuário não tem família)
// ============================================================
class _EmptyFamily extends StatelessWidget {
  final VoidCallback onCreate, onJoin;
  const _EmptyFamily({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Família')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom,
                size: 72, color: Color(0xFF1E88E5)),
            const SizedBox(height: 24),
            const Text('Você ainda não tem uma família',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onCreate,
                child: const Text('Criar nova família'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onJoin,
                child: const Text('Entrar com convite'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Cabeçalho da família
// ============================================================
class _FamilyHeader extends StatelessWidget {
  final FamilyModel family;
  const _FamilyHeader({required this.family});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF1E88E5),
              child: Icon(Icons.home, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(family.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${family.memberIds.length} membros',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  Título de seção
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

// ============================================================
//  Lista de membros
// ============================================================
class _MembersList extends StatelessWidget {
  final FamilyService service;
  final FamilyModel family;
  final bool isAdmin;
  final String currentUid;

  const _MembersList({
    required this.service,
    required this.family,
    required this.isAdmin,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.fetchMembers(family.memberIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final members = snapshot.data!;
        return Column(
          children: members.map((m) {
            final isMe = m['uid'] == currentUid;
            final isFamilyAdmin = m['uid'] == family.adminId;
            final relation = (m['relationship'] == 'outro')
                ? (m['customRelationship'] ?? 'outro')
                : (m['relationship'] ?? '—');

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E88E5),
                  backgroundImage: (m['photoUrl'] != null)
                      ? NetworkImage(m['photoUrl'])
                      : null,
                  child: (m['photoUrl'] == null)
                      ? Text((m['displayName'] ?? '?')[0].toUpperCase())
                      : null,
                ),
                title: Text(
                    '${m['displayName'] ?? '—'}${isMe ? ' (você)' : ''}'),
                subtitle: Text(
                  '${relation.toString().toUpperCase()} · '
                  '${isFamilyAdmin ? 'Administrador' : 'Membro'}',
                ),
                trailing: isAdmin && !isMe
                    ? PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'remove') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Remover membro'),
                                content: Text(
                                    'Deseja remover ${m['displayName']} da família?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Remover'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await service.removeMember(
                                familyId: family.id,
                                memberId: m['uid'],
                              );
                            }
                          } else if (value.startsWith('rel:')) {
                            final rel = value.substring(4);
                            await service.updateMemberRelationship(
                              memberId: m['uid'],
                              relationship: rel,
                              customRelationship:
                                  rel == 'outro' ? 'Outro' : null,
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'rel:pai',
                              child: Text('Marcar como Pai')),
                          PopupMenuItem(
                              value: 'rel:mãe',
                              child: Text('Marcar como Mãe')),
                          PopupMenuItem(
                              value: 'rel:filho',
                              child: Text('Marcar como Filho')),
                          PopupMenuItem(
                              value: 'rel:filha',
                              child: Text('Marcar como Filha')),
                          PopupMenuItem(
                              value: 'rel:outro',
                              child: Text('Outro parentesco')),
                          PopupMenuDivider(),
                          PopupMenuItem(
                              value: 'remove',
                              child: Text('Remover da família',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ============================================================
//  Seção de convites (só admin)
// ============================================================
class _InvitesSection extends StatelessWidget {
  final FamilyService service;
  final FamilyModel family;

  const _InvitesSection({required this.service, required this.family});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Gerar novo convite'),
            onPressed: () async {
              final invite = await service.createInvite(familyId: family.id);
              if (!context.mounted) return;
              _showInviteDialog(context, invite);
            },
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<InviteModel>>(
          stream: service.watchInvites(family.id),
          builder: (context, snapshot) {
            final invites = snapshot.data ?? [];
            if (invites.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum convite gerado ainda.',
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: invites.map((inv) {
                final status = inv.revoked
                    ? 'Cancelado'
                    : inv.isExpired
                        ? 'Expirado'
                        : 'Ativo';
                final color = inv.isActive ? Colors.green : Colors.grey;
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.vpn_key, color: color),
                    title: Text(inv.token,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                    subtitle: Text(
                      '$status · ${inv.usageCount} uso(s)',
                      style: TextStyle(color: color),
                    ),
                    trailing: inv.isActive
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: inv.token));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Código copiado!')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share,
                                    color: Colors.green),
                                tooltip: 'Compartilhar convite',
                                onPressed: () async {
                                  final text = 'Olá! Você foi convidado a '
                                      'entrar na família no app Casa Prime.\n\n'
                                      'Código de convite: ${inv.token}\n\n'
                                      'Baixe o app e use este código em '
                                      '"Entrar com convite".';
                                  await SharePlus.instance.share(
                                    ShareParams(text: text),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined),
                                onPressed: () => service.revokeInvite(inv),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context, InviteModel invite) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Convite criado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Compartilhe este código com o novo membro:'),
            const SizedBox(height: 16),
            SelectableText(
              invite.token,
              style: const TextStyle(
                fontSize: 28,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: invite.token));
              Navigator.pop(context);
            },
            child: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


