import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyphen_app/widgets/hkit.dart';
import 'package:hyphen_app/features/classes/class_line.dart';

import 'stability_wod_test.dart'
    show detailAllArrived, detailAllEmpty, dayClassesArrived;

void main() {
  testWidgets('probe arrived slot sizes', (tester) async {
    await detailAllArrived(tester);
    final slots = find.byType(HkSectionSlot);
    for (var i = 0; i < slots.evaluate().length; i++) {
      // ignore: avoid_print
      print('ARRIVED slot $i: ${tester.getSize(slots.at(i))}');
    }
  });

  testWidgets('probe empty slot sizes', (tester) async {
    await detailAllEmpty(tester);
    final slots = find.byType(HkSectionSlot);
    for (var i = 0; i < slots.evaluate().length; i++) {
      // ignore: avoid_print
      print('EMPTY slot $i: ${tester.getSize(slots.at(i))}');
    }
  });

  testWidgets('probe class line size', (tester) async {
    await dayClassesArrived(tester);
    final lines = find.byType(ClassLine);
    for (var i = 0; i < lines.evaluate().length; i++) {
      // ignore: avoid_print
      print('CLASSLINE $i: ${tester.getSize(lines.at(i))}');
    }
    final slots = find.byType(HkSectionSlot);
    for (var i = 0; i < slots.evaluate().length; i++) {
      // ignore: avoid_print
      print('DAY slot $i: ${tester.getSize(slots.at(i))}');
    }
  });
}
