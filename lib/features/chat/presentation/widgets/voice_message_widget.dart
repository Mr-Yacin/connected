import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';

/// Widget for displaying and playing voice messages
class VoiceMessageWidget extends ConsumerStatefulWidget {
  final String audioUrl;
  final bool isMe;

  const VoiceMessageWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  ConsumerState<VoiceMessageWidget> createState() =>
      _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends ConsumerState<VoiceMessageWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    // Listen to player state
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to duration
    _player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position
    _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: widget.isMe ? Colors.white : Colors.black87,
          ),
          onPressed: _togglePlayPause,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),

        const SizedBox(width: 8),

        // Progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0,
                backgroundColor: widget.isMe ? Colors.white30 : Colors.grey[400],
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isMe ? Colors.white : Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _duration.inMilliseconds > 0
                    ? _formatDuration(_position)
                    : '00:00',
                style: TextStyle(
                  color: widget.isMe ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Duration
        Text(
          _formatDuration(_duration),
          style: TextStyle(
            color: widget.isMe ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
