import 'package:flutter/material.dart';

class Searchveg extends StatefulWidget {
  const Searchveg({super.key});

  @override
  State< Searchveg> createState() => _SearchvegState();
}

class _SearchvegState extends State< Searchveg> {
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Products'),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              // Navigate to home page
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightGreen, Colors.green], // Change to your preferred colors
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Perform search
                    },
                    child: Text('Search'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  _buildProductItem('Brinjal\t\t(Rs.24)', 'assets/626.jpg', () {
                    // Handle product tap
                  }),
                  _buildProductItem('Carrots\t\t(Rs.19)', 'assets/65075.jpg', () {
                    // Handle product tap
                  }),
                  _buildProductItem('Broccolli\t\t(Rs.25)', 'assets/fresh-broccoli-isolated.jpg', () {
                    // Handle product tap
                  }),
                  _buildProductItem('tomatoes\t\t(Rs.40)', 'assets/tomatoes.jpg', () {
                    // Handle product tap
                  }),
                  _buildProductItem('Spinach\t\t(Rs.30)', 'assets/spinach.jpg', () {
                    // Handle product tap
                  }),
                  _buildProductItem('Cabbage\t\t(Rs.30)', 'assets/cabbage.jpg', () {
                    // Handle product tap
                  }),
                  // Add more product items here
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(String productName, String imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                productName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart),
              onPressed: () {
                // Add product to cart
              },
            ),
          ],
        ),
      ),
    );
  }
}




