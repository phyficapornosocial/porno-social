import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LiveListScreen extends StatefulWidget {
  const LiveListScreen({super.key});

  @override
  State<LiveListScreen> createState() => _LiveListScreenState();
}

class _LiveListScreenState extends State<LiveListScreen> {
  final _channelController = TextEditingController();

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _channelController,
              decoration: const InputDecoration(
                labelText: 'Channel name',
                hintText: 'e.g. friday-night-room',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openLive(isHost: true),
              icon: const Icon(Icons.live_tv),
              label: const Text('Start Live as Host'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openLive(isHost: false),
              icon: const Icon(Icons.remove_red_eye_outlined),
              label: const Text('Join as Viewer'),
            ),
          ],
        ),
      ),
    );
  }

  void _openLive({required bool isHost}) {
    final channel = _channelController.text.trim();
    if (channel.isEmpty) return;

    final hostFlag = isHost ? 'true' : 'false';
    context.push('/live/$channel?isHost=$hostFlag');
  }
}
