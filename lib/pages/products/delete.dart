// lib/pages/products/delete.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';

Future<bool?> showDeleteConfirmationDialog(BuildContext context, RecordModel product) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ยืนยันการลบ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.red.shade700),
        ),
        content: Text(
          'คุณต้องการลบสินค้า "${product.data['name'] ?? 'นี้'}" หรือไม่?',
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.blue.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('ลบ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    },
  );
}

Future<void> deleteProductAndHandleResponse(BuildContext context, PocketBase pb, RecordModel product) async {
  final confirmed = await showDeleteConfirmationDialog(context, product);
  
  if (confirmed == true) {
    try {
      await pb.collection('product').delete(product.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ ลบสินค้า: ${product.data['name'] ?? 'สินค้า'}", style: GoogleFonts.prompt()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ เกิดข้อผิดพลาด: $e", style: GoogleFonts.prompt()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}