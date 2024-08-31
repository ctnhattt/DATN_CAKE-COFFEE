import 'package:do_an_tot_nghiep/Model/products.dart';
import 'package:do_an_tot_nghiep/Model/provider.dart';
// import 'package:do_an_tot_nghiep/Views/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class GiaoDienDonHang extends StatefulWidget {
  final String title;

  final List<Product> selectedProducts;

  final String? tableId;

  const GiaoDienDonHang({
    Key? key,
    required this.title,
    required this.selectedProducts,
    this.tableId,
  }) : super(key: key);

  @override
  State<GiaoDienDonHang> createState() => _GiaoDienDonHangState();
}

class _GiaoDienDonHangState extends State<GiaoDienDonHang> {
  int isTableActive = 0;
  int badgeCount = 0;
  List<Product> additionalProducts = [];
  @override
  void initState() {
    super.initState();
    _updateBadgeCount(widget.selectedProducts.length);
    if (widget.tableId != null) {
      _handleTableId(widget.tableId!);
    }
  }

  void _updateBadgeCount(int newBadgeCount) {
    setState(() {
      badgeCount = newBadgeCount;
    });
    final provider = Provider.of<BadgeCountProvider>(context, listen: false);
    provider.updateBadgeCount(newBadgeCount);
  }

  void _handleTableId(String idTables) async {
    DocumentSnapshot tableSnapshot = await FirebaseFirestore.instance
        .collection('tables')
        .doc(idTables)
        .get();

    if (tableSnapshot.exists) {
      String status = tableSnapshot['status'];
      if (status == 'Đang hoạt động') {
        setState(() {
          isTableActive = 1;
        });
      } else if (status == 'Chờ duyệt') {
        setState(() {
          isTableActive = 2;
        });
      } else if ( status == 'Gọi thêm') {
        setState(() {
          isTableActive = 3;
        });
      }
    } else {
      setState(() {
        isTableActive = 0;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (widget.tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có ID bàn. Không thể đặt hàng.')),
      );
      return;
    }

    // Gọi các món mới
    for (var product in widget.selectedProducts) {
      if (isTableActive == 1||isTableActive==3) {
        await _addToOrder2(product);
      } else if(isTableActive==2||isTableActive==0){
        await _addToOrder(product);
      }
    }
    // Nếu bàn đang hoạt động, gộp các món từ order_details2 lên order_details
    if (isTableActive == 1|| isTableActive==3) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Các món của bạn đang chờ duyệt!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công!')),
      );
      await _mergeAdditionalProducts();
    }
    final provider = Provider.of<BadgeCountProvider>(context, listen: false);
    provider.updateBadgeCount(0);
    setState(() {
      widget.selectedProducts.clear();
    });
  }

 Future<void> _mergeAdditionalProducts() async {
  
  final orderDetails2Ref = FirebaseFirestore.instance
      .collection('orders')
      .doc(widget.tableId)
      .collection('order_details2');

  final orderDetailsRef = FirebaseFirestore.instance
      .collection('orders')
      .doc(widget.tableId)
      .collection('order_details');

  
  final additionalProductsSnapshot = await orderDetails2Ref.get();
  for (var additionalProductDoc in additionalProductsSnapshot.docs) {
    await additionalProductDoc.reference.delete();
  }

  for (var additionalProductDoc in additionalProductsSnapshot.docs) {
    final productId = additionalProductDoc.id;
    final productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();

    if (productDoc.exists) {
      final productData = productDoc.data()!;
      final existingProductDoc = await orderDetailsRef.doc(productId).get();

      if (existingProductDoc.exists) {
      
        await existingProductDoc.reference.update({
          'quantity': FieldValue.increment(additionalProductDoc['quantity']),
        });
      } else {
        // Nếu sản phẩm chưa tồn tại trong order_details, thêm mới sản phẩm
        await orderDetailsRef.doc(productId).set({
          'product_id': productId,
          'product_name': productData['name'],
          'quantity': additionalProductDoc['quantity'],
          'note': additionalProductDoc['note'] ?? '',
          'price': productData['price'],
        });
      }
    }
  }

  
  
}


