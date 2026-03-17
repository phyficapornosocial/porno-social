import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:porno_social/features/live/live_chat_overlay.dart';

const agoraAppId = 'YOUR_AGORA_APP_ID';

class LiveStreamScreen extends StatefulWidget {
  final bool isHost;
  final String channelName;

  const LiveStreamScreen({
    super.key,
    required this.isHost,
    required this.channelName,
  });

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _localUserJoined = false;
  int _viewerCount = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    if (widget.channelName.isEmpty || agoraAppId == 'YOUR_AGORA_APP_ID') {
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: agoraAppId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (!mounted) {
            return;
          }
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!mounted) {
            return;
          }
          setState(() {
            _remoteUid = remoteUid;
            _viewerCount++;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!mounted) {
            return;
          }
          setState(() {
            if (_remoteUid == remoteUid) {
              _remoteUid = null;
            }
            _viewerCount = (_viewerCount - 1).clamp(0, 999999);
          });
        },
      ),
    );

    await _engine.setClientRole(
      role: widget.isHost
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    if (widget.isHost) {
      await _engine.enableVideo();
      await _engine.startPreview();
    }

    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );

    if (!mounted) {
      return;
    }
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configMissing =
        widget.channelName.isEmpty || agoraAppId == 'YOUR_AGORA_APP_ID';

    if (configMissing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Stream'),
          backgroundColor: const Color(0xFF080808),
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Set a valid Agora App ID and channel name to start streaming.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (widget.isHost && _localUserJoined)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          if (!widget.isHost && _remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            ),
          if (!widget.isHost && _remoteUid == null)
            const Center(
              child: Text(
                'Waiting for host to go live...',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_viewerCount',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: LiveChatOverlay(channelName: widget.channelName),
          ),
        ],
      ),
    );
  }
}
