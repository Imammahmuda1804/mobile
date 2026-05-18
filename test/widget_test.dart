import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranahinsight_mobile/app/app.dart';
import 'package:ranahinsight_mobile/features/home/presentation/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RANAHINSIGHT app menampilkan halaman home', (
    WidgetTester tester,
  ) async {
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://127.0.0.1:3000');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapProvider.overrideWith((ref) async {}),
          homeTrendingProvider.overrideWith((ref) async => const []),
        ],
        child: const RanahInsightApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('RANAHINSIGHT'), findsWidgets);
  });
}
