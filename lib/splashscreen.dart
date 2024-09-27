import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:qams/homescreen.dart';
import 'package:qams/loginscreen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        children: [
          Lottie.asset('assets/animation/newss.json'), // Add your animation path here
          //const SizedBox(height: 20),
          const Text(
            "Welcome to AMS.",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white
            ),
          ),
        ],
      ),
      splashIconSize: 450,
      duration: 5000, // Splash screen duration in milliseconds
      nextScreen: FutureBuilder(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, AsyncSnapshot<User?> snapshot) {
          // Check if the user is authenticated
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());  // Still loading
          } else if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();  // User is authenticated, navigate to HomeScreen
          } else {
            return const LoginScreen();  // User not authenticated, navigate to LoginScreen
          }
        },
      ),
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: Colors.black,  // Background color for splash screen
      animationDuration: const Duration(seconds: 1),
    );
  }
}
