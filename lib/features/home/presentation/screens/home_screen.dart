import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app_api_26/features/home/presentation/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late CollectionReference<Map<String, dynamic>> productsReference ;

  @override
  void initState() {
    super.initState();
    getProducts();
  }
  
  void getProducts() {

    productsReference=FirebaseFirestore.instance.collection("Products");
  }
  
  
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dummyProducts = List.generate(
      10,
      (index) => {
        'id': index,
        'title': 'Product ${index + 1}',
        'description': 'Modern design for daily life',
        'price': (index + 1) * 20.0,
        'image': 'https://via.placeholder.com/150',
      },
    );

    TextEditingController _nameController = TextEditingController(),
        _descriptionController = TextEditingController(),
        _priceController = TextEditingController(),
        _imageUrlController = TextEditingController();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: (){
            showDialog(
                context: context,
                builder: (context)=>AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration:  InputDecoration(labelText: 'Name'),
                      ),
                      TextField(
                        controller: _descriptionController,
                        decoration:  InputDecoration(labelText: 'Description'),
                      ),
                      TextField(
                        controller: _priceController,
                        decoration:  InputDecoration(labelText: 'Price'),
                      ),
                      TextField(
                        controller: _imageUrlController,
                        decoration:  InputDecoration(labelText: 'Image Url'),
                      ),
                      ElevatedButton(
                          onPressed: ()async{
                            var documentRef =
                            await productsReference.add({
                              'name': _nameController.text,
                              'description': _descriptionController.text,
                              'price': double.parse(_priceController.text),
                              'image_url': _imageUrlController.text,
                            });

                          },
                          child: Text('Add Product')
                      ),
                    ],
                  ),
                ),
            );
          }
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome,', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const Text('Our Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black)),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.blue),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.blue),
                  ),
                ),
              ),
            ),
            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Shoes', 'Shirts', 'Tech', 'Home'].map((cat) {
                  bool isAll = cat == 'All';
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isAll ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (!isAll)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                          )
                      ],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isAll ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Products Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder(
                future: productsReference.get(),
                builder: (context, asyncSnapshot) {
                  if(!asyncSnapshot.hasData){
                    return const Center(child: CircularProgressIndicator());
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: asyncSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final product = asyncSnapshot.data!.docs[index].data();
                      return ProductCard(
                        title: product['name'],
                        price: product['price'],
                        description: product['description'],
                        image: product['image_url'],
                      );
                    },
                  );
                }
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
