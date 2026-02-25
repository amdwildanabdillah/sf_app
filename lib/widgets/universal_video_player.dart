import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart'; // <--- MENGGUNAKAN IFRAME
import 'package:flutter/services.dart';

class UniversalVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const UniversalVideoPlayer({
    super.key, 
    required this.videoUrl, 
    this.autoPlay = true
  });

  @override
  State<UniversalVideoPlayer> createState() => _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState extends State<UniversalVideoPlayer> {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool _isYoutube = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // 1. Cek apakah ini Link YouTube? (Pake cara Iframe)
      String? videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl);

      if (videoId != null && videoId.isNotEmpty) {
        // --- MODE YOUTUBE ---
        setState(() => _isYoutube = true);
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: widget.autoPlay,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            loop: false,
          ),
        );
      } else {
        // --- MODE MP4 (Raw Video / Storage) ---
        setState(() => _isYoutube = false);
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        
        await _videoPlayerController!.initialize();
        
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          aspectRatio: _videoPlayerController!.value.aspectRatio, 
          autoPlay: widget.autoPlay,
          looping: false,
          errorBuilder: (context, errorMessage) {
            return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
          },
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF2962FF), 
            handleColor: Colors.white,
            backgroundColor: Colors.grey.shade800,
            bufferedColor: Colors.grey.shade600,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error Init Video: $e");
      setState(() => _isError = true);
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        height: 250,
        color: Colors.black,
        child: const Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text("Gagal memuat video", style: TextStyle(color: Colors.white)),
          ],
        )),
      );
    }

    if (_isYoutube) {
      return _youtubeController != null
          ? SizedBox(
              height: 250, width: double.infinity,
              child: YoutubePlayer(
                controller: _youtubeController!,
                aspectRatio: 16 / 9,
              ),
            )
          : const Center(child: CircularProgressIndicator());
    } else {
      // Player MP4
      return _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            )
          : const SizedBox(
              height: 250, 
              child: Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)))
            );
    }
  }
}