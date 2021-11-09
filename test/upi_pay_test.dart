import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upi_pay/upi_pay.dart';

void main() {
  const MethodChannel channel = MethodChannel('upi_pay');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

}
