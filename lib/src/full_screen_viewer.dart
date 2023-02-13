import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'cursor_trail_widget.dart';

/// A full screen viewer that is shown when an item is tapped.
class FullScreenViewer extends StatefulWidget {
  /// Called when the item changes.
  final ValueChanged<int> onItemChanged;

  /// The index of the current item.
  final int currentIndex;

  /// The total number of items.
  final int? itemCount;

  /// The max allowed size of the item.
  final Size maxSize;

  /// The current fractional position of the item.
  final FractionalOffset currentPosition;

  /// Called when the full screen viewer is hidden.
  final VoidCallback onHide;

  /// Builds the item at the given index.
  final IndexedItemBuilder itemBuilder;

  /// Creates a [FullScreenViewer].
  const FullScreenViewer({
    super.key,
    required this.onItemChanged,
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
  /// The current index of the item.
  late int currentIndex = widget.currentIndex;

  /// The animation controller.
  late AnimationController controller;

  /// Whether to show the controls.
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
                          widget.onItemChanged(currentIndex);
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
                          widget.onItemChanged(currentIndex);
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

/// A widget that shows a [label] text as a cursor.
class TextCursor extends StatefulWidget {
  /// The label to show.
  final String label;

  /// The font size of the label.
  final double fontSize;

  /// The child widget on which the cursor is shown when hovered.
  final Widget child;

  /// The color of the cursor. Defaults to [Colors.white].
  final Color? color;

  /// Creates a [TextCursor].
  const TextCursor({
    super.key,
    required this.label,
    this.fontSize = 20,
    required this.child,
    this.color,
  });

  @override
  State<TextCursor> createState() => _TextCursorState();
}

class _TextCursorState extends State<TextCursor> {
  /// The position of the cursor.
  Offset position = Offset.zero;

  /// Whether the cursor is hovering.
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
                    color: widget.color ?? Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
