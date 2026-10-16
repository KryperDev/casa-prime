import 'package:cloud_firestore/cloud_firestore.dart';

/// Cria categorias padrÃ£o para uma famÃ­lia recÃ©m-criada.
Future<void> seedDefaultCategories(String familyId) async {
  final db = FirebaseFirestore.instance;
  final col = db.collection('families').doc(familyId).collection('categories');

  // ENTRADAS
  final incomeCategories = [
    {
      'name': 'SalÃ¡rio',
      'icon': 'work',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Freelance',
      'icon': 'laptop',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'BenefÃ­cio',
      'icon': 'card_giftcard',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Venda',
      'icon': 'sell',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Investimento',
      'icon': 'trending_up',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Outros',
      'icon': 'more_horiz',
      'subs': <Map<String, String>>[],
    },
  ];

  // SAÃDAS
  final expenseCategories = [
    {
      'name': 'AlimentaÃ§Ã£o',
      'icon': 'restaurant',
      'subs': [
        {'id': 'mercado', 'name': 'Mercado'},
        {'id': 'restaurante', 'name': 'Restaurante'},
        {'id': 'delivery', 'name': 'Delivery'},
        {'id': 'lanches', 'name': 'Lanches'},
      ],
    },
    {
      'name': 'Moradia',
      'icon': 'home',
      'subs': [
        {'id': 'aluguel', 'name': 'Aluguel'},
        {'id': 'condominio', 'name': 'CondomÃ­nio'},
        {'id': 'reforma', 'name': 'Reforma'},
      ],
    },
    {
      'name': 'Ãgua',
      'icon': 'water_drop',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Energia',
      'icon': 'bolt',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Internet',
      'icon': 'wifi',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Telefone',
      'icon': 'phone_android',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Transporte',
      'icon': 'directions_car',
      'subs': [
        {'id': 'combustivel', 'name': 'CombustÃ­vel'},
        {'id': 'uber', 'name': 'Uber/99'},
        {'id': 'onibus', 'name': 'Ã”nibus/MetrÃ´'},
        {'id': 'estacionamento', 'name': 'Estacionamento'},
      ],
    },
    {
      'name': 'EducaÃ§Ã£o',
      'icon': 'school',
      'subs': [
        {'id': 'escola', 'name': 'Escola'},
        {'id': 'faculdade', 'name': 'Faculdade'},
        {'id': 'cursos', 'name': 'Cursos'},
        {'id': 'material', 'name': 'Material'},
      ],
    },
    {
      'name': 'SaÃºde',
      'icon': 'local_hospital',
      'subs': [
        {'id': 'plano', 'name': 'Plano de SaÃºde'},
        {'id': 'farmacia', 'name': 'FarmÃ¡cia'},
        {'id': 'consultas', 'name': 'Consultas'},
      ],
    },
    {
      'name': 'Lazer',
      'icon': 'sports_esports',
      'subs': [
        {'id': 'streaming', 'name': 'Streaming'},
        {'id': 'cinema', 'name': 'Cinema'},
        {'id': 'viagem', 'name': 'Viagem'},
        {'id': 'jogos', 'name': 'Jogos'},
      ],
    },
    {
      'name': 'Compras',
      'icon': 'shopping_bag',
      'subs': [
        {'id': 'roupas', 'name': 'Roupas'},
        {'id': 'eletronicos', 'name': 'EletrÃ´nicos'},
        {'id': 'casa', 'name': 'Casa'},
      ],
    },
    {
      'name': 'CartÃ£o de CrÃ©dito',
      'icon': 'credit_card',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'EmprÃ©stimos',
      'icon': 'request_quote',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Assinaturas',
      'icon': 'subscriptions',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Metas e Objetivos',
      'icon': 'savings',
      'subs': <Map<String, String>>[],
    },
    {
      'name': 'Outros',
      'icon': 'more_horiz',
      'subs': <Map<String, String>>[],
    },
  ];

  final batch = db.batch();

  for (final c in incomeCategories) {
    final ref = col.doc();
    batch.set(ref, {
      'id': ref.id,
      'name': c['name'],
      'type': 'income',
      'icon': c['icon'],
      'subcategories': c['subs'],
    });
  }

  for (final c in expenseCategories) {
    final ref = col.doc();
    batch.set(ref, {
      'id': ref.id,
      'name': c['name'],
      'type': 'expense',
      'icon': c['icon'],
      'subcategories': c['subs'],
    });
  }

  await batch.commit();
}
