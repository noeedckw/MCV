import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'explorer_screen.dart';
import 'collection_screen.dart';
import '../providers/explorer_provider.dart';
import '../providers/nav_bar_visibility_provider.dart';
import '../widgets/pill_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [ExplorerScreen(), CollectionScreen()];

  // Délai avant que la navbar ne réapparaisse une fois la condition
  // de hide levée (ex: le temps que le clavier redescende).
  static const _reappearDelay = Duration(milliseconds: 600);

  // Durées du fade, différentes selon le sens.
  static const _fadeOutDuration = Duration(milliseconds: 50);
  static const _fadeInDuration = Duration(milliseconds: 600);

  bool _visible = true;
  bool _lastHide = false;
  Timer? _reappearTimer;

  void _syncVisibility(bool hide) {
    if (hide == _lastHide) return;
    _lastHide = hide;

    if (hide) {
      _reappearTimer?.cancel();
      setState(() => _visible = false);
    } else {
      _reappearTimer?.cancel();
      _reappearTimer = Timer(_reappearDelay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _reappearTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hideForModal = context.watch<ExplorerProvider>().isDetailModalOpen ||
      context.watch<NavBarVisibilityProvider>().hidden;

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncVisibility(hideForModal));

    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 201, 98, 98),
      body: Stack(
        children: [
          Stack(
            children: List.generate(_screens.length, (index) {
              return IgnorePointer(
                ignoring: _currentIndex != index,
                child: AnimatedOpacity(
                  opacity: _currentIndex == index ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: _screens[index],
                ),
              );
            }),
          ),

          // Navbar flottante
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: IgnorePointer(
              ignoring: !_visible,
              child: AnimatedOpacity(
                duration: _visible ? _fadeInDuration : _fadeOutDuration,
                curve: Curves.easeInOut,
                opacity: _visible ? 1 : 0,
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
        ],
      ),
    );
  }
}