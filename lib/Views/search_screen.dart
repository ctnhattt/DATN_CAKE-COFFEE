import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_tot_nghiep/Model/provider.dart';
import 'package:do_an_tot_nghiep/Views/oder_screen.dart';
import 'package:flutter/material.dart';
import 'package:do_an_tot_nghiep/Model/products.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  final String idTables;
  final List<Product> initialSelectedProducts;

  const SearchScreen({
    super.key,
    required this.idTables,
    required this.initialSelectedProducts,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _keyword = '';
  List<Product> selectedProducts = [];
  int badgeCount = 0;

  @override
  void initState() {
    super.initState();
    selectedProducts = widget.initialSelectedProducts;
    badgeCount = selectedProducts.length;
  }

  void _searchProducts(String keyword) {
    setState(() {
      _keyword = keyword;
    });
  }

  Stream<List<Product>> _searchItems(String keyword) {
    return FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .asyncMap((snapshot) async {
      final categoriesSnapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      final categoriesMap = categoriesSnapshot.docs.fold<Map<String, String>>(
        {},
        (prev, doc) => prev..[doc.id] = doc['name'],
      );

      final products = <Product>[];
      for (var doc in snapshot.docs) {
        final productData = doc.data();
        final productName = productData['name'].toLowerCase();
        if (productName.contains(keyword.toLowerCase())) {
          final categoryId = productData['id_category_product'];
          final categoryName = categoriesMap[categoryId] ?? 'Unknown';
          products.add(Product.fromFirestore(doc, categoryName));
        }
      }
      return products;
    });
  }

  void _addItemToCart(Product product) {
    final badgeProvider =
        Provider.of<BadgeCountProvider>(context, listen: false);
    setState(() {
      bool isExist = false;
      for (var item in selectedProducts) {
        if (item.name == product.name) {
          isExist = true;
          break;
        }
      }

      if (!isExist) {
        // Thêm sản phẩm vào danh sách đã chọn
        selectedProducts.add(product);
        badgeProvider.updateBadgeCount(selectedProducts.length);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào đơn hàng'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _navigateToOrderScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiaoDienDonHang(
          tableId: widget.idTables,
          selectedProducts: selectedProducts,
          title: 'Đơn hàng',
        ),
      ),
    );
  }

  void _showOrderDetails(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                       Text(
                product.getFormattedPrice(),
                style: const TextStyle(fontSize: 20, color: Colors.blue),
                
              ),
              const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if (product.quantity > 1) {
                                  product.quantity--;
                                }
                              });
                            },
                            icon: const Icon(Icons.remove_circle_sharp),
                            iconSize: 25,
                          ),
                          SizedBox(
                            width: 25,
                            child: Text(
                              '${product.quantity}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                product.quantity++;
                              });
                            },
                            icon: const Icon(Icons.add_circle_sharp),
                            iconSize: 25,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Ghi chú',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            product.note =
                                value.isNotEmpty ? value : 'Không có ghi chú!';
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                     ElevatedButton(
                      onPressed: () {
                        _addItemToCart(product);
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(const Color.fromRGBO(194, 101, 30, 0.871)), 
                        foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                        padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)), 
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0), // Đặt bo góc
                          ),
                        ),
                      ),
                          child: const Text('Thêm món'),
                        ),

                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BadgeCountProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(194, 101, 30, 0.871),
        title: const Text('Tìm món'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (provider.badgeCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${provider.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            ),
            onPressed: _navigateToOrderScreen,
          ),
          
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                _searchProducts(value);
              },
              decoration: const InputDecoration(
                hintText: 'Nhập từ khóa',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _searchItems(_keyword),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Hệ thống không phản hồi!'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Không có món!'));
                }

                final data = snapshot.data!;

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final product = data[index];
                    return ListTile(
                      leading: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                      ),
                      title: Text(product.name),
                      subtitle: Text(product.getFormattedPrice(),),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Color.fromRGBO(194, 101, 30, 0.871)),
                        onPressed: () {
                          _showOrderDetails(product);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
