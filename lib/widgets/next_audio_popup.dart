import 'dart:async';
import 'package:flutter/material.dart';

void showNextAudioPopup({
  required BuildContext context,
  required VoidCallback onPlay,
  required VoidCallback onStop,
}) {
  int countdown = 20;
  Timer? timer;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (countdown > 0) {
              setState(() => countdown--);
            } else {
              t.cancel();
              Navigator.pop(context);
              onStop(); // auto sleep
            }
          });

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              "Play Next Audio?",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "Next audio starts in $countdown seconds",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(context);
                  onStop();
                },
                child: const Text("Stop"),
              ),
              ElevatedButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(context);
                  onPlay();
                },
                child: const Text("Play Next"),
              ),
            ],
          );
        },
      );
    },
  ).then((_) => timer?.cancel());
}