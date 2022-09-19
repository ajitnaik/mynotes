import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mynotes/helpers/loading/loading_screen_controller.dart';

class LoadingScreen {
  LoadingScreen._();

  static final instance = LoadingScreen._();

  LoadingScreenController? controller;

  void hide() {
    controller?.closeLoadingScreen();
    controller = null;
  }

  void show({
    required BuildContext context,
    required String text,
  }) {
    if (controller?.updateLoadingScreen(text) ?? false) {
      return;
    } else {
      controller = showOverlay(
        context: context,
        text: text,
      );
    }
  }

  LoadingScreenController showOverlay({
    required BuildContext context,
    required String text,
  }) {
    final _text = StreamController<String>();

    _text.add(text);

    final state = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final overlayEntry = OverlayEntry(builder: ((context) {
      return Material(
        color: Colors.black.withAlpha(150),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: size.width * 0.8,
              maxHeight: size.height * 0.8,
              minWidth: size.width * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    const CircularProgressIndicator(),
                    const SizedBox(
                      height: 20,
                    ),
                    StreamBuilder(
                        stream: _text.stream,
                        builder: ((context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data as String,
                              textAlign: TextAlign.center,
                            );
                          } else {
                            return Container();
                          }
                        }))
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }));

    state?.insert(overlayEntry);

    return LoadingScreenController(
      closeLoadingScreen: (() {
        _text.close();
        overlayEntry.remove();
        return true;
      }),
      updateLoadingScreen: ((text) {
        _text.add(text);
        return true;
      }),
    );
  }
}
