import 'dart:async';
import 'package:flutter/material.dart';

class EventPopupOverlay extends StatefulWidget {
  final Map<String, dynamic>? event;
  final VoidCallback onDismiss;

  const EventPopupOverlay({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  State<EventPopupOverlay> createState() => _EventPopupOverlayState();
}

class _EventPopupOverlayState extends State<EventPopupOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    if (widget.event != null) {
      _show();
    }
  }

  @override
  void didUpdateWidget(EventPopupOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event != null && widget.event?['id'] != oldWidget.event?['id']) {
      _show();
    }
  }

  void _show() {
    _controller.forward(from: 0.0);
    _dismissTimer?.cancel();
    
    final payload = widget.event?['payload'] as Map<String, dynamic>?;
    final durationMs = payload?['durationMs'] as int? ?? 3000;

    _dismissTimer = Timer(Duration(milliseconds: durationMs), () {
      if (context.mounted) {
        _controller.reverse().then((_) {
          if (context.mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event == null) return const SizedBox.shrink();

    final type = widget.event?['type'] as String?;
    final payload = widget.event?['payload'] as Map<String, dynamic>?;
    final message = payload?['message'] as String? ?? '';

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case 'CAUGHT':
        backgroundColor = Colors.blue.withValues(alpha: 0.9);
        icon = Icons.lock;
        break;
      case 'RESCUED':
        backgroundColor = Colors.green.withValues(alpha: 0.9);
        icon = Icons.favorite;
        break;
      case 'KEY_USED':
        backgroundColor = Colors.orange.withValues(alpha: 0.9);
        icon = Icons.vpn_key;
        break;
      case 'GAME_STARTED':
        backgroundColor = Colors.indigo.withValues(alpha: 0.9);
        icon = Icons.play_arrow;
        break;
      case 'GAME_ENDED':
        backgroundColor = Colors.black.withValues(alpha: 0.9);
        icon = Icons.stop;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.9);
        icon = Icons.info;
    }

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
