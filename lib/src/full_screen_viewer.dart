import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'cursor_trail_widget.dart';

class FullScreenViewer extends StatefulWidget {
  final ValueChanged<int> onImageChanged;
  final int currentIndex;
  final int? itemCount;
  final Size maxSize;
  final FractionalOffset currentPosition;
  final VoidCallback onHide;
  final IndexedItemBuilder itemBuilder;

  const FullScreenViewer({
    super.key,
    required this.onImageChanged,
    required this.currentIndex,
    required this.itemCount,
    required this.maxSize,
    required this.currentPosition,
    required this.onHide,
    required this.itemBuilder,
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
            child:
                widget.itemBuilder(context, currentIndex, constraints.biggest),
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
                          currentIndex =
                              --currentIndex % (widget.itemCount ?? 1);
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
                          currentIndex = ++currentIndex;
                          if (widget.itemCount != null) {
                            currentIndex %= widget.itemCount!;
                          }
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
