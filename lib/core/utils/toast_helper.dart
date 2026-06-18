import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class ToastHelper {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Batalkan toast sebelumnya jika sedang aktif
    _currentEntry?.remove();
    _currentEntry = null;
    _timer?.cancel();

    final overlayState = Overlay.of(context);
    
    _currentEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
          _timer?.cancel();
        },
      ),
    );

    overlayState.insert(_currentEntry!);

    _timer = Timer(duration, () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }

  // Helper shortcuts
  static void success(BuildContext context, String message) {
    show(context, message: message, type: ToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: ToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: ToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: ToastType.info);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    _dismissTimer = Timer(widget.duration - const Duration(milliseconds: 300), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (_removed || !mounted) return;
    _removed = true;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Pilih warna dan ikon berdasarkan tipe toast
    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final Color iconColor;

    switch (widget.type) {
      case ToastType.success:
        bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
        textColor = isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
        break;
      case ToastType.error:
        bgColor = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
        textColor = isDark ? const Color(0xFFFEE2E2) : const Color(0xFF991B1B);
        icon = Icons.error_rounded;
        iconColor = isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
        break;
      case ToastType.warning:
        bgColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
        textColor = isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E);
        icon = Icons.warning_rounded;
        iconColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
        break;
      case ToastType.info:
        bgColor = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
        textColor = isDark ? const Color(0xFFDBEAFE) : const Color(0xFF1E40AF);
        icon = Icons.info_rounded;
        iconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
        break;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) {
                  _removed = true;
                  widget.onDismiss();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: iconColor, size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
