import 'package:car_data_app/screens/support_chat_screen.dart';
import 'package:car_data_app/services/support_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Supabase'e dokunmadan ekranı sürebilmek için sahte servis.
class _FakeService implements SupportChatService {
  final List<String> sent = <String>[];
  final List<String> tickets = <String>[];

  @override
  Future<List<SupportMessage>> loadHistory() async => <SupportMessage>[];

  @override
  Future<String> sendMessage(String message) async {
    sent.add(message);
    return 'Cevap: $message';
  }

  @override
  Future<void> openTicket(String message) async {
    tickets.add(message);
  }
}

void main() {
  testWidgets('mesaj gönderilince kullanıcı ve asistan baloncuğu görünür',
      (WidgetTester tester) async {
    final _FakeService fake = _FakeService();
    await tester.pumpWidget(
      MaterialApp(home: SupportChatScreen(service: fake)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'fren sesi geliyor');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(fake.sent, <String>['fren sesi geliyor']);
    expect(find.text('fren sesi geliyor'), findsOneWidget);
    expect(find.text('Cevap: fren sesi geliyor'), findsOneWidget);
  });

  testWidgets('Destek Talebi Aç son kullanıcı mesajıyla ticket açar',
      (WidgetTester tester) async {
    final _FakeService fake = _FakeService();
    await tester.pumpWidget(
      MaterialApp(home: SupportChatScreen(service: fake)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'motor çekmiyor');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Destek Talebi Aç'));
    await tester.pumpAndSettle();

    expect(fake.tickets, <String>['motor çekmiyor']);
    expect(find.text('Destek talebin oluşturuldu.'), findsOneWidget);
  });
}
