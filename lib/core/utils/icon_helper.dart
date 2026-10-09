import 'package:flutter/material.dart';

/// Mapa nome -> IconData para categorias.
/// Usado para persistir no Firestore o nome do ícone (string),
/// e renderizar depois na UI.
class IconHelper {
  static const Map<String, IconData> _icons = {
    'category': Icons.category,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'fastfood': Icons.fastfood,
    'local_pizza': Icons.local_pizza,
    'home': Icons.home,
    'water_drop': Icons.water_drop,
    'bolt': Icons.bolt,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,
    'directions_car': Icons.directions_car,
    'local_gas_station': Icons.local_gas_station,
    'directions_bus': Icons.directions_bus,
    'school': Icons.school,
    'menu_book': Icons.menu_book,
    'local_hospital': Icons.local_hospital,
    'medical_services': Icons.medical_services,
    'fitness_center': Icons.fitness_center,
    'sports_esports': Icons.sports_esports,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'shopping_bag': Icons.shopping_bag,
    'shopping_cart': Icons.shopping_cart,
    'checkroom': Icons.checkroom,
    'credit_card': Icons.credit_card,
    'request_quote': Icons.request_quote,
    'subscriptions': Icons.subscriptions,
    'work': Icons.work,
    'laptop': Icons.laptop,
    'card_giftcard': Icons.card_giftcard,
    'sell': Icons.sell,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'baby_changing_station': Icons.baby_changing_station,
    'local_florist': Icons.local_florist,
    'build': Icons.build,
    'handyman': Icons.handyman,
    'flight': Icons.flight,
    'beach_access': Icons.beach_access,
    'local_laundry_service': Icons.local_laundry_service,
    'smoke_free': Icons.smoke_free,
    'more_horiz': Icons.more_horiz,
  };

  static IconData getIcon(String name) {
    return _icons[name] ?? Icons.category;
  }

  static List<String> get allNames => _icons.keys.toList();

  static List<IconData> get allIcons => _icons.values.toList();
}
