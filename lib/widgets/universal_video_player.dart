import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui' as ui;

enum PlayerMode { youtube, mp4, webview, iframeWeb }

class UniversalVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const UniversalVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
  });

  @override
  State<UniversalVideoPlayer> createState() =>
      _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState
    extends State<UniversalVideoPlayer> {
  PlayerMode _mode = PlayerMode.mp4;
  bool _isError = false;

  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final lowerUrl = widget.videoUrl.toLowerCase();

      /// =============================
      /// 1️⃣ YOUTUBE
      /// =============================
      String? ytId =
          YoutubePlayerController.convertUrlToId(widget.videoUrl);

      if (ytId != null && ytId.isNotEmpty) {
        _mode = PlayerMode.youtube;

        _youtubeController =
            YoutubePlayerController.fromVideoId(
          videoId: ytId,
          autoPlay: widget.autoPlay,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            loop: false,
          ),
        );

        setState(() {});
        return;
      }

      /// =============================
      /// 2️⃣ INSTAGRAM / TIKTOK
      /// =============================
      if (lowerUrl.contains("instagram.com") ||
          lowerUrl.contains("tiktok.com")) {
        if (kIsWeb) {
          _mode = PlayerMode.iframeWeb;
          setState(() {});
          return;
        } else {
          _mode = PlayerMode.webview;

          String embedUrl = widget.videoUrl;

          if (lowerUrl.contains("instagram.com")) {
            embedUrl = widget.videoUrl.split("?").first;
            if (!embedUrl.endsWith("/")) {
              embedUrl += "/";
            }
            embedUrl += "embed/";
          }

          if (lowerUrl.contains("tiktok.com")) {
            final regex = RegExp(r'video\/(\d+)');
            final match = regex.firstMatch(widget.videoUrl);
            if (match != null) {
              embedUrl =
                  "https://www.tiktok.com/embed/v2/${match.group(1)}";
            }
          }

          _webViewController = WebViewController()
            ..setJavaScriptMode(
                JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(embedUrl));

          setState(() {});
          return;
        }
      }

      /// =============================
      /// 3️⃣ MP4 DIRECT LINK
      /// =============================
      _mode = PlayerMode.mp4;

      _videoController =
          VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        aspectRatio:
            _videoController!.value.aspectRatio == 0
                ? 16 / 9
                : _videoController!.value.aspectRatio,
        autoPlay: widget.autoPlay,
        allowFullScreen: true,
      );

      setState(() {});
    } catch (e) {
      debugPrint("Video Init Error: $e");
      _isError = true;
      setState(() {});
    }
  }

  /// =============================
  /// Web Iframe Builder
  /// =============================
  Widget _buildWebIframe() {
    String embedUrl = widget.videoUrl;

    if (widget.videoUrl.contains("instagram.com")) {
      embedUrl = widget.videoUrl.split("?").first;
      if (!embedUrl.endsWith("/")) {
        embedUrl += "/";
      }
      embedUrl += "embed/";
    }

    if (widget.videoUrl.contains("tiktok.com")) {
      final regex = RegExp(r'video\/(\d+)');
      final match = regex.firstMatch(widget.videoUrl);
      if (match != null) {
        embedUrl =
            "https://www.tiktok.com/embed/v2/${match.group(1)}";
      }
    }

    final viewType =
        "iframe-${widget.videoUrl.hashCode}";

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = embedUrl
          ..style.border = "none"
          ..allowFullscreen = true;

        return iframe;
      },
    );

    return HtmlElementView(viewType: viewType);
  }

  @override
  void dispose() {
    _youtubeController?.close();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        height: 250,
        color: Colors.black,
        child: const Center(
          child: Text(
            "Gagal memuat video",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_mode == PlayerMode.youtube &&
        _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        aspectRatio: 16 / 9,
      );
    }

    if (kIsWeb &&
        _mode == PlayerMode.iframeWeb) {
      return SizedBox(
        height: 400,
        width: double.infinity,
        child: _buildWebIframe(),
      );
    }

    if (_mode == PlayerMode.webview &&
        _webViewController != null) {
      return SizedBox(
        height: 450,
        width: double.infinity,
        child: WebViewWidget(
          controller: _webViewController!,
        ),
      );
    }

    if (_mode == PlayerMode.mp4 &&
        _chewieController != null &&
        _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio:
            _videoController!.value.aspectRatio == 0
                ? 16 / 9
                : _videoController!.value.aspectRatio,
        child: Chewie(
          controller: _chewieController!,
        ),
      );
    }

    return const SizedBox(
      height: 250,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}