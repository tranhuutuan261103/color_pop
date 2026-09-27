import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/view/home_page.dart';
import '../../library/view/library_screen.dart';
import '../../profile/view/profile_screen.dart';
import '../../creator/view/creator_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),        // Index 0: HomeTab
    const LibraryScreen(),   // Index 1: LibraryTab
    const CreatorScreen(),   // Index 2: Create (Screen)
    const Center(child: Text('Khám phá')), // Index 3: Discover (Placeholder)
    const ProfileScreen(),   // Index 4: ProfileTab
  ];

  // Xử lý logic khi bấm vào thanh điều hướng
  void _onBottomNavTapped(int index) {
    if (index == 0) {
      // Refresh home data when switching to home tab
      context.read<HomeCubit>().loadHomeData();
    }
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
