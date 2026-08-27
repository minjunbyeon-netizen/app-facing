import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';
import 'stability_home_test.dart' as home;

void main() {
  testWidgets('tmp skeleton look', (tester) async {
    phone(tester);
    await home.homeLoading(tester);
    await capture(tester, '_tmp_skel');
  });
  testWidgets('tmp empty look', (tester) async {
    phone(tester);
    await home.homeEmpty(tester);
    await capture(tester, '_tmp_empty');
  });
}
