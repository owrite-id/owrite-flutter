import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/open_voice_service.dart';

/// Widget Player Audio Open Voice Neural TTS yang interaktif
class OpenVoicePlayerWidget extends StatefulWidget {
  final String title;
  final String content;
  final String voice; // 'male' (Ardi) atau 'female' (Gadis)
  final Color? primaryColor;

  const OpenVoicePlayerWidget({
    Key? key,
    required this.title,
    required this.content,
    this.voice = 'male',
    this.primaryColor,
  }) : super(key: key);

  @override
  State<OpenVoicePlayerWidget> createState() => _OpenVoicePlayerWidgetState();
}

class _OpenVoicePlayerWidgetState extends State<OpenVoicePlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isLoading = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  File? _audioFile;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
      if (state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioFile == null) {
        setState(() => _isLoading = true);

        final audioFile = await OpenVoiceService.fetchAudio(
          title: widget.title,
          content: widget.content,
          voice: widget.voice,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (audioFile != null) {
          _audioFile = audioFile;
          await _audioPlayer.play(DeviceFileSource(audioFile.path));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat audio Open Voice Neural TTS'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = widget.primaryColor ?? (isDark ? const Color(0xFF222222) : const Color(0xFFC82327));
    final textColor = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol Play / Pause / Loading
          IconButton(
            iconSize: 42,
            color: textColor,
            icon: _isLoading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
            onPressed: _isLoading ? null : _togglePlayPause,
          ),
          const SizedBox(width: 8),

          // Title & Progress Bar Slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dengarkan Artikel (Open Voice)',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    activeTrackColor: Colors.amber,
                    inactiveTrackColor: Colors.white30,
                    thumbColor: Colors.amber,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: _duration.inSeconds.toDouble() > 0
                        ? _duration.inSeconds.toDouble()
                        : 1.0,
                    value: _position.inSeconds.toDouble().clamp(
                          0.0,
                          _duration.inSeconds.toDouble() > 0
                              ? _duration.inSeconds.toDouble()
                              : 1.0,
                        ),
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
