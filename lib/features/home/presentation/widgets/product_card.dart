import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app_api_26/features/auth/presentation/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//27.3.13750724
class ProductCard extends StatefulWidget {
  final String id;
  final String title;
  final double price;
  final String description;
  final String? image;
  final bool? isFavorite;

  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
     this.image, required this.id, required this.isFavorite,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool? isFavorite=widget.isFavorite;

  void addToFavorites(BuildContext context) async {
    setState(() {
      isFavorite=true;
    });
    if (FirebaseAuth.instance.currentUser == null) {
      print('User not logged in');
      Navigator.push(
          context,
          MaterialPageRoute(builder: (con)=> LoginScreen())
      ); // Navigate to login screen
    }
    String userId =FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snapshot= await FirebaseFirestore.instance.collection('users').doc(userId).get();
    List<dynamic> favorites = (snapshot.data()! as Map)['favorites'];
    if (favorites.contains(widget.id)){
      favorites.remove(widget.id);
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'favorites': favorites,
      });
    }else{
      favorites.add(widget.id);
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'favorites': favorites,
      });
    }


  }

  void addToCart(BuildContext context) async {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (con) => LoginScreen()),
      );
      return;
    }

    String userId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    Map<String, dynamic> data = snapshot.data()! as Map<String, dynamic>;

    // نجيب الـ cart الحالي — لو مش موجود نبدأ بـ map فاضية
    Map<String, dynamic> cart = data['cart'] != null
        ? Map<String, dynamic>.from(data['cart'])
        : {};

    if (cart.containsKey(widget.id)) {
      // المنتج موجود — زود الكمية بـ 1
      cart[widget.id] = (cart[widget.id] as int) + 1;
    } else {
      // المنتج مش موجود — ضيفه بكمية 1
      cart[widget.id] = 1;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'cart': cart});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.title} added to cart!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                   Center(
                      child: widget.image ==null?Icon(
                          Icons.shopping_bag_outlined,
                          size: 40,
                          color: Colors.blue,
                      ):Image.network(widget.image!),
                  ),
                  PositionBag(
                    top: 10,
                    right: 10,
                    child: Container(
                      //padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          onPressed: (){addToFavorites(context);},
                          style: IconButton.styleFrom(padding: EdgeInsets.zero),
                          icon: Icon(
                              isFavorite==true?Icons.favorite_outlined:Icons.favorite_border,
                              size: 18,
                              color: Colors.red)) ,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${widget.price}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => addToCart(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
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

class PositionBag extends StatelessWidget {
  final double? top;
  final double? right;
  final Widget child;
  const PositionBag({super.key, this.top, this.right, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(top: top, right: right, child: child);
  }
}
