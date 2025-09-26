import 'package:flutter/material.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';

class UpdateProductPage extends StatefulWidget {
  final RecordModel product;

  const UpdateProductPage({super.key, required this.product});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.data["name"]);
    _priceController = TextEditingController(text: widget.product.data["price"].toString());
    _imageUrlController = TextEditingController(text: widget.product.data["imageUrl"]); // ✅ เปลี่ยนเป็น imageUrl
  }

  Future<void> _updateProduct() async {
    setState(() => _isLoading = true);
    try {
      final record = await pb.collection('product').update(widget.product.id, body: {
        "name": _nameController.text,
        "price": double.tryParse(_priceController.text) ?? 0,
        "imageUrl": _imageUrlController.text, // ✅ ใช้ imageUrl
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ อัปเดตสินค้าสำเร็จ", style: GoogleFonts.prompt()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, record);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ เกิดข้อผิดพลาด: $e", style: GoogleFonts.prompt()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "แก้ไขสินค้า",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "ชื่อสินค้า",
                labelStyle: GoogleFonts.prompt(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: "ราคา",
                labelStyle: GoogleFonts.prompt(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: "ImageURL", // ✅ เปลี่ยน label
                labelStyle: GoogleFonts.prompt(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("บันทึกการแก้ไข", style: GoogleFonts.prompt(fontSize: 18)),
                  ),
          ],
        ),
      ),
    );
  }
}
