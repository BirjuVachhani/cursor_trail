# cursor_trail

A widget that shows a trail of widgets/images as you move your cursor. Inspired by [bridget.pictures](https://bridget.pictures) website.

[![Codemagic build status](https://api.codemagic.io/apps/63e92d6ef515a4ee099149a3/63e92d6ef515a4ee099149a2/status_badge.svg)](https://codemagic.io/apps/63e92d6ef515a4ee099149a3/63e92d6ef515a4ee099149a2/latest_build)
[![Pub Version](https://img.shields.io/pub/v/cursor_trail?label=Pub)](https://pub.dev/packages/cursor_trail)

Demo: [Cursor Trail](https://cursortrail.codemagic.app)

<img src="https://user-images.githubusercontent.com/20423471/218333478-80a28b55-c7f3-40f1-b9ed-2a492b5d5408.gif" width="100%"/>

## Features

- Show any widget as a trail. Works best for images.
- `ListView.builder` like easy to use API.
- Customizable threshold for cursor movement.
- Control how many items should be visible in the trail.
- Shows widgets/images in full screen mode.
- Custom text cursor in full screen mode.
- Animates nicely when full screen is toggled.

## Getting Started

Add following dependency to your `pubspec.yaml`.

```yaml
dependencies:
  cursor_trail: <latest_version>
```

Use `CursorTrail` widget to add a cursor trail to your app.

```dart
CursorTrail(
  itemCount: images.length,
  itemBuilder: (context, index, maxSize) {
    // build your widget/image here.
    return CachedNetworkImage(
      imageUrl: images[index],
      fit: BoxFit.contain,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
    );
  },
  onImageChanged: (index) {
    // do something when image changes.
  },
);
```

See example app for more details.

See [api docs](https://pub.dev/documentation/cursor_trail/latest/) for available options.

## Contribution

You are most welcome to contribute to this project!

Please have a look
at [Contributing Guidelines](https://github.com/BirjuVachhani/cursor_trail/blob/main/CONTRIBUTING.md), before
contributing and proposing a change.

## Liked what you show?

Show some love and support by starring the repository.

Or you can

<a href="https://www.buymeacoffee.com/birjuvachhani" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-blue.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>

## License

```
BSD 3-Clause License

Copyright (c) 2023, Birju Vachhani

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
