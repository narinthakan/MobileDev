import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'package:faker/faker.dart';

/// Script to generate dummy product records into PocketBase.
/// Usage:
///   dart run Scripts/generate_product.dart [count] [baseUrl] [adminEmail] [adminPassword]
/// Or set environment variables: PB_URL, PB_ADMIN_EMAIL, PB_ADMIN_PASSWORD

Future<void> main(List<String> args) async {
  final count = args.isNotEmpty ? int.tryParse(args[0]) ?? 100 : int.tryParse(Platform.environment['GEN_COUNT'] ?? '') ?? 100;
  final baseUrl = args.length > 1 ? args[1] : Platform.environment['PB_URL'] ?? 'http://127.0.0.1:8090';
  final adminEmail = args.length > 2 ? args[2] : Platform.environment['PB_ADMIN_EMAIL'] ?? 'Narinthakan.wa.65@ubu.ac.th';
  final adminPassword = args.length > 3 ? args[3] : Platform.environment['PB_ADMIN_PASSWORD'] ?? '0944675251';

  final pb = PocketBase(baseUrl);
  final faker = Faker();
  final random = Random();

  print('PocketBase URL: $baseUrl');
  print('Generating $count records');

  try {
    // Authenticate as admin
    await pb.admins.authWithPassword(adminEmail, adminPassword);
    print('Connected as admin: $adminEmail');
  } catch (e) {
    stderr.writeln('Failed to authenticate admin: $e');
    return;
  }

  for (int i = 0; i < count; i++) {
    // สร้างชื่อผลิตภัณฑ์
    final name = (faker.food.cuisine() + ' ' + faker.lorem.words(random.nextInt(3) + 1).join(' ')).trim() + ' Serum';
    // สร้างราคาเป็น double โดยอยู่ในช่วง 150.00 - 1150.00
    final price = (random.nextDouble() * 1000) + 150;

    // ใช้ Lorem Picsum เพื่อรูปภาพสุ่ม
    final imageUrl = 'https://picsum.photos/400/600?random=${random.nextInt(100000)}';

    try {
      final record = await pb.collection('product').create(body: {
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
      });
      print('Created (${i + 1}/$count): ${record.id} - $name (฿${price.toStringAsFixed(2)})');
    } catch (e, st) {
      stderr.writeln('Error creating $name: $e');
      stderr.writeln(st.toString());
    }

    // small delay to avoid hammering the server
    await Future.delayed(const Duration(milliseconds: 200));
  }

  print('Finished generating $count products into PocketBase.');
}