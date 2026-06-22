// Darma
import 'package:flutter/material.dart';
import 'package:spotmancing_uas_pab2/screens/home_screen.dart';
import 'package:spotmancing_uas_pab2/screens/favorite_screen.dart';
import 'package:spotmancing_uas_pab2/screens/post_screen.dart';
import 'package:spotmancing_uas_pab2/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final String username;
  const MainNavigation({super.key, required this.username});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(username: widget.username),
      const FavoriteScreen(),
      const PostScreen(),
      ProfileScreen(username: widget.username),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.yellow.shade300,
          unselectedItemColor: Colors.yellow.shade100,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorit'),
            BottomNavigationBarItem(icon: Icon(Icons.add_location), label: 'Post Spot'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}