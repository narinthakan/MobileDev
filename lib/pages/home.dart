import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';
import 'products/list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/app_events.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  late final RecordService _service;
  final List<RecordModel> _products = [];
  final List<String> _categories = ['ทั้งหมด', 'ความงาม', 'แฟชั่น', 'อุปกรณ์', 'ของใช้', 'โปรโมชั่น'];
  int _selectedCategoryIndex = 0;
  bool _isLoading = false;
  bool _isDeleting = false;
  UnsubscribeFunc? _unsubscribeRealtime;

  // ===== Banner carousel state (ปุ่มเลื่อนซ้าย/ขวา) =====
  final PageController _bannerCtrl = PageController(viewportFraction: 0.9);
  final int _bannerCount = 4;
  int _currentBanner = 0;

  void _goBanner(int delta) {
    int next = (_currentBanner + delta) % _bannerCount;
    if (next < 0) next = _bannerCount - 1;
    _bannerCtrl.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }
  // ======================================================

  @override
  void initState() {
    super.initState();
    _service = pb.collection('product');
    _fetchProducts();

    // subscribe realtime
    pb.realtime.subscribe("collections.product.records", (msg) {
      try {
        dynamic raw = msg.data;
        Map<String, dynamic>? payload;
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) payload = Map<String, dynamic>.from(decoded.map((k, v) => MapEntry(k.toString(), v)));
        } else if (raw is Map) {
          payload = Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)));
        }

        if (payload == null) {
          debugPrint('Home realtime: payload not a map (type=${raw.runtimeType})');
          return;
        }

        final action = payload['action']?.toString() ?? '';
        final rawRecord = payload['record'];

        Map<String, dynamic>? recordMap;
        if (rawRecord is String) {
          final decoded = jsonDecode(rawRecord);
          if (decoded is Map) recordMap = Map<String, dynamic>.from(decoded.map((k, v) => MapEntry(k.toString(), v)));
        } else if (rawRecord is Map) {
          recordMap = Map<String, dynamic>.from(rawRecord.map((k, v) => MapEntry(k.toString(), v)));
        }

        // If delete event may come with only id
        final incomingId = payload['id']?.toString();
        if (action == 'delete' && incomingId != null) {
          setState(() {
            _products.removeWhere((p) => p.id.toString() == incomingId);
          });
          return;
        }

        if (recordMap == null) {
          debugPrint('Home realtime: no record map for action=$action');
          return;
        }

        final record = RecordModel.fromJson(recordMap);

        setState(() {
          if (action == "create") {
            _products.insert(0, record);
          } else if (action == "update") {
            final index = _products.indexWhere((p) => p.id == record.id);
            if (index != -1) {
              _products[index] = record;
            }
          } else if (action == "delete") {
            _products.removeWhere((p) => p.id == record.id);
          }
          _products.sort((a, b) => b.updated.compareTo(a.updated));
        });
      } catch (e, st) {
        debugPrint("Home realtime error: $e");
        debugPrint(st.toString());
      }
    }).then((unsubscribe) {
      _unsubscribeRealtime = unsubscribe;
    });
  }

  Future<void> _fetchProducts() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final result = await _service.getList(page: 1, perPage: 10, sort: "-created");
      setState(() {
        _products
          ..clear()
          ..addAll(result.items);
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
    _isLoading = false;
  }

  @override
  void dispose() {
    _unsubscribeRealtime?.call();
    _bannerCtrl.dispose(); // dispose controller ของแบนเนอร์
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration.collapsed(hintText: 'ค้นหาสินค้า, แบรนด์, รีวิว'),
                        onSubmitted: (q) {
                          // TODO: implement search
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
          ],
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProductListPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Banner carousel with arrows (ไม่มีการเปลี่ยนแปลง) =====
                  SizedBox(
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PageView.builder(
                          controller: _bannerCtrl,
                          itemCount: _bannerCount,
                          onPageChanged: (i) => setState(() => _currentBanner = i),
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: 'https://picsum.photos/900/300?random=$i',
                                fit: BoxFit.cover,
                                placeholder: (c, s) => Container(color: Colors.grey[200]),
                                errorWidget: (c, s, e) => Container(color: Colors.grey[200]),
                              ),
                            ),
                          ),
                        ),

                        // ปุ่มซ้าย
                        Positioned(
                          left: 8,
                          child: Material(
                            color: Colors.black.withOpacity(.35),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _goBanner(-1),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                        ),

                        // ปุ่มขวา
                        Positioned(
                          right: 8,
                          child: Material(
                            color: Colors.black.withOpacity(.35),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _goBanner(1),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.chevron_right, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                        ),

                        // จุดบอกตำแหน่งสไลด์
                        Positioned(
                          bottom: 8,
                          child: Row(
                            children: List.generate(_bannerCount, (i) {
                              final active = i == _currentBanner;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: active ? 18 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active ? Colors.white : Colors.white70,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ===== End banner =====

                  const SizedBox(height: 12),

                  // Category scrollable button bar (selectable) (ไม่มีการเปลี่ยนแปลง)
                  SizedBox(
                    height: 48,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: List.generate(_categories.length, (i) {
                          final c = _categories[i];
                          final selected = _selectedCategoryIndex == i;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategoryIndex = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.orange.shade100 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: selected ? Colors.deepOrange : Colors.transparent),
                                ),
                                child: Text(
                                  c,
                                  style: GoogleFonts.prompt(
                                    fontSize: 14,
                                    color: selected ? Colors.deepOrange : Colors.black87,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Section title + actions (API สินค้า + ดูทั้งหมด) (ไม่มีการเปลี่ยนแปลง)
                  Row(
                    children: [
                      Text(
                        'สินค้าขายดี',
                        style: GoogleFonts.prompt(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProductListPage()),
                          );
                        },
                        icon: const Icon(Icons.api, size: 18),
                        label: Text('รายการ API สินค้า', style: GoogleFonts.prompt()),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProductListPage()),
                          );
                        },
                        child: Text('ดูทั้งหมด', style: GoogleFonts.prompt()),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Product grid (ไม่มีการเปลี่ยนแปลง, แต่ใช้ _ProductCard ที่ได้รับการแก้ไข)
                  Builder(builder: (context) {
                    final selectedCategory = _categories[_selectedCategoryIndex];
                    final shownProducts = selectedCategory == 'ทั้งหมด'
                        ? _products
                        : _products.where((p) {
                            final cat = p.data['category'];
                            return cat != null && cat.toString() == selectedCategory;
                          }).toList();

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: shownProducts.length,
                      itemBuilder: (context, index) {
                        final product = shownProducts[index];
                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => _buildProductDetailsSheet(ctx, product),
                            );
                          },
                          child: _ProductCard(product: product, pb: pb),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
    );
  }

  // ✅ แก้ไขส่วนนี้: ให้ดึง URL ภาพจาก PocketBase ได้
  Widget _buildProductDetailsSheet(BuildContext ctx, RecordModel product) {
    final name = product.data['name']?.toString() ?? 'ไม่มีชื่อสินค้า';
    
    // โค้ดใหม่สำหรับสร้าง URL รูปภาพ
    String imageUrl = '';
    final urlField = product.data['imageUrl']?.toString() ?? '';
    if (urlField.isNotEmpty && urlField.toLowerCase().startsWith('http')) {
      imageUrl = urlField;
    } else {
      final fileName = product.data['image']?.toString() ?? '';
      if (fileName.isNotEmpty) {
        imageUrl = pb.files.getUrl(product, fileName).toString(); // ใช้ pb.files.getUrl
      } else {
        imageUrl = 'https://via.placeholder.com/400x400?text=No+Image';
      }
    }
    
    final price = product.data['price']?.toString() ?? '0.0';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: CachedNetworkImage( // ใช้ CachedNetworkImage
              imageUrl: imageUrl,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (c, s) => Container(color: Colors.grey[200]),
              errorWidget: (c, e, st) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Text('ราคา: ฿$price', style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.redAccent)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () { Navigator.of(ctx).pop(); /* TODO add to cart */ },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('เพิ่มในตะกร้า', style: GoogleFonts.prompt()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () { Navigator.of(ctx).pop(); /* TODO: buy now */ },
                  child: Text('ซื้อทันที', style: GoogleFonts.prompt()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: _isDeleting
                      ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,))
                      : const Icon(Icons.delete, color: Colors.redAccent),
                  label: _isDeleting
                      ? Text('กำลังลบ...', style: GoogleFonts.prompt(color: Colors.redAccent))
                      : Text('ลบสินค้า', style: GoogleFonts.prompt(color: Colors.redAccent)),
                  onPressed: _isDeleting ? null : () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (dctx) => AlertDialog(
                        title: Text('ยืนยันการลบ', style: GoogleFonts.prompt()),
                        content: Text('ต้องการลบสินค้านี้ใช่หรือไม่?', style: GoogleFonts.prompt()),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: Text('ยกเลิก', style: GoogleFonts.prompt())),
                          TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: Text('ลบ', style: GoogleFonts.prompt())),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    setState(() => _isDeleting = true);
                    try {
                      final id = product.id.toString();
                      if (id.isEmpty) throw Exception('Invalid product id');
                      await _service.delete(product.id);
                      // remove locally
                      setState(() {
                        _products.removeWhere((p) => p.id == product.id);
                      });
                      // notify other pages immediately
                      AppEvents.notifyProductDeleted(id);
                      Navigator.of(ctx).pop(); // close bottom sheet
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ลบสินค้าเรียบร้อย', style: GoogleFonts.prompt())),
                        );
                      }
                    } catch (e) {
                      Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ไม่สามารถลบสินค้า: $e', style: GoogleFonts.prompt())),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isDeleting = false);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final RecordModel product;
  final PocketBase pb;

  const _ProductCard({required this.product, required this.pb});

  // ✅ เพิ่มฟังก์ชันเพื่อสร้าง URL ของรูปภาพ
  String _getImageUrl() {
    // 1. ลองดึงจากฟิลด์ 'imageUrl' ก่อน
    final urlField = product.data['imageUrl']?.toString() ?? '';
    if (urlField.isNotEmpty && urlField.toLowerCase().startsWith('http')) {
      return urlField;
    }

    // 2. ลองดึงจากฟิลด์ 'image' (ชื่อไฟล์ PocketBase)
    final fileName = product.data['image']?.toString() ?? '';
    if (fileName.isNotEmpty) {
      return pb.files.getUrl(product, fileName).toString();
    }

    // 3. ภาพ Placeholder
    return 'https://via.placeholder.com/400x600?text=No+Image';
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _getImageUrl(); // ✅ ใช้ฟังก์ชันใหม่

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage( // ใช้ CachedNetworkImage
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (c, s) => Container(color: Colors.grey[200]),
                errorWidget: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.data['name']?.toString() ?? '',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.blue.shade900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '฿${product.data['price']?.toString() ?? '0.0'}',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.lightBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}