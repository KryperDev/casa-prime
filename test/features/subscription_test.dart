import 'package:flutter_test/flutter_test.dart';
import 'package:casa_prime/features/family/domain/family_model.dart';

void main() {
  group('Testes de Plano SaaS', () {
    test('Plano Free não permite editar categorias', () {
      final family = FamilyModel(
        id: 'test',
        name: 'Família Teste',
        adminId: 'admin',
        memberIds: ['admin'],
        createdAt: DateTime.now(),
        planType: PlanType.free,
      );
      
      expect(family.canEditCategories, false);
      expect(family.maxMembers, 2);
    });

    test('Plano Família permite editar categorias e tem 5 membros', () {
      final family = FamilyModel(
        id: 'test',
        name: 'Família Teste',
        adminId: 'admin',
        memberIds: ['admin'],
        createdAt: DateTime.now(),
        planType: PlanType.family,
      );
      
      expect(family.canEditCategories, true);
      expect(family.maxMembers, 5);
      expect(family.canUseCoupleMode, false);
    });

    test('Plano Plus permite tudo e tem 10 membros', () {
      final family = FamilyModel(
        id: 'test',
        name: 'Família Teste',
        adminId: 'admin',
        memberIds: ['admin'],
        createdAt: DateTime.now(),
        planType: PlanType.plus,
      );
      
      expect(family.canEditCategories, true);
      expect(family.maxMembers, 10);
      expect(family.canUseCoupleMode, true);
      expect(family.canUseEmailReport, true);
    });

    test('Conversão de String para PlanType funciona', () {
      expect(PlanTypeX.fromKey('free'), PlanType.free);
      expect(PlanTypeX.fromKey('family'), PlanType.family);
      expect(PlanTypeX.fromKey('plus'), PlanType.plus);
      expect(PlanTypeX.fromKey('invalido'), PlanType.free);
    });
  });
}
