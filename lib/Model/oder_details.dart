import 'package:cloud_firestore/cloud_firestore.dart';
class OderDetails {
  final String productId;
  final String productName;
  int quantity; // Change to non-final
  final double price;

  OderDetails({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OderDetails.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OderDetails(
      productId: data['product_id'],
      productName: data['product_name'],
      quantity: data['quantity'],
      price: (data['price'] as num).toDouble(),
    );
  }

  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
  }
}

