import 'dart:math';

import 'package:flutter/material.dart';

import 'full_screen_viewer.dart';

typedef IndexedItemBuilder = Widget Function(
    BuildContext context, int index, Size maxSize);

class CursorTrail extends StatefulWidget {
  final double threshold;
  final ValueChanged<int> onImageChanged;
  final Duration fadeAnimationDuration;
  final int maxVisibleCount;
  final Size maxImageSize;
  final IndexedItemBuilder itemBuilder;
  final bool showFullScreenViewerOnTap;
  final ValueChanged<int>? onTap;
  final int? itemCount;

  const CursorTrail({
    super.key,
    this.itemCount,
    required this.onImageChanged,
    required this.itemBuilder,
    this.threshold = 40,
    this.maxVisibleCount = 5,
    this.maxImageSize = const Size(1000, 700),
    this.fadeAnimationDuration = const Duration(milliseconds: 120),
    this.showFullScreenViewerOnTap = true,
    this.onTap,
  }) : assert(onTap == null || !showFullScreenViewerOnTap, '''
      onTap and showFullScreenViewerOnTap cannot be used together.
      Use onTap to handle tap events and showFullScreenViewerOnTap to show
      full screen viewer on tap.
    ''');

  @override
  State<CursorTrail> createState() => _CursorTrailState();
}

class _CursorTrailState extends State<CursorTrail>
    with SingleTickerProviderStateMixin {
  // last item is the current/top-most item in stack.
  List<FractionalOffset> activeImagePositions = [];

  int currentIndex = 0;

  Offset lastPosition = Offset.zero;

  late AnimationController controller;

  bool shouldShowFullScreenViewer = false;

  int get startIndex {
    int index = (currentIndex - (activeImagePositions.length - 1));
    if (widget.itemCount != null) {
      index %= widget.itemCount!;
    }
    return index;
  }

  int get totalMillis =>
      widget.fadeAnimationDuration.inMilliseconds * activeImagePositions.length;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      value: 0,
      animationBehavior: AnimationBehavior.preserve,
    );
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        showFullScreenViewer();
      }
    });
  }

  int getImageIndexFromPositionIndex(int index) {
    int imageIndex = (startIndex + index);
    if (widget.itemCount != null) {
      imageIndex %= widget.itemCount!;
    }
    return imageIndex;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxHeight =
          min(constraints.maxHeight / 2, widget.maxImageSize.height);
      final double maxWidth =
          min(constraints.maxWidth / 2, widget.maxImageSize.width);

      final Size maxSize = Size(maxWidth, maxHeight);

      return Listener(
        onPointerHover: (details) =>
            onPointerMove(details.localPosition, constraints.biggest),
        onPointerMove: (details) =>
            onPointerMove(details.localPosition, constraints.biggest),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!shouldShowFullScreenViewer)
              for (int index = 0; index < activeImagePositions.length; index++)
                Builder(
                  builder: (context) {
                    final fractionalPos = activeImagePositions[index];
                    final position =
                        fractionalPos.alongSize(constraints.biggest);
                    final millis = widget.fadeAnimationDuration.inMilliseconds;

                    return Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        transformHitTests: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(index),
                          child: Builder(
                            builder: (context) {
                              final imageIndex =
                                  getImageIndexFromPositionIndex(index);
                              final child = SizedBox.fromSize(
                                size: maxSize,
                                child: widget.itemBuilder(
                                    context, imageIndex, maxSize),
                              );

                              // Last image doesn't need to be animated.
                              if (index == activeImagePositions.length - 1) {
                                return child;
                              }

                              final begin = (index * millis) / totalMillis;
                              final end = ((index + 1) * millis) / totalMillis;

                              return AnimatedBuilder(
                                animation: CurvedAnimation(
                                  parent: controller,
                                  curve: Curves.easeOutSine,
                                  reverseCurve: Curves.easeOutSine,
                                ),
                                builder: (context, child) {
                                  final intervalValue = Interval(begin, end)
                                      .transform(controller.value);
                                  return FractionalTranslation(
                                    translation:
                                        Offset(0, intervalValue * 0.05),
                                    child: Opacity(
                                      opacity: 1 - intervalValue,
                                      child: child!,
                                    ),
                                  );
                                },
                                child: child,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
            if (shouldShowFullScreenViewer && widget.showFullScreenViewerOnTap)
              Positioned.fill(
                child: FullScreenViewer(
                  currentPosition: activeImagePositions.last,
                  onImageChanged: (newIndex) {
                    currentIndex = newIndex;
                    setState(() {});
                    widget.onImageChanged(currentIndex);
                  },
                  currentIndex: currentIndex,
                  maxSize: maxSize,
                  onHide: hideFullScreenViewer,
                  itemCount: widget.itemCount,
                  itemBuilder: widget.itemBuilder,
                ),
              ),
          ],
        ),
      );
    });
  }

  void onPointerMove(Offset localPosition, Size size) {
    // Return if there are no images or animation is in progress or full screen
    // viewer is visible.
    if (widget.itemCount == 0 ||
        controller.isAnimating ||
        controller.status == AnimationStatus.completed) return;

    assert(size != Size.zero && size.isFinite);
    if (activeImagePositions.isEmpty) {
      activeImagePositions
          .add(FractionalOffset.fromOffsetAndSize(localPosition, size));
      lastPosition = localPosition;
      setState(() {});
      widget.onImageChanged(currentIndex);
      return;
    }

    // add a new image if the threshold is reached
    final double distance = (localPosition - lastPosition).distance.abs();
    if (distance > max(widget.threshold, 1)) {
      // Increment current index
      currentIndex = ++currentIndex;
      if (widget.itemCount != null) currentIndex %= widget.itemCount!;

      final item = FractionalOffset.fromOffsetAndSize(localPosition, size);
      // log('added ${item.key}');
      activeImagePositions.add(item);
      lastPosition = localPosition;

      // remove tail photo if there are more than 5 photos
      if (activeImagePositions.length > widget.maxVisibleCount) {
        final int itemsToRemove =
            activeImagePositions.length - widget.maxVisibleCount;
        activeImagePositions.removeRange(0, itemsToRemove);
        // log('removed ${item.key}');
      }

      setState(() {});
      widget.onImageChanged(currentIndex);
    }
  }

  Future<void> showFullScreenViewer() async {
    shouldShowFullScreenViewer = true;
    setState(() {});
  }

  void hideFullScreenViewer() {
    shouldShowFullScreenViewer = false;
    setState(() {});

    // Reveal other images with animation.
    controller.reverse();
  }

  void onTap(int index) {
    if (!widget.showFullScreenViewerOnTap) {
      // Let the user handle the tap event.
      widget.onTap?.call(index);
      return;
    }
    if (controller.isAnimating) return;

    // Update duration for currently visible item count.
    controller.duration = Duration(milliseconds: totalMillis);

    if (controller.status == AnimationStatus.completed) {
      // Hide other images and begin to show the full screen viewer.
      controller.reverse();
    } else {
      // Show other images as full screen viewer is closed now.
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
