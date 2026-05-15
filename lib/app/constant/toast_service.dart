import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  bool _isLoading = false;
  OverlayEntry? _currentToast;

  void showLoader(String message) {
    try {
      if (_isLoading) return;
      _isLoading = true;

      final context = navigatorKey.currentContext;
      if (context == null) {
        _isLoading = false;
        return;
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(strokeWidth: 7, strokeCap: StrokeCap.round)),
                  const SizedBox(height: 24),
                  Text(message, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87, decoration: TextDecoration.none), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      developer.log("Error in showLoader: $e");
      _isLoading = false;
    }
  }

  void closeLoader() {
    try {
      final context = navigatorKey.currentContext;
      if (context != null && _isLoading) {
        Navigator.pop(context);
        _isLoading = false;
      }
    } catch (e) {
      developer.log("Error in closeLoader: $e");
      _isLoading = false;
    }
  }

  void showSuccessToast(String message, {ToastPosition position = ToastPosition.top}) {
    _showToast(message, backgroundColor: const Color(0xFF4CAF50), icon: Icons.check_circle);
  }

  void showErrorToast(String message, {ToastPosition position = ToastPosition.top}) {
    _showToast(message, backgroundColor: const Color(0xFFF44336), icon: Icons.error);
  }

  void showWarningToast(String message, {ToastPosition position = ToastPosition.top}) {
    _showToast(message, backgroundColor: const Color(0xFFFF9800), icon: Icons.warning);
  }

  void _showToast(String message, {required Color backgroundColor, required IconData icon}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _currentToast?.remove();
    _currentToast = null;

    final overlay = Overlay.of(context);

    _currentToast = OverlayEntry(
      builder: (context) => _TopToast(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: () {
          _currentToast?.remove();
          _currentToast = null;
        },
      ),
    );

    overlay.insert(_currentToast!);
  }
}

class _TopToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _TopToast({required this.message, required this.backgroundColor, required this.icon, required this.onDismiss});

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
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
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _controller.reverse().then((_) {
                  if (mounted) widget.onDismiss();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: widget.backgroundColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, decoration: TextDecoration.none),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.close, color: Colors.white.withValues(alpha: 0.7), size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ToastPosition {
  top,
  bottom,
}
