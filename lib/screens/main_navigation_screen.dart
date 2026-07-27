import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'explorer_screen.dart';
import 'collection_screen.dart';
import '../providers/explorer_provider.dart';
import '../widgets/pill_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExplorerScreen(),
    CollectionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Same flag ExplorerScreen watches to hide its search bar — kept in
    // sync so the navbar and search bar hide/show together around the
    // album detail modal.
    final hideForModal = context.watch<ExplorerProvider>().isDetailModalOpen;

    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 201, 98, 98),
      body: Stack(
        children: [

          // Pages conservées en mémoire
          Stack(
            children: List.generate(
              _screens.length,
              (index) {
                return IgnorePointer(
                  ignoring: _currentIndex != index,

                  child: AnimatedOpacity(
                    opacity: _currentIndex == index ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,

                    child: _screens[index],
                  ),
                );
              },
            ),
          ),


          // Navbar flottante
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: IgnorePointer(
              ignoring: hideForModal,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: hideForModal ? const Offset(0, 0.6) : Offset.zero,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: hideForModal ? 0 : 1,
                  child: SafeArea(
                    child: PillNavBar(
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        if (index == _currentIndex) return;

                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}