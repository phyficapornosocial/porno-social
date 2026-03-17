import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SubscribeScreen extends StatefulWidget {
  final String creatorId;
  final double price;

  const SubscribeScreen({
    super.key,
    required this.creatorId,
    required this.price,
  });

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    final segpayUrl =
        'https://www.segpay.com/payment?merchant_id=YOUR_MERCHANT_ID&price=${widget.price}&currency=GBP&item_desc=Subscription+to+Creator&return_url=https://porno-social.com/subscription/success';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains('/subscription/success')) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(segpayUrl));
  }

  Future<void> _handlePaymentSuccess() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('subscriptions').add({
      'subscriberId': uid,
      'creatorId': widget.creatorId,
      'tier': 'monthly',
      'status': 'active',
      'price': widget.price,
      'currency': 'GBP',
      'startedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
      'segpayTransactionId': '',
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe'),
        backgroundColor: const Color(0xFF080808),
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}
