import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'split_screen.dart';
import '../utils/upi_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  final _nameController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SplitScreen(
            totalAmount: double.parse(_amountController.text),
            upiId: _upiController.text.trim(),
            payeeName: _nameController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Logo mark
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4A8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          '₹',
                          style: TextStyle(
                            color: Color(0xFF0A0A0F),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'SplitPe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Split bills. Share UPI links. Done.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),

                    _label('Total Bill Amount'),
                    const SizedBox(height: 8),
                    _AmountField(controller: _amountController),
                    const SizedBox(height: 24),

                    _label('Your Name'),
                    const SizedBox(height: 8),
                    _StyledField(
                      controller: _nameController,
                      hint: 'Rahul Sharma',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your name';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _label('Your UPI ID'),
                    const SizedBox(height: 8),
                    _StyledField(
                      controller: _upiController,
                      hint: 'rahul@okaxis',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your UPI ID';
                        if (!UpiHelper.isValidUpiId(v.trim())) return 'Enter a valid UPI ID (e.g. name@okaxis)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 48),

                    _ProceedButton(onTap: _proceed),
                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'No account needed · Works offline · 100% free',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F2E)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            alignment: Alignment.center,
            child: const Text(
              '₹',
              style: TextStyle(
                color: Color(0xFF00D4A8),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(width: 1, height: 24, color: const Color(0xFF1F1F2E)),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Color(0xFF2D2D3D), fontSize: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter the total amount';
                final parsed = double.tryParse(v);
                if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F2E)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF2D2D3D)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}

class _ProceedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ProceedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF00D4A8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'Add People & Split →',
            style: TextStyle(
              color: Color(0xFF0A0A0F),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}