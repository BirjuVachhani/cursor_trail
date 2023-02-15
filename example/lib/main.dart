import 'dart:developer';
import 'dart:ui';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cursor_trail/cursor_trail.dart';
import 'package:example/utils/universal/universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
        light: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: Colors.blue,
        ),
        dark: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
        ),
        initial: AdaptiveThemeMode.dark,
        builder: (light, dark) {
          return MaterialApp(
            title: 'Flutter Demo',
            debugShowCheckedModeBanner: false,
            theme: light,
            darkTheme: dark,
            home: const MyHomePage(),
          );
        });
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: CursorTrail(
                      threshold: threshold,
                      itemCount: images.length,
                      // maxVisibleCount: 10,
                      itemBuilder: (context, index, maxSize) {
                        return CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.contain,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                        );
                      },
                      onItemChanged: (index) {
                        currentIndex = index;
                        setState(() {});
                      },
                    ),
                  ),
                  const Positioned(right: 12, top: 12, child: TopBar()),
                ],
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

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final adaptiveTheme = AdaptiveTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ButtonBar(
            children: [
              IconButton(
                onPressed: () {
                  launchUrlString(
                      'https://github.com/birjuvachhani/cursor_trail');
                },
                icon: const Icon(FontAwesomeIcons.github),
              ),
              IconButton(
                onPressed: () {
                  adaptiveTheme.toggleThemeMode();
                },
                icon: Builder(
                  builder: (context) {
                    switch (adaptiveTheme.mode) {
                      case AdaptiveThemeMode.light:
                        return const Icon(Icons.wb_sunny);
                      case AdaptiveThemeMode.dark:
                        return const Icon(Icons.nightlight_round);
                      case AdaptiveThemeMode.system:
                        return const Icon(Icons.brightness_auto);
                    }
                  },
                ),
              ),
            ],
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
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: LayoutBuilder(builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cursor Trail'),
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
