import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/participant.dart';
import '../utils/upi_helper.dart';

class ResultScreen extends StatefulWidget {
  final List<Participant> participants;
  final String upiId;
  final String payeeName;
  final double totalAmount;

  const ResultScreen({
    super.key,
    required this.participants,
    required this.upiId,
    required this.payeeName,
    required this.totalAmount,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final Set<int> _copiedIndices = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getUpiLink(Participant p) {
    return UpiHelper.generateLink(
      upiId: widget.upiId,
      payeeName: widget.payeeName,
      amount: p.amount,
    );
  }

  Future<void> _openUpiLink(Participant p) async {
    final upiLink = _getUpiLink(p);

    if (Theme.of(context).platform == TargetPlatform.android) {
      // Android: LaunchMode.externalApplication triggers the OS's native
      // "Open with" chooser — GPay, PhonePe, Paytm all appear automatically
      final uri = Uri.parse(upiLink);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) _showUpiPicker(p, upiLink);
      }
    } else {
      // iOS: no system UPI chooser — show our own app picker bottom sheet
      if (mounted) _showUpiPicker(p, upiLink);
    }
  }

  void _showUpiPicker(Participant p, String upiLink) {
    final query = Uri.parse(upiLink).query;
    final apps = [
      {
        'name': 'Google Pay',
        'emoji': '🟢',
        'scheme': 'gpay://upi/pay?$query',
      },
      {
        'name': 'PhonePe',
        'emoji': '🟣',
        'scheme': 'phonepe://pay?$query',
      },
      {
        'name': 'Paytm',
        'emoji': '🔵',
        'scheme': 'paytmmp://pay?$query',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay with UPI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose your UPI app',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4A8).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${p.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00D4A8),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...apps.map((app) => GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse(app['scheme']!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${app['name']} is not installed'),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2A3A)),
                ),
                child: Row(
                  children: [
                    Text(app['emoji']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        app['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF374151),
                      size: 14,
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 4),
            Container(height: 1, color: const Color(0xFF1F1F2E)),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: upiLink));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('UPI link copied!'),
                    backgroundColor: const Color(0xFF00D4A8),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded,
                        color: Color(0xFF6B7280), size: 18),
                    const SizedBox(width: 12),
                    Text(
                      'Copy UPI link instead',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyLink(int index, Participant p) async {
    final link = UpiHelper.generateShareableLink(upiId: widget.upiId, payeeName: widget.payeeName, amount: p.amount);
    await Clipboard.setData(ClipboardData(text: link));
    setState(() => _copiedIndices.add(index));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedIndices.remove(index));
    });
  }

  Future<void> _shareWhatsApp(Participant p) async {
    final link = UpiHelper.generateShareableLink(upiId: widget.upiId, payeeName: widget.payeeName, amount: p.amount);
    final message = UpiHelper.generateWhatsAppMessage(
      participantName: p.name,
      amount: p.amount,
      shareableLink: link,
      payeeName: widget.payeeName,
    );
    final encoded = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      final shareUri = Uri.parse('https://wa.me/?text=$encoded');
      if (await canLaunchUrl(shareUri)) {
        await launchUrl(shareUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _shareAll() async {
    final buffer = StringBuffer();
    buffer.writeln('💸 Payment links from ${widget.payeeName}\n');
    for (final p in widget.participants) {
      buffer.writeln('${p.name}: ₹${p.amount.toStringAsFixed(2)}');
      buffer.writeln(_getUpiLink(p));
      buffer.writeln();
    }
    buffer.writeln('_Sent via SplitPe_');
    final message = buffer.toString();
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Links',
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: _shareAll,
            icon: const Icon(Icons.send, size: 15, color: Color(0xFF00D4A8)),
            label: const Text(
              'Share All',
              style: TextStyle(
                  color: Color(0xFF00D4A8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryBanner(
            totalAmount: widget.totalAmount,
            participantCount: widget.participants.length,
            payeeName: widget.payeeName,
            upiId: widget.upiId,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: widget.participants.length,
              itemBuilder: (context, i) {
                final p = widget.participants[i];
                final delay = i * 0.08;
                return AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final t = (((_animController.value - delay) / (1 - delay))
                        .clamp(0.0, 1.0));
                    final curved = Curves.easeOutCubic.transform(t);
                    return Opacity(
                      opacity: curved,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - curved)),
                        child: child,
                      ),
                    );
                  },
                  child: _PaymentCard(
                    participant: p,
                    index: i,
                    isCopied: _copiedIndices.contains(i),
                    onTapPay: () => _openUpiLink(p),
                    onTapCopy: () => _copyLink(i, p),
                    onTapWhatsApp: () => _shareWhatsApp(p),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _DoneBar(
        onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final double totalAmount;
  final int participantCount;
  final String payeeName;
  final String upiId;

  const _SummaryBanner({
    required this.totalAmount,
    required this.participantCount,
    required this.payeeName,
    required this.upiId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4A8), Color(0xFF00B894)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${totalAmount.toStringAsFixed(2)} total',
                  style: const TextStyle(
                    color: Color(0xFF0A0A0F),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Split $participantCount ways · Pay to $payeeName',
                  style: TextStyle(
                    color: const Color(0xFF0A0A0F).withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              upiId,
              style: const TextStyle(
                color: Color(0xFF0A0A0F),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Participant participant;
  final int index;
  final bool isCopied;
  final VoidCallback onTapPay;
  final VoidCallback onTapCopy;
  final VoidCallback onTapWhatsApp;

  const _PaymentCard({
    required this.participant,
    required this.index,
    required this.isCopied,
    required this.onTapPay,
    required this.onTapCopy,
    required this.onTapWhatsApp,
  });

  Color get _avatarColor {
    final colors = [
      const Color(0xFF00D4A8),
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F2E)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _avatarColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      participant.name[0].toUpperCase(),
                      style: TextStyle(
                        color: _avatarColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap Pay to open UPI app',
                        style:
                            TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${participant.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFF1F1F2E)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _ActionButton(
                    label: 'Pay via UPI',
                    icon: Icons.payment_rounded,
                    primary: true,
                    onTap: onTapPay,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    label: isCopied ? 'Copied!' : 'Copy Link',
                    icon: isCopied ? Icons.check : Icons.copy_rounded,
                    primary: false,
                    onTap: onTapCopy,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTapWhatsApp,
                  child: Container(
                    width: 44,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('💬', style: TextStyle(fontSize: 18)),
                    ),
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF00D4A8) : const Color(0xFF1F1F2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: primary
                  ? const Color(0xFF0A0A0F)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: primary
                    ? const Color(0xFF0A0A0F)
                    : const Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneBar extends StatelessWidget {
  final VoidCallback onDone;
  const _DoneBar({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        border: Border(top: BorderSide(color: Color(0xFF1F1F2E))),
      ),
      child: GestureDetector(
        onTap: onDone,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F2E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'Split Another Bill',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}