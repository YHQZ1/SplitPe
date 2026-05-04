class UpiHelper {
  // Your GitHub Pages URL — change YOUR_GITHUB_USERNAME to your actual username
  static const String _baseUrl = 'https://split-pe.vercel.app';

  /// Generates a shareable web link that opens the payment page.
  /// This works in WhatsApp, iMessage, etc. — no raw upi:// scheme.
  static String generateShareableLink({
    required String upiId,
    required String payeeName,
    required double amount,
    String? note,
  }) {
    final params = [
      'pa=${Uri.encodeComponent(upiId)}',
      'pn=${Uri.encodeComponent(payeeName)}',
      'am=${amount.toStringAsFixed(2)}',
      'tn=${Uri.encodeComponent(note ?? 'Bill Split via SplitPe')}',
    ].join('&');

    return '$_baseUrl/#\$params';
  }

  /// Raw upi:// link — used internally on-device (Pay via UPI button)
  static String generateLink({
    required String upiId,
    required String payeeName,
    required double amount,
    String? note,
  }) {
    final encodedName = Uri.encodeComponent(payeeName);
    final encodedNote = Uri.encodeComponent(note ?? 'Bill Split via SplitPe');
    final formattedAmount = amount.toStringAsFixed(2);
    return 'upi://pay?pa=\$upiId&pn=\$encodedName&am=\$formattedAmount&cu=INR&tn=\$encodedNote';
  }

  static String generateWhatsAppMessage({
    required String participantName,
    required double amount,
    required String shareableLink,
    required String payeeName,
  }) {
    return 'Hey \$participantName! Your share is ₹\${amount.toStringAsFixed(2)}.'
        '\n\nPay \$payeeName via UPI 👇'
        '\n\$shareableLink'
        '\n\nTap the link → your UPI app will open automatically'
        '\nIf not, choose your app manually 👇';
  }

  static bool isValidUpiId(String upiId) {
    final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    return upiRegex.hasMatch(upiId);
  }
}
