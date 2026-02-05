import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  // Controller untuk YouTube
  YoutubePlayerController? _youtubeController;
  
  // Controller untuk MP4 (Chewie)
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
      // 1. Cek apakah ini Link YouTube?
      String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

      if (videoId != null) {
        // --- MODE YOUTUBE ---
        setState(() => _isYoutube = true);
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: widget.autoPlay,
            mute: false,
            forceHD: true,
            enableCaption: true,
          ),
        );
      } else {
        // --- MODE MP4 (Raw Video / Storage) ---
        setState(() => _isYoutube = false);
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        
        await _videoPlayerController!.initialize();
        
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          aspectRatio: _videoPlayerController!.value.aspectRatio, // Otomatis nyesuain (Portrait/Landscape)
          autoPlay: widget.autoPlay,
          looping: false,
          errorBuilder: (context, errorMessage) {
            return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
          },
          // Kustomisasi UI Chewie biar Vixel banget
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF2962FF), // Biru Vixel
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
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    
    // Balikin orientasi ke Portrait pas keluar player
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
          ? YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: const Color(0xFF2962FF),
              ),
              builder: (context, player) => player,
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