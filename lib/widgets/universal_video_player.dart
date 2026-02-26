import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter/webview_flutter.dart'; // <--- TAMBAHAN WEBVIEW
import 'package:flutter/services.dart';

enum PlayerMode { youtube, mp4, webview }

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
  PlayerMode _mode = PlayerMode.mp4;
  bool _isError = false;

  // Controllers
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final url = widget.videoUrl.toLowerCase();

      // --- 1. DETEKSI YOUTUBE ---
      String? ytId = YoutubePlayerController.convertUrlToId(widget.videoUrl);
      if (ytId != null && ytId.isNotEmpty) {
        setState(() => _mode = PlayerMode.youtube);
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: ytId,
          autoPlay: widget.autoPlay,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            loop: false,
            origin: 'https://www.youtube.com'
          ),
        );
        return;
      }

      // --- 2. DETEKSI INSTAGRAM / TIKTOK (WEBVIEW EMBED) ---
      if (url.contains('instagram.com') || url.contains('tiktok.com')) {
        setState(() => _mode = PlayerMode.webview);
        String finalUrl = widget.videoUrl;

        // Trik Embed Instagram (buang parameter ?igsh=, lalu tambah /embed)
        if (url.contains('instagram.com')) {
          finalUrl = widget.videoUrl.split('?').first; 
          if (!finalUrl.endsWith('/')) finalUrl += '/';
          finalUrl += 'embed/';
        } 
        // Trik Embed TikTok
        else if (url.contains('tiktok.com')) {
          final RegExp regex = RegExp(r'video\/(\d+)');
          final match = regex.firstMatch(widget.videoUrl);
          if (match != null) {
            finalUrl = 'https://www.tiktok.com/embed/v2/${match.group(1)}';
          }
        }

        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(finalUrl));
        return;
      }

      // --- 3. DETEKSI MP4 / SUPABASE STORAGE (CHEWIE) ---
      setState(() => _mode = PlayerMode.mp4);
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio, 
        autoPlay: widget.autoPlay, looping: false,
        materialProgressColors: ChewieProgressColors(playedColor: const Color(0xFF2962FF), handleColor: Colors.white, backgroundColor: Colors.grey.shade800),
      );
      setState(() {});

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
      return Container(height: 250, color: Colors.black, child: const Center(child: Text("Gagal memuat video", style: TextStyle(color: Colors.white))));
    }

    // TAMPILAN YOUTUBE
    if (_mode == PlayerMode.youtube && _youtubeController != null) {
      return SizedBox(height: 250, width: double.infinity, child: YoutubePlayer(controller: _youtubeController!, aspectRatio: 16 / 9));
    } 
    
    // TAMPILAN IG & TIKTOK (WEBVIEW) -> Dibuat Agak Tinggi (Vertical Video)
    else if (_mode == PlayerMode.webview) {
      return SizedBox(
        height: 450, width: double.infinity,
        child: WebViewWidget(controller: _webViewController),
      );
    } 
    
    // TAMPILAN MP4 RAW
    else if (_mode == PlayerMode.mp4 && _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(aspectRatio: _videoPlayerController!.value.aspectRatio, child: Chewie(controller: _chewieController!));
    } 
    
    return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator(color: Color(0xFF2962FF))));
  }
}