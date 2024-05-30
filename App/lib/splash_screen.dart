import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Import ui package for using ImageFilter

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3), // Adjusted duration to 3 seconds
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with BackdropFilter for blur effect
          Image.asset(
            'assets/2705.jpg', // Replace with your image path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Apply blur effect using BackdropFilter
          BackdropFilter(
            filter: ui.ImageFilter.blur(
                sigmaX: 0,
                sigmaY: 0), // Adjust sigmaX and sigmaY for blur intensity
            child: Container(
              color: Colors.black.withOpacity(0.3), // Adjust opacity as needed
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Add your logo widget here
                    Image.asset(
                      'assets/logo.webp', // Replace 'assets/logo.png' with your logo image path
                      width: 100, // Adjust width as needed
                      height: 100, // Adjust height as needed
                    ),
                    SizedBox(
                        height: 20), // Add some spacing between logo and text
                    FadeTransition(
                      opacity: _animation,
                      child: Text(
                        'FarmToFork',
                        style: TextStyle(
                          fontSize: 48, // Adjust font size
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pacifico', // Apply Pacifico font family
                          color: Colors.green, // Adjust text color
                        ),
                      ),
                    ),

                    SizedBox(
                        height:
                            20), // Add some spacing between text and spinner loader
                    CircularProgressIndicator(), // Add CircularProgressIndicator below the existing content
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
