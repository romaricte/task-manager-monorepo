import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_mobile/core/api_client.dart';
import 'package:task_manager_mobile/core/token_storage.dart';
import 'package:task_manager_mobile/main.dart';
import 'package:task_manager_mobile/repositories/auth_repository.dart';
import 'package:task_manager_mobile/repositories/task_repository.dart';

void main() {
  testWidgets('affiche le formulaire de connexion sans session', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = TokenStorage();
    final apiClient = ApiClient(storage, baseUrl: 'http://localhost:8080');

    await tester.pumpWidget(
      MomentumApp(
        authRepository: AuthRepository(apiClient, storage),
        taskRepository: TaskRepository(apiClient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task manager'), findsOneWidget);
    expect(find.text('Bon retour'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
