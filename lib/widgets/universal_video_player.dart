import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter/webview_flutter.dart'; 
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // <--- KUNCI ANTI BLANK WEB
import 'package:url_launcher/url_launcher.dart'; // <--- FALLBACK UNTUK WEB

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
            showControls: true, showFullscreenButton: true, loop: false, origin: 'https://www.youtube.com'
          ),
        );
        return;
      }

      // --- 2. DETEKSI INSTAGRAM / TIKTOK (WEBVIEW) ---
      if (url.contains('instagram.com') || url.contains('tiktok.com')) {
        setState(() => _mode = PlayerMode.webview);
        
        // HANYA init WebView jika BUKAN di Web, biar tidak crash
        if (!kIsWeb) {
          String finalUrl = widget.videoUrl;
          if (url.contains('instagram.com')) {
            finalUrl = widget.videoUrl.split('?').first; 
            if (!finalUrl.endsWith('/')) finalUrl += '/';
            finalUrl += 'embed/';
          } else if (url.contains('tiktok.com')) {
            final RegExp regex = RegExp(r'video\/(\d+)');
            final match = regex.firstMatch(widget.videoUrl);
            if (match != null) {
              finalUrl = 'https://www.tiktok.com/embed/v2/${match.group(1)}';
            }
          }

          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(finalUrl));
        }
        return;
      }

      // --- 3. DETEKSI MP4 ---
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

    if (_mode == PlayerMode.youtube && _youtubeController != null) {
      return SizedBox(height: 250, width: double.infinity, child: YoutubePlayer(controller: _youtubeController!, aspectRatio: 16 / 9));
    } 
    else if (_mode == PlayerMode.webview) {
      // --- LOGIC SAKTI ANTI BLANK DI WEB ---
      if (kIsWeb) {
        return Container(
          height: 250, width: double.infinity, color: const Color(0xFF1A1A1A),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.externalLink, color: Colors.blueAccent, size: 40),
              const SizedBox(height: 16),
              const Text("Video platform ini tidak dapat disematkan di Web.", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: () => launchUrl(Uri.parse(widget.videoUrl), mode: LaunchMode.externalApplication), 
                icon: const Icon(Icons.open_in_new, color: Colors.white, size: 16),
                label: const Text("Tonton di Platform Asli", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        );
      } else {
        return SizedBox(
          height: 450, width: double.infinity,
          child: WebViewWidget(controller: _webViewController),
        );
      }
    } 
    else if (_mode == PlayerMode.mp4 && _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(aspectRatio: _videoPlayerController!.value.aspectRatio, child: Chewie(controller: _chewieController!));
    } 
    
    return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator(color: Color(0xFF2962FF))));
  }
}