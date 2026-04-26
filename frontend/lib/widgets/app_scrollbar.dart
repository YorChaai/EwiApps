import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppScrollbar extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final Axis scrollDirection;
  final ScrollbarOrientation? scrollbarOrientation;
  final bool thumbVisibility;
  final bool trackVisibility;
  final double thickness;
  final double interactiveThickness;
  final Radius radius;
  final bool interactive;
  final ScrollNotificationPredicate? notificationPredicate;

  const AppScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.scrollbarOrientation,
    this.thumbVisibility = true,
    this.trackVisibility = true,
    this.thickness = 8.0,
    this.interactiveThickness = 16.0,
    this.radius = const Radius.circular(4),
    this.interactive = true,
    this.notificationPredicate,
  });

  @override
  State<AppScrollbar> createState() => _AppScrollbarState();
}

class _AppScrollbarState extends State<AppScrollbar> {
  Timer? _scrollTimer;
  bool _isHoldingTrack = false;
  static const double _scrollSpeed = 1000.0; // px per second

  void _startScrolling(Offset localPosition) {
    if (_scrollTimer != null) return;

    _isHoldingTrack = true;
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || !_isHoldingTrack || widget.controller == null || !widget.controller!.hasClients) {
        timer.cancel();
        _scrollTimer = null;
        return;
      }

      final position = widget.controller!.position;
      final maxScroll = position.maxScrollExtent;
      final viewport = position.viewportDimension;
      final totalContent = maxScroll + viewport;

      if (totalContent <= viewport) return;

      // Calculate track dimension
      // In RawScrollbar, track is usually the full length of the viewport
      final trackLength = viewport;
      
      // Relative position of touch on track (0.0 to 1.0)
      double relativeTouch;
      if (widget.scrollDirection == Axis.vertical) {
        relativeTouch = localPosition.dy / trackLength;
      } else {
        relativeTouch = localPosition.dx / trackLength;
      }
      relativeTouch = relativeTouch.clamp(0.0, 1.0);

      // Target offset in the scrollable content
      final targetOffset = relativeTouch * totalContent - (viewport / 2);
      final clampedTarget = targetOffset.clamp(0.0, maxScroll);

      final currentOffset = widget.controller!.offset;
      final distance = (clampedTarget - currentOffset).abs();

      if (distance < 5.0) {
        // Close enough, stop
        return;
      }

      // Move towards target
      final step = _scrollSpeed * (16 / 1000); // Distance to move in 16ms
      final newOffset = currentOffset < clampedTarget
          ? (currentOffset + step).clamp(0.0, clampedTarget)
          : (currentOffset - step).clamp(clampedTarget, currentOffset);

