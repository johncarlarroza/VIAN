import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/vivian_ai_service.dart';

class VivianChatSheet extends StatefulWidget {
  final String orderType;

  const VivianChatSheet({super.key, required this.orderType});

  @override
  State<VivianChatSheet> createState() => _VivianChatSheetState();
}

class _VivianChatSheetState extends State<VivianChatSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VivianAiService _service = VivianAiService();

  bool _isSending = false;

  late final AnimationController _sheetController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Hi! I’m Vivian ✨\nI can help with menu items, prices, ingredients, pairings, recommendations, and your cart.',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _sheetController, curve: Curves.easeOutCubic),
    );

    _sheetController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _send({String? presetText}) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    final cart = context.read<CartProvider>();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final reply = await _service.askVivian(
        message: text,
        orderType: widget.orderType,
        cartItems: cart.itemList,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text: reply.trim().isEmpty
                ? 'Sorry, I could not generate a reply right now.'
                : reply,
            isUser: false,
          ),
        );
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
                'Sorry, something went wrong while contacting Vivian. Please try again.',
            isUser: false,
          ),
        );
        _isSending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 180,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width >= 1200;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment:
                  isWide ? Alignment.bottomRight : Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  isWide ? 0 : 10,
                  0,
                  isWide ? 18 : 10,
                  isWide ? 16 : 0,
                ),
                width: isWide ? 430 : double.infinity,
                height: isWide ? size.height * 0.82 : size.height * 0.88,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FBF8).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(isWide ? 30 : 28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.55),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 26,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isWide ? 30 : 28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildQuickPrompts(),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF7FBF8),
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(14, 14, 14, 10),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final m = _messages[index];
                                return _ChatBubble(message: m);
                              },
                            ),
                          ),
                        ),
                        if (_isSending) _buildTypingIndicator(),
                        _buildInputArea(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0E4F31), Color(0xFF166534), Color(0xFF2B7A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/vivian_logo.gif',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3A7E4B),
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7CFFAA),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vivian',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'VIAN CAFE AI Assistant',
                  style: TextStyle(
                    color: Color(0xFFE8F7EC),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    final prompts = [
      'What is your best coffee?',
      'What meals do you suggest?',
      'Recommend something sweet',
      'What is in my cart?',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F8F3),
        border: Border(bottom: BorderSide(color: Color(0xFFE1ECE4))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: prompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _isSending ? null : () => _send(presetText: prompt),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDCE7DF)),
                  ),
                  child: Text(
                    prompt,
                    style: const TextStyle(
                      color: Color(0xFF315243),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.3,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: const Color(0xFFE3ECE5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DotPulse(delay: 0),
            SizedBox(width: 4),
            _DotPulse(delay: 160),
            SizedBox(width: 4),
            _DotPulse(delay: 320),
            SizedBox(width: 10),
            Text(
              'Vivian is typing.',
              style: TextStyle(
                color: Color(0xFF5D6E65),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4ECE6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1E8E3)),
              ),
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Ask Vivian about menu items, recommendations, or your cart...',
                  hintStyle: TextStyle(
                    color: Color(0xFF93A19A),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSending ? null : () => _send(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6D44),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFC8D5CD),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final align =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleColor =
        message.isUser ? const Color(0xFF1F6D44) : Colors.white;

    final textColor =
        message.isUser ? Colors.white : const Color(0xFF223128);

    final borderRadius = message.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          );

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          border: message.isUser
              ? null
              : Border.all(color: const Color(0xFFE3ECE5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  final int delay;

  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _opacity = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF5D6E65),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}