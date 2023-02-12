import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'full_screen_viewer.dart';

typedef IndexedItemBuilder = Widget Function(
    BuildContext context, int index, Size maxSize);

class PicturesStack extends StatefulWidget {
  final List<String> images;
  final double threshold;
  final ValueChanged<int> onImageChanged;
  final Duration fadeAnimationDuration;
  final double maxVisibleCount;
  final Size maxImageSize;
  final IndexedItemBuilder itemBuilder;
  final bool showFullScreenViewerOnTap;
  final ValueChanged<int>? onTap;

  const PicturesStack({
    super.key,
    required this.images,
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
  State<PicturesStack> createState() => _PicturesStackState();
}

class _PicturesStackState extends State<PicturesStack>
    with SingleTickerProviderStateMixin {
  late List<String> images = [...widget.images];

  List<MapEntry<String, FractionalOffset>> activeImages = [];

  int currentIndex = 0;

  Offset lastPosition = Offset.zero;

  late AnimationController controller;

  late Size maxSize;

  bool shouldShowFullScreenViewer = false;

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
        showFullScreenViewer(
            activeImages.length - 1, activeImages.last, maxSize);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PicturesStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images != oldWidget.images) {
      images = widget.images;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxHeight =
          min(constraints.maxHeight / 2, widget.maxImageSize.height);
      final double maxWidth =
          min(constraints.maxWidth / 2, widget.maxImageSize.width);

      maxSize = Size(maxWidth, maxHeight);

      return Listener(
        onPointerHover: (details) =>
            onPointerMove(details, constraints.biggest),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!shouldShowFullScreenViewer)
              for (int i = 0; i < activeImages.length; i++)
                Builder(
                  builder: (context) {
                    final entry = activeImages[i];
                    final offset = entry.value.alongSize(constraints.biggest);
                    final millis = widget.fadeAnimationDuration.inMilliseconds;
                    final totalMillis = millis * activeImages.length;

                    return Positioned(
                      left: offset.dx,
                      top: offset.dy,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        transformHitTests: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!widget.showFullScreenViewerOnTap) {
                              widget.onTap?.call(i);
                              return;
                            }
                            if (controller.isAnimating) return;

                            controller.duration =
                                Duration(milliseconds: totalMillis);
                            if (controller.status ==
                                AnimationStatus.completed) {
                              controller.reverse();
                            } else {
                              controller.forward();
                            }
                          },
                          child: Builder(
                            builder: (context) {
                              final index = widget.images.indexOf(entry.key);
                              final child = SizedBox.fromSize(
                                size: maxSize,
                                child: widget.itemBuilder(context, index, maxSize),
                              );

                              // Last image doesn't need to be animated.
                              if (i == activeImages.length - 1) return child;

                              final begin = (i * millis) / totalMillis;
                              final end = ((i + 1) * millis) / totalMillis;
                              return AnimatedBuilder(
                                animation: CurvedAnimation(
                                  parent: controller,
                                  curve: Curves.easeOutSine,
                                  reverseCurve: Curves.easeOutSine,
                                ),
                                builder: (context, child) {
                                  return FractionalTranslation(
                                    translation: Offset(
                                      0,
                                      Interval(begin, end)
                                              .transform(controller.value) *
                                          0.05,
                                    ),
                                    child: Opacity(
                                      opacity: 1 -
                                          Interval(begin, end)
                                              .transform(controller.value),
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
                  currentPosition: activeImages.last.value,
                  current: activeImages.last,
                  onImageChanged: updateImages,
                  currentIndex: currentIndex,
                  images: widget.images,
                  maxSize: maxSize,
                  onHide: hideFullScreenViewer,
                ),
              ),
          ],
        ),
      );
    });
  }

  void onPointerMove(PointerHoverEvent event, Size size) {
    if (controller.isAnimating ||
        controller.status == AnimationStatus.completed) return;

    assert(size != Size.zero && size.isFinite);
    if (activeImages.isEmpty) {
      activeImages.add(MapEntry(images[currentIndex],
          FractionalOffset.fromOffsetAndSize(event.localPosition, size)));
      lastPosition = event.localPosition;
      setState(() {});
      widget.onImageChanged(currentIndex);
      return;
    }

    // add a new image if the threshold is reached
    final double distance = (event.localPosition - lastPosition).distance.abs();
    if (distance > max(widget.threshold, 1)) {
      currentIndex = ++currentIndex % images.length;
      final item = MapEntry(images[currentIndex],
          FractionalOffset.fromOffsetAndSize(event.localPosition, size));
      // log('added ${item.key}');
      activeImages.add(item);
      lastPosition = event.localPosition;

      // remove tail photo if there are more than 5 photos
      if (activeImages.length > 5) {
        activeImages.removeAt(0);
        // log('removed ${item.key}');
      }

      setState(() {});
      widget.onImageChanged(currentIndex);
    }
  }

  /// A new image is selected from the full screen viewer. Update
  /// currently showing images to match new index.
  void updateImages(int newIndex) {
    final lastIndex = activeImages.length - 1;
    int startIndex = newIndex - lastIndex >= 0
        ? newIndex - lastIndex
        : images.length - (lastIndex - newIndex);

    activeImages = activeImages.map((e) {
      final key = images[startIndex];
      final value = e.value;
      startIndex = ++startIndex % images.length;
      return MapEntry(key, value);
    }).toList();

    currentIndex = newIndex;

    setState(() {});
    widget.onImageChanged(currentIndex);
  }

  Future<void> showFullScreenViewer(
      int i, MapEntry<String, FractionalOffset> entry, Size maxSize) async {
    shouldShowFullScreenViewer = true;
    setState(() {});
  }

  void hideFullScreenViewer() {
    shouldShowFullScreenViewer = false;
    setState(() {});
    controller.reverse();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
