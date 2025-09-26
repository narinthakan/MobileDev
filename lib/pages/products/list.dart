import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'create.dart';
import 'update.dart';
import '../../services/app_events.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  final ScrollController _scrollController = ScrollController();
  final List<RecordModel> _products = [];
  final int _pageSize = 20;
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  UnsubscribeFunc? _unsubscribeRealtime;
  StreamSubscription<String>? _deletedSub;

  @override
  void initState() {
    super.initState();
    _fetchProducts(reset: true);
    _setupRealtime();
    _scrollController.addListener(_onScroll);

    _deletedSub = AppEvents.onProductDeleted.listen((id) {
      setState(() => _products.removeWhere((p) => p.id == id));
    });
  }

  /// ✅ subscribe realtime events
  void _setupRealtime() async {
    _unsubscribeRealtime =
        await pb.collection('product').subscribe('*', (e) {
      debugPrint("📡 ${e.action} : ${e.record?.id}");
      if (!mounted || e.record == null) return;

      setState(() {
        if (e.action == "create") {
          _products.insert(0, e.record!);
        } else if (e.action == "update") {
          final i = _products.indexWhere((p) => p.id == e.record!.id);
          if (i != -1) _products[i] = e.record!;
        } else if (e.action == "delete") {
          _products.removeWhere((p) => p.id == e.record!.id);
        }
        _products.sort((a, b) => b.updated.compareTo(a.updated));
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _page++;
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (_isLoading) return;
    _isLoading = true;

    if (reset) {
      _products.clear();
      _page = 1;
      _hasMore = true;
    }

    try {
      final result = await pb.collection('product').getList(
            page: _page,
            perPage: _pageSize,
            sort: "-created",
          );
      setState(() {
        _products.addAll(result.items);
        if (result.items.length < _pageSize) _hasMore = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt())),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editProduct(RecordModel product) async {
    final updatedRecord = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UpdateProductPage(product: product)),
    );
    if (updatedRecord is RecordModel) {
      setState(() {
        final index = _products.indexWhere((p) => p.id == updatedRecord.id);
        if (index != -1) _products[index] = updatedRecord;
      });
    }
  }

  Future<void> _deleteProduct(RecordModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('ยืนยันการลบ', style: GoogleFonts.prompt()),
        content: Text('ต้องการลบสินค้า ${product.data['name']} ใช่หรือไม่?',
            style: GoogleFonts.prompt()),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: Text('ยกเลิก', style: GoogleFonts.prompt())),
          TextButton(
              onPressed: () => Navigator.of(dctx).pop(true),
              child: Text('ลบ', style: GoogleFonts.prompt(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await pb.collection('product').delete(product.id);
      setState(() {
        _products.removeWhere((p) => p.id == product.id);
      });
      AppEvents.notifyProductDeleted(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบสินค้าเรียบร้อย', style: GoogleFonts.prompt())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถลบสินค้า: $e', style: GoogleFonts.prompt())),
        );
      }
    }
  }

  @override
  void dispose() {
    _unsubscribeRealtime?.call();
    _scrollController.dispose();
    _deletedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการสินค้า',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () async {
              final newRecord = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateProductPage()),
              );

              // ✅ fallback: ถ้า realtime ไม่ยิง event → insert เอง
              if (newRecord is RecordModel) {
                setState(() {
                  _products.insert(0, newRecord);
                });
              }
            },
          ),
        ],
      ),
      body: _products.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _fetchProducts(reset: true),
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _products.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    if (!_isLoading) _fetchProducts();
                    return const Center(child: CircularProgressIndicator());
                  }
                  final product = _products[index];
                  return _ProductCard(
                    product: product,
                    pb: pb,
                    onEdit: _editProduct,
                    onDelete: _deleteProduct,
                  );
                },
              ),
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final RecordModel product;
  final PocketBase pb;
  final Function(RecordModel) onEdit;
  final Function(RecordModel) onDelete;

  const _ProductCard({
    required this.product,
    required this.pb,
    required this.onEdit,
    required this.onDelete,
  });

  String _getImageUrl() {
    final urlField = product.data['imageUrl']?.toString() ?? '';
    if (urlField.isNotEmpty && urlField.toLowerCase().startsWith('http')) {
      return urlField;
    }
    final fileName = product.data['image']?.toString() ?? '';
    if (fileName.isNotEmpty) {
      return pb.files.getUrl(product, fileName).toString();
    }
    return 'https://via.placeholder.com/200x200?text=No+Image';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: _getImageUrl(),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.data['name']?.toString() ?? 'ไม่มีชื่อ',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '฿${product.data['price']?.toString() ?? '0.0'}',
                  style: GoogleFonts.prompt(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => onEdit(product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => onDelete(product),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