  Stream<List<Product>> _getTableOrderProducts(String tableId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .doc(tableId)
        .collection('order_details')
        .snapshots()
        .asyncMap((orderSnapshot) async {
      final products = <Product>[];

      for (var orderDoc in orderSnapshot.docs) {
        final productId = orderDoc.id;
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final productData = productDoc.data()!;
          final product = Product.fromFirestore(
              productDoc, productData['id_category_product']);
          product.quantity = orderDoc['quantity'] ?? 1;

          products.add(product);
        }
      }

      return products;
    });
  }

  Future<void> _addToOrder(Product product) async {
    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.tableId)
        .collection('order_details')
        .doc(product.id);

    var existingOrder = await orderRef.get();
    if (existingOrder.exists) {
      int currentQuantity = existingOrder['quantity'] ?? 0;
      int newQuantity = currentQuantity + product.quantity;

      await orderRef.update({
        'quantity': newQuantity,
        'note': product.note,
      });
    } else {
      await orderRef.set({
        'product_id': product.id,
        'product_name': product.name,
        'quantity': product.quantity,
        'note': product.note,
        'price': product.price,
      });
    }

    setState(() {
      additionalProducts.add(product);
    });
    final provider = Provider.of<BadgeCountProvider>(context, listen: false);
    provider.updateBadgeCount(widget.selectedProducts.length);
    await FirebaseFirestore.instance
        .collection('tables')
        .doc(widget.tableId)
        .update({
      'status': 'Chờ duyệt',
    });
  }

  Future<void> _addToOrder2(Product product) async {
    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.tableId)
        .collection('order_details2')
        .doc(product.id);

    var existingOrder = await orderRef.get();
    if (existingOrder.exists) {
      int currentQuantity = existingOrder['quantity'] ?? 0;
      int newQuantity = currentQuantity + product.quantity;

      await orderRef.update({
        'quantity': newQuantity,
        'note': product.note,
      });
    } else {
      await orderRef.set({
        'product_id': product.id,
        'product_name': product.name,
        'quantity': product.quantity,
        'note': product.note,
        'price': product.price,
      });
    }

    setState(() {
      additionalProducts.add(product);
    });
    final provider = Provider.of<BadgeCountProvider>(context, listen: false);
    provider.updateBadgeCount(widget.selectedProducts.length);
    await FirebaseFirestore.instance
        .collection('tables')
        .doc(widget.tableId)
        .update({
      'status': 'Gọi thêm',
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.selectedProducts.fold(
      0,
      (sum, product) => sum + (product.price * product.quantity).toInt(),
    );
    if (isTableActive == 1 || isTableActive == 2||isTableActive==3) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(194, 101, 30, 0.871),
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tables')
                .doc(widget.tableId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Đang tải...');
              } else if (snapshot.hasError) {
                return const Text('Lỗi');
              } else if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text('Không có thông tin');
              }

              final tableName = snapshot.data!.get('name');
              // final tableStatus = snapshot.data!.get('status');
              return Text('Đơn hàng bàn $tableName ');
            },
          ),
        ),
        body: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Padding(
      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        'Thông tin món đã gọi:',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    Expanded(
      flex: 1,
      child: StreamBuilder<List<Product>>(
        stream: _getTableOrderProducts(widget.tableId!),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Center(child: CircularProgressIndicator());
          // } else if (snapshot.hasError) {
          //   return const Center(child: Text('Có lỗi xảy ra'));
          // } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          //   return const Center(child: Text('Không có món nào'));
          // }

          final products = snapshot.data!;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: Image.network(
                  product.image,
                  width: 50,
                  height: 50,
                ),
                title: Text(product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${product.price} đ'),
                    Text('Số lượng: ${product.quantity}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    ),
    if (widget.selectedProducts.isNotEmpty) ...[
      const Divider(height: 5, color: Colors.grey),
      const Padding(
        padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
        child: Text(
          'Thông tin món thêm:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        flex: 1,
        child: ListView.builder(
          itemCount: widget.selectedProducts.length,
          itemBuilder: (context, index) {
            final product = widget.selectedProducts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Stack(
                children: [
                  Container(
                    color: Colors.grey[300],
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Image.network(
                            product.image,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey,
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(fontSize: 20),
                              ),
                              Text(
                           product.getFormattedPrice(),
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.grey),
                              ),
                              Text(
                                "Ghi chú: ${product.note}",
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          final provider =
                              Provider.of<BadgeCountProvider>(context,
                                  listen: false);
                          widget.selectedProducts.removeAt(index);
                          provider.updateBadgeCount(
                              widget.selectedProducts.length);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        color: Colors.red,
                        child: const Text(
                          'Xóa',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    right: -7,
                    child: Row(
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
                          color: const Color.fromRGBO(194, 101, 30, 0.871),
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
                          color:const Color.fromRGBO(194, 101, 30, 0.871),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
    Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(194, 101, 30, 0.871),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: StreamBuilder<List<Product>>(
              stream: _getTableOrderProducts(widget.tableId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Loading...",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Text('Lỗi');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Không có dữ liệu');
                }

                final products = snapshot.data!;
                final totalAmountOldOrders = products.fold<int>(
                  0,
                  (previousValue, element) =>
                      previousValue +
                      (element.price * element.quantity).toInt(),
                );
                final totalAmountNewOrders = widget.selectedProducts.fold<int>(
                  0,
                  (previousValue, element) =>
                      previousValue +
                      (element.price * element.quantity).toInt(),
                );
                final totalAmount =
                    totalAmountOldOrders + totalAmountNewOrders;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền',
                          style: TextStyle(fontSize: 28),
                        ),
                        Text(
                          Product.formatPrice(totalAmount as double),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton(
                        onPressed: widget.selectedProducts.isEmpty
                            ? null
                            : () async {
                                await _placeOrder();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(162, 109, 59, 1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Đặt món'),
                      ),
                    ),
                    if (widget.selectedProducts.isEmpty)
                      const Center(
                        child: Text('Bạn đã gọi món rồi. Thêm món mới nào!'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  ],
),

      );
    } else {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: const Color.fromRGBO(194, 101, 30, 0.871),
          title: const Text(
            'Đơn hàng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: widget.selectedProducts.isEmpty
            ? const Center(
                child: Text(
                  'Bạn chưa có đơn hàng nào',
                  style: TextStyle(fontSize: 20),
                ),
              )
            : Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.only(left: 10, right: 10, top: 10),
                    color: Colors.white,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thông tin đơn hàng',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Số lượng   ',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.selectedProducts.length,
                      itemBuilder: (context, index) {
                        final product = widget.selectedProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: Stack(
                            children: [
                              Container(
                                color: Colors.grey[300],
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    children: [
                                      Image.network(
                                        product.image,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 70,
                                            height: 70,
                                            color: Colors.grey,
                                            child: const Icon(
                                              Icons.error,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                          Text(
                                       product.getFormattedPrice(),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "Ghi chú: ${product.note}",
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      final provider =
                                          Provider.of<BadgeCountProvider>(
                                              context,
                                              listen: false);
                                      widget.selectedProducts.removeAt(index);

                                      provider.updateBadgeCount(
                                          widget.selectedProducts.length);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    color: Colors.red,
                                    child: const Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -6,
                                right: -7,
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          if (product.quantity > 1) {
                                            product.quantity--;
                                          }
                                        });
                                      },
                                      icon:
                                          const Icon(Icons.remove_circle_sharp),
                                      iconSize: 25,
                                      color: const Color.fromRGBO(194, 101, 30, 0.871),
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
                                      color: const Color.fromRGBO(194, 101, 30, 0.871),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color.fromARGB(255, 222, 148, 148),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng tiền',
                              style: TextStyle(fontSize: 28),
                            ),
                            Text(
                               Product.formatPrice(totalAmount as double),
                              style: const TextStyle(fontSize: 28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton(
                            onPressed: _placeOrder,
                            style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(162, 109, 59, 1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Đặt món'),
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
}
