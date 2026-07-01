import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // كل عنصر في الـ list ده فيه بيانات المنتج + الكمية
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  Future<void> loadCart() async {
    setState(() => isLoading = true);

    String userId = FirebaseAuth.instance.currentUser!.uid;

    // 1. نجيب الـ cart map من document اليوزر
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    Map<String, dynamic> data = userSnapshot.data()! as Map<String, dynamic>;
    Map<String, dynamic> cart = data['cart'] != null
        ? Map<String, dynamic>.from(data['cart'])
        : {};

    if (cart.isEmpty) {
      setState(() {
        cartItems = [];
        isLoading = false;
      });
      return;
    }

    // 2. لكل product ID في الـ cart، نجيب تفاصيله من Products collection
    List<Map<String, dynamic>> loadedItems = [];
    for (String productId in cart.keys) {
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('Products')
          .doc(productId)
          .get();

      if (productSnapshot.exists) {
        Map<String, dynamic> productData =
        productSnapshot.data()! as Map<String, dynamic>;
        loadedItems.add({
          'id': productId,
          'title': productData['name'],
          'price': productData['price'],
          'image': productData['image_url'],
          'quantity': cart[productId],
        });
      }
    }

    setState(() {
      cartItems = loadedItems;
      isLoading = false;
    });
  }

  // حساب السعر الإجمالي
  double get totalPrice {
    return cartItems.fold(0.0, (sum, item) {
      return sum + ((item['price'] as double) * (item['quantity'] as int));
    });
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    Map<String, dynamic> cart = Map<String, dynamic>.from(
        (snapshot.data()! as Map<String, dynamic>)['cart'] ?? {});

    if (newQuantity <= 0) {
      cart.remove(productId);
    } else {
      cart[productId] = newQuantity;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'cart': cart});

    // نعمل reload للشاشة
    await loadCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                  fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // صورة المنتج
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item['image'] != null &&
                            item['image'].toString().isNotEmpty
                            ? Image.network(
                          item['image'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.blue.shade50,
                            child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.blue),
                          ),
                        )
                            : Container(
                          width: 80,
                          height: 80,
                          color: Colors.blue.shade50,
                          child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // اسم المنتج والسعر
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${((item['price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // أزرار الكمية
                      Column(
                        children: [
                          Row(
                            children: [
                              _buildQtyBtn(Icons.remove, () {
                                updateQuantity(
                                  item['id'],
                                  (item['quantity'] as int) - 1,
                                );
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text(
                                  '${item['quantity']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              _buildQtyBtn(Icons.add, () {
                                updateQuantity(
                                  item['id'],
                                  (item['quantity'] as int) + 1,
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => updateQuantity(item['id'], 0),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // قسم الـ Total والـ Checkout
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 16),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.black),
      ),
    );
  }
}