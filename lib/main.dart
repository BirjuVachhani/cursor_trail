import 'dart:developer';
import 'dart:math' hide log;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pictures_stack/utils/universal/universal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> images = [];

  bool isLoading = true;

  double threshold = 80;

  int currentIndex = -1;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    try {
      isLoading = true;
      int index = 0;
      while (index < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        getRedirectionUrl('https://source.unsplash.com/random?sig=$index')
            .then((image) {
          if (image != null) {
            // final uri = Uri.parse(image);
            // if (images.any((element) => element.contains(uri.path))) {
            //   continue;
            // }
            images.add(image);
            precacheImage(CachedNetworkImageProvider(image), context);
            // log('Image $index: $image}');
          }
        });
        index++;
      }
      setState(() => isLoading = false);
    } catch (error, stacktrace) {
      setState(() => isLoading = false);
      log(error.toString());
      log(stacktrace.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading)
            const Expanded(
              child: Center(
                child: CupertinoActivityIndicator(
                  radius: 20,
                ),
              ),
            ),
          if (!isLoading)
            Expanded(
              child: PicturesStack(
                images: images,
                threshold: threshold,
                fadeAnimationDuration: const Duration(milliseconds: 120),
                onImageChanged: (index) {
                  currentIndex = index;
                  setState(() {});
                },
              ),
            ),
          BottomBar(
            threshold: threshold,
            currentIndex: currentIndex,
            totalImages: images.length,
            onThresholdChanged: (value) {
              setState(() => threshold = value);
            },
          ),
        ],
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  final double threshold;
  final ValueChanged<double> onThresholdChanged;
  final int currentIndex;
  final int totalImages;

  const BottomBar({
    super.key,
    required this.threshold,
    required this.onThresholdChanged,
    required this.currentIndex,
    required this.totalImages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: LayoutBuilder(builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Birju Vachhani'),
              if (constraints.maxWidth >= 370) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (threshold == 0) return;
                        onThresholdChanged(threshold - 40);
                      },
                      splashRadius: 8,
                      constraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      padding: const EdgeInsets.all(4),
                      iconSize: 20,
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'threshold: ${threshold.toInt().toString().padLeft(4, '0')}',
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        onThresholdChanged((threshold + 40).clamp(0, 200));
                      },
                      splashRadius: 10,
                      constraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      padding: const EdgeInsets.all(4),
                      iconSize: 20,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                Text(
                  '${(currentIndex + 1).toString().padLeft(4, '0')} / ${totalImages.toString().padLeft(4, '0')}',
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class PicturesStack extends StatefulWidget {
  final List<String> images;
  final double threshold;
  final ValueChanged<int> onImageChanged;
  final Duration fadeAnimationDuration;

  const PicturesStack({
    super.key,
    required this.images,
    required this.threshold,
    required this.onImageChanged,
    this.fadeAnimationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<PicturesStack> createState() => _PicturesStackState();
}

enum AnimationState {
  idle,
  forward,
  reverse;

  bool get isIdle => this == AnimationState.idle;

  bool get isForward => this == AnimationState.forward;

  bool get isReverse => this == AnimationState.reverse;
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
    // controller.addListener(() {
    //   setState(() {});
    // });
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
      final double maxHeight = min(constraints.maxHeight / 2, 700);
      final double maxWidth = min(constraints.maxWidth / 2, 1000);

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
                          child: Builder(builder: (context) {
                            final child = CachedNetworkImage(
                              imageUrl: entry.key,
                              width: maxWidth,
                              height: maxHeight,
                              fit: BoxFit.contain,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                            );

                            if (i == activeImages.length - 1) {
                              return Hero(tag: 'IMAGE', child: child);
                            }

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
                          }),
                        ),
                      ),
                    );
                  },
                ),
            if (shouldShowFullScreenViewer)
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

class FullScreenViewer extends StatefulWidget {
  final ValueChanged<int> onImageChanged;
  final int currentIndex;
  final List<String> images;
  final Size maxSize;
  final MapEntry<String, FractionalOffset> current;
  final FractionalOffset currentPosition;
  final VoidCallback onHide;

  const FullScreenViewer({
    super.key,
    required this.onImageChanged,
    required this.currentIndex,
    required this.images,
    required this.maxSize,
    required this.current,
    required this.currentPosition,
    required this.onHide,
  });

  @override
  State<FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer>
    with SingleTickerProviderStateMixin {
  late int currentIndex = widget.currentIndex;

  late AnimationController controller;

  bool showControls = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    controller.addListener(() => setState(() {}));

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      animateIn();
    });
  }

  @override
  void didUpdateWidget(FullScreenViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      currentIndex = widget.currentIndex;
    }
  }

  /// Animate in when full screen viewer is shown.
  /// Translate to center and then Scale to fit the viewport.
  Future<void> animateIn() async {
    await controller.forward();
    setState(() => showControls = true);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.images[currentIndex];
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            ),
            builder: (context, child) {
              final scaleFactor = const Interval(
                0.7,
                1,
                curve: Curves.easeOutSine,
              ).transform(controller.value);
              final scale = lerpDouble(
                  widget.maxSize.width / constraints.maxWidth, 1, scaleFactor);

              final positionFactor = const Interval(
                0,
                0.4,
                curve: Curves.easeOutSine,
              ).transform(controller.value);
              final Offset pos =
                  widget.currentPosition.alongSize(constraints.biggest);

              final Offset? position = Offset.lerp(
                pos,
                constraints.biggest.center(Offset.zero),
                positionFactor,
              );

              return Positioned(
                left: position?.dx,
                top: position?.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: SizedBox(
                    width: constraints.maxWidth * scale!,
                    height: constraints.maxHeight * scale,
                    child: child,
                    // alignment: Alignment.topLeft,
                  ),
                ),
              );
            },
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              // width: constraints.maxWidth,
              // height: constraints.maxHeight,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
            ),
          ),
          if (showControls)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: TextCursor(
                      label: 'PREV',
                      child: GestureDetector(
                        onTap: () {
                          currentIndex = --currentIndex % widget.images.length;
                          setState(() {});
                          widget.onImageChanged(currentIndex);
                        },
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextCursor(
                      label: 'CLOSE',
                      child: GestureDetector(
                        onTap: animateOut,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextCursor(
                      label: 'NEXT',
                      child: GestureDetector(
                        onTap: () {
                          currentIndex = ++currentIndex % widget.images.length;
                          setState(() {});
                          widget.onImageChanged(currentIndex);
                        },
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  /// Animate out and close full screen viewer.
  /// Scale down and translate back to original position.
  Future<void> animateOut() async {
    showControls = false;
    await controller.reverse();

    // pause for a bit after animation is done.
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onHide();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class TextCursor extends StatefulWidget {
  final String label;
  final double fontSize;
  final Widget child;

  const TextCursor({
    super.key,
    required this.label,
    this.fontSize = 20,
    required this.child,
  });

  @override
  State<TextCursor> createState() => _TextCursorState();
}

class _TextCursorState extends State<TextCursor> {
  Offset position = Offset.zero;

  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        MouseRegion(
          onEnter: (event) {
            position = event.localPosition;
            hovering = true;
            setState(() {});
          },
          onExit: (_) {
            hovering = false;
            position = Offset.zero;
            setState(() {});
          },
          onHover: (event) {
            position = event.localPosition;
            setState(() {});
          },
          cursor: SystemMouseCursors.none,
          child: widget.child,
        ),
        if (hovering)
          Positioned(
            left: position.dx,
            top: position.dy,
            child: IgnorePointer(
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
