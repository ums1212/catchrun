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
                        _buildEventVisual(type, payload, icon),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
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

  Widget _buildEventVisual(String? type, Map<String, dynamic>? payload, IconData defaultIcon) {
    final actorSeed = payload?['actorAvatarSeed'] as String?;
    final targetSeed = payload?['targetAvatarSeed'] as String?;

    if (actorSeed == null && targetSeed == null) {
      return Icon(defaultIcon, color: Colors.white, size: 64);
    }

    if (targetSeed != null && (type == 'CAUGHT' || type == 'RESCUED')) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _avatarCircle(actorSeed!, size: 64),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          ),
          _avatarCircle(targetSeed, size: 64),
        ],
      );
    }

    return _avatarCircle(actorSeed ?? targetSeed!, size: 64);
  }

  Widget _avatarCircle(String seed, {double size = 64}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          'assets/image/profile$seed.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54),
        ),
      ),
    );
  }
}
