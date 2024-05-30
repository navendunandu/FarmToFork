import 'package:flutter/material.dart';

class ItemBox extends StatefulWidget {
  const ItemBox({super.key});

  @override
  State<ItemBox> createState() => _ItemBoxState();
}

class _ItemBoxState extends State<ItemBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farm Image Placeholder (Replace with actual image)
          Center(
            child: Image.asset(
              'assets/house.jpg',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'NatureBites', // Replace with actual farm name
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Kothamangalam', // Replace with actual farm place
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Row(
            children: [
              Icon(Icons.star, color: Colors.yellow),
              Text(
                '4.5', // Replace with actual farm rating
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
