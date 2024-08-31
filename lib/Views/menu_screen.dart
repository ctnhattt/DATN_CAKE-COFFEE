import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:do_an_tot_nghiep/Model/products.dart';
import 'package:do_an_tot_nghiep/Model/provider.dart';
import 'package:do_an_tot_nghiep/Views/drawer_screen.dart';
import 'package:do_an_tot_nghiep/Views/login_screen.dart';
import 'package:do_an_tot_nghiep/Views/oder_screen.dart';
import 'package:do_an_tot_nghiep/Views/register_screen.dart';
import 'package:do_an_tot_nghiep/Views/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import 'package:badges/badges.dart' as BadgesLibrary;

class TrangMenu extends StatefulWidget {
  const TrangMenu({super.key, required this.title});
  final String title;

  @override
  State<TrangMenu> createState() => _TrangMenuState();
}

class _TrangMenuState extends State<TrangMenu> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Product> selectedProducts = [];
  int badgeCount = 0;
  String tableId = '';
  String tableStatus = '';
  String? selectedOption;
  bool isTableStatus = false;
  bool isTableActive = false;
  bool _checkedTableStatus = false;
  

  Future<void> _gettableIdFromUrl() async {
    Uri uri = Uri.base;
    String? tableIdParam = uri.queryParameters['id_tables'];
    if (tableIdParam != null) {
      setState(() {
        tableId = tableIdParam;
      });

      // Kiểm tra trạng thái của bảng
      await _checkTableStatus(tableId);
    }
  }

  Future<void> _checkTableStatus(String idTables) async {
    final tableDoc = await FirebaseFirestore.instance
        .collection('tables')
        .doc(idTables)
        .get();

    if (tableDoc.exists) {
      final tableData = tableDoc.data();
      setState(() {
        tableStatus = tableData?['status'] ?? '';
        isTableActive = tableStatus == 'Đang hoạt động';
        isTableStatus = tableStatus == 'Trống';
      });
    } else {
      setState(() {
        tableStatus = '';
        isTableActive = false;
        isTableStatus = false;
      });
    }
  }

  void _addItemToCart(Product product) {
    final badgeProvider =
        Provider.of<BadgeCountProvider>(context, listen: false);
    setState(() {
      bool isExist = false;
      for (var item in selectedProducts) {
        if (item.name == product.name) {
          isExist = true;
          item.quantity++;
        }
      }

      if (!isExist) {
        selectedProducts.add(product);
      }

      badgeProvider.updateBadgeCount(selectedProducts.length);
      _updateBadgeCount();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm'),
          duration: Duration(seconds: 1),
        ),
      );
    });
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
                        style:
                            const TextStyle(fontSize: 20, color: Colors.blue),
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
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color.fromRGBO(194, 101, 30, 0.871)),
                          foregroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                          padding: WidgetStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0)),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8.0), // Đặt bo góc
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

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
                Text(
                  product.description ?? 'No description available',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initializeData() async {
    await _gettableIdFromUrl();
    await _checkTableStatus(tableId);
  }

  @override
  void initState() {
    super.initState();
    badgeCount = selectedProducts.length;
    _tabController = TabController(length: 3, vsync: this);
    _gettableIdFromUrl();
    _initializeData();
     final provider = Provider.of<BadgeCountProvider>(context, listen: false);
    if (!provider.isTableStatusChecked) {
      provider.setTableStatusChecked(true);
      if (isTableStatus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMembershipDialog(context);
        });
      }
    }
    
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateBadgeCount() {
    setState(() {
      badgeCount = selectedProducts.length;
    });
  }

  Stream<List<Product>> _getItems(String category) {
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
        final categoryId = productData['id_category_product'];
        final categoryName = categoriesMap[categoryId] ?? 'Unknown';

        if (categoryName.toLowerCase() == category.toLowerCase()) {
          products.add(Product.fromFirestore(doc, categoryName));
        }
      }
      return products;
    });
  }

  void _showMembershipDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Không cho phép bỏ qua bằng cách nhấn ra ngoài
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor:
                  Color.fromRGBO(194, 101, 30, 0.871), // Màu nền cam
              title: Text(
                selectedOption == null
                    ? 'Bạn đã là thành viên của Cake & Coffee chưa?'
                    : selectedOption == 'login'
                        ? 'Đăng nhập'
                        : 'Đăng ký',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (selectedOption == null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedOption = 'login';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white, // Màu chữ của nút
                          ),
                          child: Text('Đăng nhập'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedOption = 'register';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white, // Màu chữ của nút
                          ),
                          child: Text('Đăng kí'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      child: const Text('Tôi sẽ đăng kí sau >>>'),
                    ),
                  ] else if (selectedOption == 'login') ...[
                    LoginScreen(
                      onSuccess: () {
                        Navigator.pop(context);
                      },
                    ),
                  ] else if (selectedOption == 'register') ...[
                    RegisterScreen(
                      onSuccess: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                if (selectedOption != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedOption = null;
                      });
                    },
                    child: Text('Quay lại'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

 

  void _navigateToOrderScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiaoDienDonHang(
          tableId: tableId,
          selectedProducts: selectedProducts,
          title: 'Đơn hàng',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BadgeCountProvider>(context);

      
    
      if (!_checkedTableStatus && isTableStatus) {
    _checkedTableStatus = true; // Đánh dấu là đã kiểm tra
    _showMembershipDialog(context);
  }
  
    
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: AppBar(
          centerTitle: true,
          backgroundColor: const Color.fromRGBO(194, 101, 30, 0.871),
          title: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'MENU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tables')
                    .doc(tableId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Đang tải...',
                        style: TextStyle(fontSize: 16));
                  } else if (snapshot.hasError) {
                    return const Text('Lỗi', style: TextStyle(fontSize: 16));
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text('Không có thông tin',
                        style: TextStyle(fontSize: 16));
                  }

                  final tableName = snapshot.data!.get('name');
                  final tableStatus = snapshot.data!.get('status');
                  Color statusColor;
                  IconData statusIcon;

                  switch (tableStatus) {
                    case 'Đang hoạt động':
                      statusColor = Colors.green;
                      statusIcon = Icons.circle;
                      break;
                    case 'Chờ duyệt':
                      statusColor = Colors.red;
                      statusIcon = Icons.circle;
                      break;
                    case 'Gọi thêm':
                      statusColor = Colors.yellow;
                      statusIcon = Icons.circle;
                      break;
                    case 'Trống':
                      statusColor = Colors.white;
                      statusIcon = Icons.circle;
                      break;
                    default:
                      statusColor = Colors.black;
                      statusIcon = Icons.circle;
                  }

                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Bàn $tableName: ',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                        WidgetSpan(
                          child: Transform.translate(
                            offset: const Offset(0, -3.8),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: 12,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: ' $tableStatus',
                          style: TextStyle(fontSize: 16, color: statusColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                final newBadgeCount = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(
                      initialSelectedProducts: selectedProducts,
                      idTables: tableId,
                    ),
                  ),
                );

                if (newBadgeCount != null) {
                  setState(() {
                    provider.updateBadgeCount(newBadgeCount);
                  });
                }
              },
              icon: const Icon(
                Icons.search,
                color: Colors.black,
                size: 30.0,
              ),
            ),
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
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () {
                  if (Provider.of<AuthProvider>(context, listen: false)
                          .phoneNumber ==
                      '') {
                    _showMembershipDialog(context);
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                },
              );
            },
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: TabBar(
              isScrollable: false,
              controller: _tabController,
              labelColor: Colors.black,
              indicatorPadding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 1),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [SizedBox(width: 1), Text('Cake')],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [SizedBox(width: 1), Text('Bread')],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [SizedBox(width: 1), Text('Drink')],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCategoryTab('cake'),
            _buildCategoryTab('bread'),
            _buildCategoryTab('drink'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String category) {
    return StreamBuilder<List<Product>>(
      stream: _getItems(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Hệ thống không phản hồi!'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Chưa có dữ liệu!'));
        }

        final data = snapshot.data!;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final product = data[index];

              return GestureDetector(
                onTap: () {
                  _showOrderDetails(product);
                },
                onLongPress: () {
                  _showProductDetails(product);
                },
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 2000,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 238, 238, 238),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 233, 236, 229),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.getFormattedPrice(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -5,
                      right: -5,
                      child: IconButton(
                        onPressed: () {
                          _addItemToCart(product);
                        },
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color.fromRGBO(194, 101, 30, 0.871),
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
