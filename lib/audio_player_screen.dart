import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaPlayerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final int currentIndex;

  const MediaPlayerScreen({
    super.key,
    required this.playlist,
    required this.currentIndex,
  });

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();

  bool _loading = true;
  bool _shuffle = false;
  bool _repeat = false;
  bool _completionHandled = false;

  DateTime? _sessionStartTime;
  DateTime? _goodNightPopupOpenedAt;
  double _volume = 1.0;
  late int _index;
  final Set<String> _favoriteKeys = {};

  late AnimationController _rotation;

  Map<String, dynamic> get currentTrack => widget.playlist[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.currentIndex;

    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _sessionStartTime = DateTime.now();
    _initPlayer();

    /// rotate album when playing
    _player.playingStream.listen((playing) {
      if (playing) {
        _rotation.repeat();
      } else {
        _rotation.stop();
      }
    });

    /// detect end of audio
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          !_completionHandled) {
        _completionHandled = true;
        _showPopup();
      }
    });
  }

  Future<void> _initPlayer() async {
    await _loadTrack();
    setState(() => _loading = false);
  }

  Future<void> _loadTrack() async {
    final url = currentTrack['media_file_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Media URL is missing for track at index $_index');
    }
    await _player.setUrl(url);
  }

  // ================= PLAYBACK CONTROLS =================

  void _play() => _player.play();
  void _pause() => _player.pause();

  Future<void> _next() async {
    if (widget.playlist.isEmpty) return;

    if (_shuffle && widget.playlist.length > 1) {
      int nextIndex;
      do {
        nextIndex = _random.nextInt(widget.playlist.length);
      } while (nextIndex == _index && widget.playlist.length > 1);
      _index = nextIndex;
    } else if (_index < widget.playlist.length - 1) {
      _index++;
    } else {
      return;
    }

    await _loadTrack();
    setState(() {});
    _completionHandled = false;
    _player.play();
  }

  Future<void> _previous() async {
    if (widget.playlist.isEmpty) return;

    if (_index > 0) {
      _index--;
      await _loadTrack();
      setState(() {});
      _player.play();
    }
  }

  void _forward10() async {
    final position = await _player.position;
    final duration = _player.duration ?? Duration.zero;
    final target = position + const Duration(seconds: 10);
    _player.seek(target <= duration ? target : duration);
  }

  void _back10() async {
    final position = await _player.position;
    final target = position - const Duration(seconds: 10);
    _player.seek(target >= Duration.zero ? target : Duration.zero);
  }

  void _toggleShuffle() {
    setState(() => _shuffle = !_shuffle);
  }

  void _toggleRepeat() {
    setState(() => _repeat = !_repeat);
    _player.setLoopMode(_repeat ? LoopMode.one : LoopMode.off);
  }

  void _setVolume(double v) {
    setState(() => _volume = v);
    _player.setVolume(v);
  }
  String get _currentTrackKey {
    final id = currentTrack['id'];
    final url = currentTrack['media_file_url'];
    return id?.toString() ?? url?.toString() ?? '';
  }

  bool get _isFavorite =>
      _currentTrackKey.isNotEmpty && _favoriteKeys.contains(_currentTrackKey);

  void _toggleFavorite() {
    final key = _currentTrackKey;
    if (key.isEmpty) return;
    setState(() {
      if (_favoriteKeys.contains(key)) {
        _favoriteKeys.remove(key);
      } else {
        _favoriteKeys.add(key);
      }
    });
  }

  String _formatDuration(Duration duration) {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
  // ================= POPUP =================

  void _showPopup() {
    int count = 20;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (count > 0) {
                setState(() => count--);
              } else {
                t.cancel();
                Navigator.pop(context);
                _sleepMode();
                _showGoodNightPopup();
              }
            });

            return AlertDialog(
              backgroundColor: const Color(222431),
              title: const Text(
                "Play Next Audio?",
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                "Auto stop in $count sec",
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context);
                    _sleepMode();
                    _showGoodNightPopup();
                  },
                  child: const Text("Stop"),
                ),
                ElevatedButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context);
                    _next();
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

  void _sleepMode() {
    _player.stop();
  }

  Future<void> _updateSleepDuration(Duration duration) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final durationHours = duration.inSeconds / 3600.0;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'sleep_duration': durationHours})
          .eq('user_id', userId);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to update sleep_duration: $e');
    }
  }

  Duration get _sessionDuration {
    final start = _sessionStartTime ?? DateTime.now();
    return DateTime.now().difference(start);
  }

  Future<void> _showGoodNightPopup() async {
    if (!mounted) return;

    _goodNightPopupOpenedAt = DateTime.now();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(222431),
          title: const Text(
            "Good Night",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "You spent ${_formatDuration(_sessionDuration)} in the audio player.\n"
            "The app will close now so you can rest.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _sleepMode();
                final openedAt = _goodNightPopupOpenedAt ?? DateTime.now();
                final popupDuration = DateTime.now().difference(openedAt);
                await _updateSleepDuration(popupDuration);
                // h=there: return to home screen instead of closing the app
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ================= UI =================

  @override
  void dispose() {
    _player.dispose();
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(222431),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Now Playing",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Column(
              children: [

                const SizedBox(height: 20),

                // ================= ALBUM ART =================
                Expanded(
                  flex: 3,
                  child: Center(
                    child: RotationTransition(
                      turns: _rotation,
                      child: ClipOval(
                        child: currentTrack['cover_img_url'] != null
                            ? Image.network(
                                currentTrack['cover_img_url'] as String,
                                width: 260,
                                height: 260,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 260,
                                height: 260,
                                color: Colors.grey,
                                child: const Icon(
                                  Icons.music_note,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  currentTrack['title'] ?? 'Unknown Title',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),

                Text(
                  currentTrack['type'] ?? 'Unknown Type',
                  style: const TextStyle(color: Colors.white60),
                ),

                const SizedBox(height: 10),

                // ================= PROGRESS =================
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, posSnap) {
                    return StreamBuilder<Duration?>(
                      stream: _player.durationStream,
                      builder: (context, durSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = durSnap.data ?? Duration.zero;

                        final max = dur.inMilliseconds.toDouble();
                        final safeMax = max == 0 ? 1.0 : max;

                        final value = pos.inMilliseconds
                            .toDouble()
                            .clamp(0.0, safeMax);

                        return Column(
                          children: [
                            Slider(
                              activeColor: Colors.purpleAccent,
                              inactiveColor: Colors.grey,
                              min: 0.0,
                              max: safeMax,
                              value: value,
                              onChanged: (v) {
                                _player.seek(Duration(milliseconds: v.toInt()));
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(pos),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(dur),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                // ================= MAIN CONTROLS =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    IconButton(
                      icon: Icon(Icons.shuffle,
                          color: _shuffle ? const Color.fromARGB(255, 127, 76, 175) : Colors.white),
                      onPressed: _toggleShuffle,
                    ),

                    IconButton(
                      icon: const Icon(Icons.skip_previous,
                          color: Colors.white),
                      onPressed: _previous,
                    ),

                    StreamBuilder<bool>(
                      stream: _player.playingStream,
                      builder: (context, snap) {
                        final playing = snap.data ?? false;
                        return IconButton(
                          iconSize: 60,
                          icon: Icon(
                            playing ? Icons.pause_circle : Icons.play_circle,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              playing ? _pause() : _play(),
                        );
                      },
                    ),

                    IconButton(
                      icon: const Icon(Icons.skip_next,
                          color: Colors.white),
                      onPressed: _next,
                    ),

                    IconButton(
                      icon: Icon(Icons.repeat,
                          color: _repeat ? Colors.purple : Colors.white),
                      onPressed: _toggleRepeat,
                    ),
                  ],
                ),

                // ================= EXTRA CONTROLS =================
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        activeColor: Colors.purpleAccent,
                        onChanged: _setVolume,
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: _back10,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: _forward10,
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
    );
  }
}