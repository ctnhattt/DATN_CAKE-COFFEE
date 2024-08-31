import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Product {
  String id;
  String id_category_product;
  String name;
  double price;
  String id_unit_product;
  String image;
  final String? description;
  String note;
  int quantity;
  DateTime? createTime;
  DateTime? updateTime;
  DateTime? deleteTime;
  String categoryName;

  Product({
    required this.id,
    required this.id_category_product,
    required this.name,
    required this.price,
    required this.id_unit_product,
    required this.image,
    this.description,
    required this.note,
    this.quantity = 1,
    this.createTime,
    this.updateTime,
    this.deleteTime,
    required this.categoryName,
  });

  factory Product.fromFirestore(DocumentSnapshot doc, String categoryName) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      id_category_product: data['id_category_product'],
      name: data['name'],
      price: data['price'].toDouble(),
      id_unit_product: data['id_unit_product'],
      image: data['image'],
      description: data['description'],
      note: data['note'],
      createTime: (data['createTime'] as Timestamp?)?.toDate(),
      updateTime: (data['updateTime'] as Timestamp?)?.toDate(),
      deleteTime: (data['deleteTime'] as Timestamp?)?.toDate(),
      categoryName: categoryName,
    );
  }

   static fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> doc) {}

  // Hàm định dạng giá tiền tĩnh
  static String formatPrice(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  // Hàm định dạng giá tiền của đối tượng hiện tại
  String getFormattedPrice() {
    return Product.formatPrice(price);
  }
}
