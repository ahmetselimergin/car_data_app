import 'package:flutter_test/flutter_test.dart';

import 'package:admin_desktop/services/catalog_service.dart';

void main() {
  test('normalizeSlug lowercases and strips', () {
    expect(normalizeSlug('BMW X5'), 'bmw-x5');
    expect(normalizeSlug('  Mercedes-Benz  '), 'mercedes-benz');
  });
}
