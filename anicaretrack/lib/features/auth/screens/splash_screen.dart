import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {

    const primary = Color(0xFF4A90E2);
    const mint = Color(0xFF7EDDD3);
    const cream = Color(0xFFFFF9F2);
    const text = Color(0xFF333333);

    return Scaffold(
      backgroundColor: cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              Icons.pets,
              size: 90,
              color: primary,
            ),

            const SizedBox(height: 20),

            const Text(
              "AniCareTrack",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: text,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Pet Care Made Easy",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(
              color: mint,
            ),
          ],
        ),
      ),
    );
  }
}