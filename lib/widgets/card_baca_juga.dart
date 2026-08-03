import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BacaJugaItem {
  final String title;
  final String? excerpt;
  final String? imageUrl;
  final String? url;
  final String? articleId;

  BacaJugaItem({
    required this.title,
    this.excerpt,
    this.imageUrl,
    this.url,
    this.articleId,
  });
}

class StackedBacaJugaWidget extends StatefulWidget {
  final List<BacaJugaItem> items;
  final Function(BacaJugaItem item)? onItemTap;
  final int initialIndex;

  const StackedBacaJugaWidget({
    super.key,
    required this.items,
    this.onItemTap,
    this.initialIndex = 0,
  });

  @override
  State<StackedBacaJugaWidget> createState() => _StackedBacaJugaWidgetState();
}

class _StackedBacaJugaWidgetState extends State<StackedBacaJugaWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  double _dragOffset = 0.0;
  bool _isSwipingAway = false;
  double _swipeStartX = 0.0;
  double _swipeTargetX = 0.0;

  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );

    _animController.addListener(() {
      setState(() {});
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isSwipingAway) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.items.length;
            PageStorage.of(context).writeState(
              context,
              _currentIndex,
              identifier: 'bacajuga_index_${widget.items.hashCode}',
            );
            _dragOffset = 0.0;
            _isSwipingAway = false;
          });
          _animController.reset();
        } else {
          setState(() {
            _dragOffset = 0.0;
          });
          _animController.reset();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final savedIndex = PageStorage.of(context).readState(
      context,
      identifier: 'bacajuga_index_${widget.items.hashCode}',
    );
    if (savedIndex is int) {
      _currentIndex = savedIndex;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_animController.isAnimating) {
      _animController.stop();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_animController.isAnimating) return;
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_animController.isAnimating) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    // Guard against accidental swipes caused by frame drops or micro-touches:
    // Requires at least 45px of physical movement before velocity or distance can trigger a card swap.
    final minDragDistance = 45.0;
    final swipeDistance = 110.0;
    final minVelocity = 450.0;

    _swipeStartX = _dragOffset;

    bool shouldSwipeLeft = false;
    bool shouldSwipeRight = false;

    if (_dragOffset < -minDragDistance) {
      if (_dragOffset <= -swipeDistance || (velocity < -minVelocity)) {
        shouldSwipeLeft = true;
      }
    } else if (_dragOffset > minDragDistance) {
      if (_dragOffset >= swipeDistance || (velocity > minVelocity)) {
        shouldSwipeRight = true;
      }
    }

    if (shouldSwipeLeft) {
      // Swipe left away (GSAP Power3.out curve)
      _swipeTargetX = -500.0;
      _isSwipingAway = true;
      _animation = CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      );
      _animController.forward(from: 0.0);
    } else if (shouldSwipeRight) {
      // Swipe right away (GSAP Power3.out curve)
      _swipeTargetX = 500.0;
      _isSwipingAway = true;
      _animation = CurvedAnimation(
        parent: _animController,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      );
      _animController.forward(from: 0.0);
    } else {
      // Snap back smoothly with spring physics (GSAP back.out curve)
      _swipeTargetX = 0.0;
      _isSwipingAway = false;
      _animation = CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      );
      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.items.length;

    final topItem = widget.items[_currentIndex % total];
    final secondItem = total > 1 ? widget.items[(_currentIndex + 1) % total] : null;
    final thirdItem = total > 2 ? widget.items[(_currentIndex + 2) % total] : null;

    // Calculate position X of top card and stack progress [0.0 .. 1.0]
    double topCardX;
    double progress;

    if (_animController.isAnimating) {
      final animValue = _animation.value;
      topCardX = lerpDouble(_swipeStartX, _swipeTargetX, animValue)!;
      if (_isSwipingAway) {
        final startProgress = (_swipeStartX.abs() / 180.0).clamp(0.0, 1.0);
        progress = lerpDouble(startProgress, 1.0, animValue)!;
      } else {
        final startProgress = (_swipeStartX.abs() / 180.0).clamp(0.0, 1.0);
        progress = lerpDouble(startProgress, 0.0, animValue)!;
      }
    } else {
      topCardX = _dragOffset;
      progress = (_dragOffset.abs() / 180.0).clamp(0.0, 1.0);
    }

    return Container(
      margin: const EdgeInsets.only(top: 14.0, bottom: 32.0, left: 4.0, right: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Label with Card Counter
          Padding(
            padding: const EdgeInsets.only(left: 6.0, bottom: 8.0, right: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5FF11),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Baca juga:",
                      style: TextStyle(
                        fontFamily: 'Domine',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? const Color(0xFFE5FF11) : Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (total > 1)
                  Text(
                    "${(_currentIndex % total) + 1}/$total",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),

          // Stacked 3D Cards Container
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // --- Layer 3 (Back Card) ---
                if (thirdItem != null)
                  _buildMorphingCardLayer(
                    context: context,
                    item: thirdItem,
                    bgColor: const Color(0xFF0C0F00),
                    fromOffset: const Offset(-5, 10),
                    toOffset: const Offset(5, 5),
                    fromRotation: 0.04,
                    toRotation: -0.03,
                    fromOpacity: 0.25,
                    toOpacity: 0.50,
                    fromScale: 0.92,
                    toScale: 0.96,
                    progress: progress,
                  ),

                // --- Layer 2 (Middle Card) ---
                if (secondItem != null)
                  _buildMorphingCardLayer(
                    context: context,
                    item: secondItem,
                    bgColor: const Color(0xFF131800),
                    fromOffset: const Offset(5, 5),
                    toOffset: const Offset(0, 0),
                    fromRotation: -0.03,
                    toRotation: 0.0,
                    fromOpacity: 0.50,
                    toOpacity: 1.0,
                    fromScale: 0.96,
                    toScale: 1.0,
                    progress: progress,
                  ),

                // --- Layer 1 (Top Interactive Card) ---
                GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onTap: () {
                    if (_dragOffset.abs() < 10 && widget.onItemTap != null) {
                      widget.onItemTap!(topItem);
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(topCardX, topCardX.abs() * 0.03),
                    child: Transform.rotate(
                      angle: topCardX * 0.0006,
                      child: Opacity(
                        opacity: (1.0 - (progress * 0.35)).clamp(0.0, 1.0),
                        child: _buildCardContent(
                          context,
                          topItem,
                          bgColor: const Color(0xFF1A1F00),
                          isInteractive: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMorphingCardLayer({
    required BuildContext context,
    required BacaJugaItem item,
    required Color bgColor,
    required Offset fromOffset,
    required Offset toOffset,
    required double fromRotation,
    required double toRotation,
    required double fromOpacity,
    required double toOpacity,
    required double fromScale,
    required double toScale,
    required double progress,
  }) {
    final offset = Offset.lerp(fromOffset, toOffset, progress)!;
    final rotation = lerpDouble(fromRotation, toRotation, progress)!;
    final opacity = lerpDouble(fromOpacity, toOpacity, progress)!.clamp(0.0, 1.0);
    final scale = lerpDouble(fromScale, toScale, progress)!;

    return Positioned.fill(
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: _buildCardContent(
                context,
                item,
                bgColor: bgColor,
                isInteractive: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    BacaJugaItem item, {
    required Color bgColor,
    required bool isInteractive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50.0), // Capsule / Pill shape
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Image Avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 100,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFFE5FF11),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, err) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.newspaper_rounded,
                          color: Color(0xFFE5FF11),
                          size: 18,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.newspaper_rounded,
                        color: Color(0xFFE5FF11),
                        size: 18,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Excerpt
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Domine',
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                    height: 1.25,
                    color: Color(0xFFE5FF11), // Lime Yellow
                  ),
                ),
                if (item.excerpt != null && item.excerpt!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.excerpt!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.2,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Forward Arrow Icon
          const Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFFE5FF11),
            size: 18,
          ),
        ],
      ),
    );
  }
}

