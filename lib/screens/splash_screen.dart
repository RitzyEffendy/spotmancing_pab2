// Marcell
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotmancing_uas_pab2/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotmancing_uas_pab2/screens/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin{

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState () {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    Timer(const Duration(seconds: 3), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final username = user.displayName ?? user.email?.split('@')[0] ?? 'Pengguna';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainNavigation(username: username)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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
      backgroundColor: Colors.green[50],
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
            'assets/mancingmania.png',
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }
}