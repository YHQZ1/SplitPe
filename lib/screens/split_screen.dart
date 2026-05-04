import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/participant.dart';
import 'result_screen.dart';

class SplitScreen extends StatefulWidget {
  final double totalAmount;
  final String upiId;
  final String payeeName;

  const SplitScreen({
    super.key,
    required this.totalAmount,
    required this.upiId,
    required this.payeeName,
  });

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  final List<Participant> _participants = [];
  final _nameController = TextEditingController();
  bool _equalSplit = true;
  final Map<int, TextEditingController> _amountControllers = {};

  double get _equalShare {
    if (_participants.isEmpty) return 0;
    return widget.totalAmount / _participants.length;
  }

  double get _assignedTotal {
    if (_equalSplit) return _participants.length * _equalShare;
    double total = 0;
    for (int i = 0; i < _participants.length; i++) {
      final text = _amountControllers[i]?.text ?? '';
      total += double.tryParse(text) ?? 0;
    }
    return total;
  }

  double get _remaining => widget.totalAmount - _assignedTotal;

  void _addParticipant() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      final idx = _participants.length;
      _participants.add(Participant(name: name, amount: _equalShare));
      _amountControllers[idx] = TextEditingController(
        text: _equalShare.toStringAsFixed(2),
      );
      _nameController.clear();
      if (_equalSplit) _recalculateEqual();
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
      // Rebuild controllers map
      final oldControllers = Map<int, TextEditingController>.from(_amountControllers);
      _amountControllers.clear();
      for (int i = 0; i < _participants.length; i++) {
        final oldIdx = i >= index ? i + 1 : i;
        _amountControllers[i] = oldControllers[oldIdx] ?? TextEditingController();
      }
      if (_equalSplit) _recalculateEqual();
    });
  }

  void _recalculateEqual() {
    if (_participants.isEmpty) return;
    final share = widget.totalAmount / _participants.length;
    for (int i = 0; i < _participants.length; i++) {
      _participants[i] = _participants[i].copyWith(amount: share);
      _amountControllers[i]?.text = share.toStringAsFixed(2);
    }
  }

  void _toggleSplitMode(bool equal) {
    setState(() {
      _equalSplit = equal;
      if (equal) _recalculateEqual();
    });
  }

  bool get _canProceed {
    if (_participants.isEmpty) return false;
    if (!_equalSplit) {
      return (_remaining.abs() < 0.01);
    }
    return true;
  }

  void _proceed() {
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _participants.isEmpty
                ? 'Add at least one person'
                : 'Amounts don\'t add up to ₹${widget.totalAmount.toStringAsFixed(2)}',
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Sync custom amounts to participants
    if (!_equalSplit) {
      for (int i = 0; i < _participants.length; i++) {
        final amount = double.tryParse(_amountControllers[i]?.text ?? '0') ?? 0;
        _participants[i] = _participants[i].copyWith(amount: amount);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          participants: _participants,
          upiId: widget.upiId,
          payeeName: widget.payeeName,
          totalAmount: widget.totalAmount,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Split Bill',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              '₹${widget.totalAmount.toStringAsFixed(2)} total',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Split mode toggle
                  _SplitToggle(
                    equalSplit: _equalSplit,
                    onToggle: _toggleSplitMode,
                  ),
                  const SizedBox(height: 24),

                  // Add person input
                  _label('Add People'),
                  const SizedBox(height: 8),
                  _AddPersonRow(
                    controller: _nameController,
                    onAdd: _addParticipant,
                  ),
                  const SizedBox(height: 24),

                  // Participants list
                  if (_participants.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _label('${_participants.length} ${_participants.length == 1 ? 'person' : 'people'}'),
                        if (!_equalSplit)
                          Text(
                            _remaining.abs() < 0.01
                                ? '✓ Balanced'
                                : _remaining > 0
                                    ? '₹${_remaining.toStringAsFixed(2)} left'
                                    : '₹${(-_remaining).toStringAsFixed(2)} over',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _remaining.abs() < 0.01
                                  ? const Color(0xFF00D4A8)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_participants.length, (i) {
                      return _ParticipantTile(
                        participant: _participants[i],
                        index: i,
                        equalSplit: _equalSplit,
                        amountController: _amountControllers[i]!,
                        onRemove: () => _removeParticipant(i),
                        onAmountChanged: (val) {
                          setState(() {
                            final amount = double.tryParse(val) ?? 0;
                            _participants[i] = _participants[i].copyWith(amount: amount);
                          });
                        },
                      );
                    }),
                  ] else
                    _EmptyState(),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        canProceed: _canProceed,
        participantCount: _participants.length,
        totalAmount: widget.totalAmount,
        onProceed: _proceed,
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
      ),
    );
  }
}

class _SplitToggle extends StatelessWidget {
  final bool equalSplit;
  final ValueChanged<bool> onToggle;

  const _SplitToggle({required this.equalSplit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F2E)),
      ),
      child: Row(
        children: [
          _Tab(label: 'Equal Split', active: equalSplit, onTap: () => onToggle(true)),
          _Tab(label: 'Custom Amounts', active: !equalSplit, onTap: () => onToggle(false)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF00D4A8) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF0A0A0F) : const Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPersonRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddPersonRow({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F1F2E)),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => onAdd(),
              decoration: const InputDecoration(
                hintText: 'Enter name...',
                hintStyle: TextStyle(color: Color(0xFF2D2D3D)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4A8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Color(0xFF0A0A0F), size: 22),
          ),
        ),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final Participant participant;
  final int index;
  final bool equalSplit;
  final TextEditingController amountController;
  final VoidCallback onRemove;
  final ValueChanged<String> onAmountChanged;

  const _ParticipantTile({
    required this.participant,
    required this.index,
    required this.equalSplit,
    required this.amountController,
    required this.onRemove,
    required this.onAmountChanged,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F2E)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _avatarColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                participant.name[0].toUpperCase(),
                style: TextStyle(
                  color: _avatarColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participant.name,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          if (equalSplit)
            Text(
              '₹${participant.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF00D4A8),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            SizedBox(
              width: 90,
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                onChanged: onAmountChanged,
                style: const TextStyle(
                  color: Color(0xFF00D4A8),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  prefixText: '₹',
                  prefixStyle: TextStyle(color: Color(0xFF00D4A8), fontWeight: FontWeight.w700),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: Color(0xFF374151), size: 18),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            '👥',
            style: TextStyle(fontSize: 40, color: Colors.white.withOpacity(0.15)),
          ),
          const SizedBox(height: 12),
          Text(
            'Add people to split with',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool canProceed;
  final int participantCount;
  final double totalAmount;
  final VoidCallback onProceed;

  const _BottomBar({
    required this.canProceed,
    required this.participantCount,
    required this.totalAmount,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        border: Border(top: BorderSide(color: Color(0xFF1F1F2E))),
      ),
      child: GestureDetector(
        onTap: canProceed ? onProceed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: canProceed ? const Color(0xFF00D4A8) : const Color(0xFF1F1F2E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              participantCount == 0
                  ? 'Add at least one person'
                  : 'Generate ${participantCount} Payment ${participantCount == 1 ? 'Link' : 'Links'} →',
              style: TextStyle(
                color: canProceed ? const Color(0xFF0A0A0F) : const Color(0xFF374151),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}