      widget.controller!.jumpTo(newOffset);
    });
  }

  void _stopScrolling() {
    _isHoldingTrack = false;
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumbColor = isDark
        ? AppTheme.accent.withValues(alpha: 0.9)
        : AppTheme.primary.withValues(alpha: 0.9);

    // Pertajam warna track agar terlihat jelas bedanya dengan background halaman
    final trackColor = isDark 
        ? Colors.white.withValues(alpha: 0.15) 
        : Colors.black.withValues(alpha: 0.08);

    return Listener(
      onPointerDown: (event) {
        if (widget.controller == null || !widget.controller!.hasClients) return;

        final renderBox = context.findRenderObject() as RenderBox;
        final localPos = renderBox.globalToLocal(event.position);
        final size = renderBox.size;

        bool inScrollbarArea = false;
        const hitSlop = 24.0;

        if (widget.scrollDirection == Axis.vertical) {
          if (widget.scrollbarOrientation == ScrollbarOrientation.left) {
            inScrollbarArea = localPos.dx <= hitSlop;
          } else {
            inScrollbarArea = localPos.dx >= (size.width - hitSlop);
          }
        } else {
          if (widget.scrollbarOrientation == ScrollbarOrientation.top) {
            inScrollbarArea = localPos.dy <= hitSlop;
          } else {
            inScrollbarArea = localPos.dy >= (size.height - hitSlop);
          }
        }

        if (!inScrollbarArea) return;

        final position = widget.controller!.position;
        final maxScroll = position.maxScrollExtent;
        final viewport = position.viewportDimension;
        final currentScroll = position.pixels;
        final totalContent = maxScroll + viewport;

        if (totalContent > 0) {
          final thumbLength = (viewport / totalContent) * viewport;
          final thumbOffset = (currentScroll / totalContent) * viewport;

          double touchCoord = widget.scrollDirection == Axis.vertical ? localPos.dy : localPos.dx;

          if (touchCoord >= thumbOffset - 5 && touchCoord <= thumbOffset + thumbLength + 5) {
            return;
          }
        }

        _startScrolling(localPos);
      },
      onPointerUp: (_) => _stopScrolling(),
      onPointerCancel: (_) => _stopScrolling(),
      child: RawScrollbar(
        controller: widget.controller,
        thumbVisibility: widget.thumbVisibility,
        trackVisibility: false,
        thickness: 24.0,
        radius: widget.radius,
        interactive: true,
        notificationPredicate: widget.notificationPredicate ?? defaultScrollNotificationPredicate,
        scrollbarOrientation: widget.scrollbarOrientation,
        thumbColor: Colors.transparent,
        child: Stack(
          children: [
            RawScrollbar(
              controller: widget.controller,
              thumbVisibility: widget.thumbVisibility,
              trackVisibility: widget.trackVisibility,
              thickness: 8.0,
              radius: widget.radius,
              interactive: false,
              notificationPredicate: widget.notificationPredicate ?? defaultScrollNotificationPredicate,
              scrollbarOrientation: widget.scrollbarOrientation,
              thumbColor: thumbColor,
              trackColor: trackColor,
              child: widget.child,
            ),
            _buildArrows(context),
          ],
        ),
      ),
    );
  }

  Widget _buildArrows(BuildContext context) {
    if (!widget.thumbVisibility) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;
    
    // barSize disesuaikan dengan thickness interaksi (24.0)
    // agar kita bisa memposisikan panah di dalamnya dengan Align
    const barSize = 24.0; 

    if (widget.scrollDirection == Axis.vertical) {
      return Positioned(
        top: 2,
        bottom: 2,
        left: widget.scrollbarOrientation == ScrollbarOrientation.left ? 0 : null,
        right: widget.scrollbarOrientation == ScrollbarOrientation.right || widget.scrollbarOrientation == null ? 0 : null,
        width: barSize,
        child: IgnorePointer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CenteredArrow(icon: Icons.keyboard_arrow_up_rounded, color: iconColor, orientation: widget.scrollbarOrientation),
              _CenteredArrow(icon: Icons.keyboard_arrow_down_rounded, color: iconColor, orientation: widget.scrollbarOrientation),
            ],
          ),
        ),
      );
    } else {
      // Horizontal
      return Positioned(
        left: 2,
        right: 2,
        top: widget.scrollbarOrientation == ScrollbarOrientation.top ? 0 : null,
        bottom: widget.scrollbarOrientation == ScrollbarOrientation.bottom || widget.scrollbarOrientation == null ? 0 : null,
        height: barSize,
        child: IgnorePointer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CenteredArrow(icon: Icons.keyboard_arrow_left_rounded, color: iconColor, orientation: widget.scrollbarOrientation, isVertical: false),
              _CenteredArrow(icon: Icons.keyboard_arrow_right_rounded, color: iconColor, orientation: widget.scrollbarOrientation, isVertical: false),
            ],
          ),
        ),
      );
    }
  }
}

class _CenteredArrow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final ScrollbarOrientation? orientation;
  final bool isVertical;

  const _CenteredArrow({
    required this.icon,
    required this.color,
    this.orientation,
    this.isVertical = true,
  });

  @override
  Widget build(BuildContext context) {
    // Rumus Matematika:
    // Jalur Visual = 8px. Margin = 2px.
    // Titik tengah jalur = Margin + (Jalur/2) = 2 + 4 = 6px dari pinggir.
    // Dengan SizedBox 12px yang mepet pinggir, Center-nya akan tepat di 6px.
    
    Alignment alignment;
    if (isVertical) {
      alignment = orientation == ScrollbarOrientation.left ? Alignment.centerLeft : Alignment.centerRight;
    } else {
      alignment = orientation == ScrollbarOrientation.top ? Alignment.topCenter : Alignment.bottomCenter;
    }

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: isVertical ? 12 : null,
        height: !isVertical ? 12 : null,
        child: Center(
          child: Icon(icon, size: 9, color: color.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}
