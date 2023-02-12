import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pictures_stack/utils/universal/universal.dart';

import 'pictures_stack.dart';

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
                itemBuilder: (context, index, maxSize) => CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  // width: maxSize.width,
                  // height: maxSize.height,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                ),
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
