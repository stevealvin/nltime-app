import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniflow/core/storage/app_storage.dart';
import 'package:omniflow/core/theme/app_theme.dart';
import 'package:omniflow/core/theme/glass_container.dart';
import 'package:omniflow/features/quota/models/quota_model.dart';
import 'package:omniflow/features/quota/widgets/quota_stats_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'omniflow_base_url': 'https://om.nle.lol',
      'omniflow_theme_mode': 'dark',
    });
    await AppStorage.init();
  });

  test('AppStorage initializes correctly', () {
    expect(AppStorage.baseUrl, 'https://om.nle.lol');
    expect(AppStorage.themeMode, ThemeMode.dark);
  });

  test('QuotaModel decodes JSON correctly', () {
    final json = {
      'id': 'test-1',
      'name': 'Antigravity Pro Account',
      'type': 'token-plane',
      'provider': 'google-antigravity',
      'baseUrl': 'https://daily-cloudcode-pa.googleapis.com',
      'tokenQuota': {
        'usedPercentage': 20.0,
        'remainingPercentage': 80.0,
        'status': 'healthy',
        'resetIntervalHours': 5,
        'secondsRemaining': 3600,
        'nextResetTime': '2026-08-31 23:00:00',
        'planType': 'Ultra Plan',
        'details': [
          {
            'name': 'gemini-2.5-pro',
            'providerGroup': 'Gemini',
            'remainingPercentage': 80.0,
            'secondsRemaining': 3600,
            'nextResetTime': '2026-08-31 23:00:00',
          }
        ]
      }
    };

    final item = ApiKeyConfig.fromJson(json);
    expect(item.id, 'test-1');
    expect(item.name, 'Antigravity Pro Account');
    expect(item.tokenQuota?.remainingPercentage, 80.0);
    expect(item.tokenQuota?.details.length, 1);
    expect(item.tokenQuota?.details.first.name, 'gemini-2.5-pro');
  });

  testWidgets('GlassContainer and QuotaStatsBanner render properly', (WidgetTester tester) async {
    final keys = [
      ApiKeyConfig(
        id: '1',
        name: 'Test Key 1',
        type: 'token-plane',
        provider: 'google-antigravity',
        baseUrl: 'https://test',
        status: 'active',
      ),
      ApiKeyConfig(
        id: '2',
        name: 'Test Key 2',
        type: 'api-key',
        provider: 'openai-compatible',
        baseUrl: 'https://test',
        status: 'active',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Column(
            children: [
              QuotaStatsBanner(keys: keys),
              const GlassContainer(
                child: Text('Glass Card Test'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('全部资产'), findsOneWidget);
    expect(find.text('TokenPlane'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('健康在线'), findsOneWidget);
    expect(find.text('Glass Card Test'), findsOneWidget);
  });
}
