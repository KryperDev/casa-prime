class AccountModel {
  final String id;
  final String name;
  final String type; // 'dinheiro', 'corrente', 'poupanca', 'carteira', 'credito', 'digital'

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'type': type};

  factory AccountModel.fromMap(Map<String, dynamic> m) => AccountModel(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        type: m['type'] ?? 'dinheiro',
      );
}