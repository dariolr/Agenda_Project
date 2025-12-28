import 'package:agenda_backend/core/models/business_invitation.dart';
import 'package:agenda_backend/core/models/business_user.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test per i modelli BusinessUser e BusinessInvitation
void main() {
  group('BusinessUser', () {
    test('fullName combina firstName e lastName', () {
      const user = BusinessUser(
        id: 1,
        businessId: 1,
        userId: 1,
        email: 'test@example.com',
        firstName: 'Mario',
        lastName: 'Rossi',
        role: 'admin',
        status: 'active',
      );

      expect(user.fullName, 'Mario Rossi');
    });

    test('fullName gestisce lastName vuoto', () {
      const user = BusinessUser(
        id: 1,
        businessId: 1,
        userId: 1,
        email: 'test@example.com',
        firstName: 'Mario',
        lastName: '',
        role: 'admin',
        status: 'active',
      );

      expect(user.fullName, 'Mario');
    });

    test('roleLabel restituisce etichetta corretta per ogni ruolo', () {
      final roles = ['owner', 'admin', 'manager', 'staff', 'unknown'];
      final expected = ['Proprietario', 'Amministratore', 'Manager', 'Staff', 'unknown'];

      for (var i = 0; i < roles.length; i++) {
        final user = BusinessUser(
          id: 1,
          businessId: 1,
          userId: 1,
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          role: roles[i],
          status: 'active',
        );

        expect(user.roleLabel, expected[i]);
      }
    });

    test('isAdmin restituisce true per owner e admin', () {
      const owner = BusinessUser(
        id: 1,
        businessId: 1,
        userId: 1,
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'owner',
        status: 'active',
      );

      const admin = BusinessUser(
        id: 2,
        businessId: 1,
        userId: 2,
        email: 'admin@example.com',
        firstName: 'Admin',
        lastName: 'User',
        role: 'admin',
        status: 'active',
      );

      const staff = BusinessUser(
        id: 3,
        businessId: 1,
        userId: 3,
        email: 'staff@example.com',
        firstName: 'Staff',
        lastName: 'User',
        role: 'staff',
        status: 'active',
      );

      expect(owner.isAdmin, true);
      expect(admin.isAdmin, true);
      expect(staff.isAdmin, false);
    });

    test('canManageUsers per owner e admin', () {
      const owner = BusinessUser(
        id: 1,
        businessId: 1,
        userId: 1,
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'owner',
        status: 'active',
      );

      const manager = BusinessUser(
        id: 2,
        businessId: 1,
        userId: 2,
        email: 'manager@example.com',
        firstName: 'Manager',
        lastName: 'User',
        role: 'manager',
        status: 'active',
      );

      expect(owner.canManageUsers, true);
      expect(manager.canManageUsers, false);
    });

    test('fromJson parsa correttamente i dati', () {
      final json = {
        'id': 1,
        'business_id': 2,
        'user_id': 3,
        'email': 'test@example.com',
        'first_name': 'Test',
        'last_name': 'User',
        'role': 'admin',
        'status': 'active',
      };

      final user = BusinessUser.fromJson(json);

      expect(user.id, 1);
      expect(user.businessId, 2);
      expect(user.userId, 3);
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Test');
      expect(user.lastName, 'User');
      expect(user.role, 'admin');
      expect(user.status, 'active');
    });

    test('copyWith crea copia con modifiche', () {
      const user = BusinessUser(
        id: 1,
        businessId: 1,
        userId: 1,
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        role: 'staff',
        status: 'active',
      );

      final updated = user.copyWith(role: 'admin');

      expect(updated.role, 'admin');
      expect(updated.email, 'test@example.com'); // non modificato
    });
  });

  group('BusinessInvitation', () {
    test('isExpired restituisce true per data passata', () {
      final invitation = BusinessInvitation(
        id: 1,
        businessId: 1,
        email: 'test@example.com',
        role: 'staff',
        token: 'abc123',
        expiresAt: DateTime(2020, 1, 1), // Data nel passato
        createdAt: DateTime(2020, 1, 1),
        invitedBy: const InviterInfo(firstName: 'Admin', lastName: 'User'),
      );

      expect(invitation.isExpired, true);
    });

    test('isExpired restituisce false per data futura', () {
      final invitation = BusinessInvitation(
        id: 1,
        businessId: 1,
        email: 'test@example.com',
        role: 'staff',
        token: 'abc123',
        expiresAt: DateTime(2030, 1, 1), // Data nel futuro
        createdAt: DateTime(2024, 1, 1),
        invitedBy: const InviterInfo(firstName: 'Admin', lastName: 'User'),
      );

      expect(invitation.isExpired, false);
    });

    test('roleLabel restituisce etichetta corretta', () {
      final roles = ['admin', 'manager', 'staff', 'custom'];
      final expected = ['Amministratore', 'Manager', 'Staff', 'custom'];

      for (var i = 0; i < roles.length; i++) {
        final invitation = BusinessInvitation(
          id: 1,
          businessId: 1,
          email: 'test@example.com',
          role: roles[i],
          expiresAt: DateTime(2024, 1, 8),
          createdAt: DateTime(2024, 1, 1),
          invitedBy: const InviterInfo(firstName: 'Admin', lastName: 'User'),
        );

        expect(invitation.roleLabel, expected[i]);
      }
    });

    test('fromJson parsa correttamente i dati con inviter', () {
      final json = {
        'id': 1,
        'business_id': 2,
        'email': 'invite@example.com',
        'role': 'manager',
        'token': 'abc123def456',
        'expires_at': '2024-01-08T00:00:00Z',
        'created_at': '2024-01-01T00:00:00Z',
        'invited_by': {
          'first_name': 'Admin',
          'last_name': 'User',
        },
      };

      final invitation = BusinessInvitation.fromJson(json);

      expect(invitation.id, 1);
      expect(invitation.businessId, 2);
      expect(invitation.email, 'invite@example.com');
      expect(invitation.role, 'manager');
      expect(invitation.token, 'abc123def456');
      expect(invitation.invitedBy.firstName, 'Admin');
      expect(invitation.invitedBy.lastName, 'User');
    });

    test('fromJson gestisce inviter mancante', () {
      final json = {
        'id': 1,
        'business_id': 2,
        'email': 'invite@example.com',
        'role': 'staff',
        'expires_at': '2024-01-08T00:00:00Z',
        'created_at': '2024-01-01T00:00:00Z',
        // invited_by mancante
      };

      final invitation = BusinessInvitation.fromJson(json);

      expect(invitation.invitedBy.firstName, '');
    });

    test('copyWith crea copia con modifiche', () {
      final invitation = BusinessInvitation(
        id: 1,
        businessId: 1,
        email: 'test@example.com',
        role: 'staff',
        expiresAt: DateTime(2024, 1, 8),
        createdAt: DateTime(2024, 1, 1),
        invitedBy: const InviterInfo(firstName: 'Admin', lastName: 'User'),
      );

      final updated = invitation.copyWith(role: 'admin');

      expect(updated.role, 'admin');
      expect(updated.email, 'test@example.com'); // non modificato
    });
  });

  group('InviterInfo', () {
    test('fullName combina firstName e lastName', () {
      const inviter = InviterInfo(firstName: 'Mario', lastName: 'Rossi');
      expect(inviter.fullName, 'Mario Rossi');
    });

    test('fromJson parsa correttamente', () {
      final json = {
        'first_name': 'Test',
        'last_name': 'User',
      };

      final inviter = InviterInfo.fromJson(json);

      expect(inviter.firstName, 'Test');
      expect(inviter.lastName, 'User');
    });
  });
}
