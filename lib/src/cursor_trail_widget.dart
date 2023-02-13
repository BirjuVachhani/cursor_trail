import 'dart:math';

import 'package:flutter/material.dart';

import 'full_screen_viewer.dart';

/// Item builder for [CursorTrail].
typedef IndexedItemBuilder = Widget Function(
    BuildContext context, int index, Size maxSize);

/// A widget that shows a trail of widgets as the cursor moves.
class CursorTrail extends StatefulWidget {
  /// The threshold distance in pixels that the cursor must move before
  /// the next widget is shown.
  final double threshold;

  /// Called when the widget changes.
  final ValueChanged<int> onItemChanged;

  /// The duration of the fade animation per item when full screen viewer
  /// is about to be shown.
  final Duration fadeAnimationDuration;

  /// The maximum number of items that can be visible at a time.
  final int maxVisibleCount;

  /// The maximum size of the item. A minimum of half the screen size is
  /// used if available space is less than this.
  final Size maxItemSize;

  /// The item builder.
  final IndexedItemBuilder itemBuilder;

  /// Whether to show full screen viewer on tap. If set to false, [onTap]
  /// will be called instead. Defaults to true. If [onTap] is set, this
  /// must not be set to true.
  final bool showFullScreenViewerOnTap;

  /// Called when the widget is tapped. If [showFullScreenViewerOnTap] is
  /// set to true, this must be null.
  final ValueChanged<int>? onTap;

  /// The total number of items. If set, the items will be looped.
  /// Defaults to null.
  final int? itemCount;

  /// Creates a [CursorTrail].
  const CursorTrail({
    super.key,
    this.itemCount,
    required this.onItemChanged,
    required this.itemBuilder,
    this.threshold = 80,
    this.maxVisibleCount = 5,
    this.maxItemSize = const Size(1000, 700),
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
  /// last item is the current/top-most item in stack.
  List<FractionalOffset> activeItemPositions = [];

  /// The index of the current/top-most item.
  int currentIndex = 0;

  /// The last position of the cursor.
  Offset lastPosition = Offset.zero;

  /// The animation controller for the fade animation.
  late AnimationController controller;

  /// Whether to show full screen viewer.
  bool shouldShowFullScreenViewer = false;

  /// The index of the bottom-most visible item.
  int get startIndex {
    int index = (currentIndex - (activeItemPositions.length - 1));
    if (widget.itemCount != null) {
      index %= widget.itemCount!;
    }
    return index;
  }

  /// The total duration of the fade animation for all the visible items.
  int get totalMillis =>
      widget.fadeAnimationDuration.inMilliseconds * activeItemPositions.length;

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

  /// Converts visible index to item index.
  int getItemIndexFromPositionIndex(int index) {
    int itemIndex = (startIndex + index);

    if (widget.itemCount != null) itemIndex %= widget.itemCount!;

    return itemIndex;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxHeight =
          min(constraints.maxHeight / 2, widget.maxItemSize.height);
      final double maxWidth =
          min(constraints.maxWidth / 2, widget.maxItemSize.width);

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
              for (int index = 0; index < activeItemPositions.length; index++)
                Builder(
                  builder: (context) {
                    final fractionalPos = activeItemPositions[index];
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
                              final itemIndex =
                                  getItemIndexFromPositionIndex(index);
                              final child = SizedBox.fromSize(
                                size: maxSize,
                                child: widget.itemBuilder(
                                    context, itemIndex, maxSize),
                              );

                              // Last item doesn't need to be animated.
                              if (index == activeItemPositions.length - 1) {
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
                  currentPosition: activeItemPositions.last,
                  onItemChanged: (newIndex) {
                    currentIndex = newIndex;
                    setState(() {});
                    widget.onItemChanged(currentIndex);
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

  /// Called when the user moves the cursor.
  void onPointerMove(Offset localPosition, Size size) {
    // Return if there are no items or animation is in progress or full screen
    // viewer is visible.
    if (widget.itemCount == 0 ||
        controller.isAnimating ||
        controller.status == AnimationStatus.completed) return;

    assert(size != Size.zero && size.isFinite);
    if (activeItemPositions.isEmpty) {
      activeItemPositions
          .add(FractionalOffset.fromOffsetAndSize(localPosition, size));
      lastPosition = localPosition;
      setState(() {});
      widget.onItemChanged(currentIndex);
      return;
    }

    // add a new item if the threshold is reached
    final double distance = (localPosition - lastPosition).distance.abs();
    if (distance > max(widget.threshold, 1)) {
      // Increment current index
      currentIndex = ++currentIndex;
      if (widget.itemCount != null) currentIndex %= widget.itemCount!;

      final item = FractionalOffset.fromOffsetAndSize(localPosition, size);
      // log('added ${item.key}');
      activeItemPositions.add(item);
      lastPosition = localPosition;

      // remove tail photo if there are more than 5 photos
      if (activeItemPositions.length > widget.maxVisibleCount) {
        final int itemsToRemove =
            activeItemPositions.length - widget.maxVisibleCount;
        activeItemPositions.removeRange(0, itemsToRemove);
        // log('removed ${item.key}');
      }

      setState(() {});
      widget.onItemChanged(currentIndex);
    }
  }

  /// Shows the full screen viewer.
  Future<void> showFullScreenViewer() async {
    shouldShowFullScreenViewer = true;
    setState(() {});
  }

  /// Hides the full screen viewer.
  void hideFullScreenViewer() {
    shouldShowFullScreenViewer = false;
    setState(() {});

    // Reveal other items with animation.
    controller.reverse();
  }

  /// Called when the user taps on an item..
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
      // Hide other items and begin to show the full screen viewer.
      controller.reverse();
    } else {
      // Show other items as full screen viewer is closed now.
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
