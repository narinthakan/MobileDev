import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

const String GEMINI_API_KEY = 'AIzaSyCUaMTYFMj-C5kG75kiSyZzbL-cam-TI5s';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat App (Gemini)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4FC3F7),
          primaryContainer: Color(0xFFE1F5FE),
          secondary: Color(0xFF81D4FA),
          surface: Colors.white,
          background: Color(0xFFFAFAFA),
          surfaceVariant: Color(0xFFF5F5F5),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  Future<String> fetchGeminiResponse(String prompt) async {
    if (GEMINI_API_KEY.isEmpty || GEMINI_API_KEY == 'YOUR_ACTUAL_GEMINI_API_KEY_HERE') {
      return "❌ ไม่พบ Gemini API Key (กรุณาแทนที่ในโค้ด)";
    }

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: GEMINI_API_KEY);
      final String fullPrompt = "You are a helpful assistant. Be concise and friendly. Answer in Thai if user asks in Thai. User Query: $prompt";
      final response = await model.generateContent([Content.text(fullPrompt)]);
      return response.text ?? "❌ AI ไม่ได้ให้คำตอบ";
    } catch (e) {
      if (e.toString().contains('Invalid API key')) {
        return "🛑 ERROR: API Key ไม่ถูกต้องหรือหมดอายุ (โปรดตรวจสอบ Key ของคุณ)";
      }
      return "❌ Exception: ${e.toString()}";
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    
    final userMessage = ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _scrollToBottom();

    final reply = await fetchGeminiResponse(text);

    final aiMessage = ChatMessage(text: reply, isUser: false);
    setState(() {
      _messages.add(aiMessage);
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Gemini AI",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  "พร้อมช่วยเหลือคุณ",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          Flexible(
            child: _messages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _messages[_messages.length - 1 - i],
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(context),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "เริ่มต้นการสนทนา",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "ถามคำถามอะไรก็ได้ ฉันพร้อมช่วยเหลือคุณ",
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "AI กำลังพิมพ์...",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFEEEEEE),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  onSubmitted: _handleSubmitted,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: "พิมพ์ข้อความ...",
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded),
                color: Colors.white,
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatefulWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isUser ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alignment = widget.isUser ? Alignment.centerRight : Alignment.centerLeft;

    Color bubbleColor;
    Color textColor;
    
    if (widget.isUser) {
      bubbleColor = const Color(0xFF4FC3F7);
      textColor = Colors.white;
    } else {
      bubbleColor = Colors.white;
      textColor = const Color(0xFF37474F);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          alignment: alignment,
          child: Row(
            mainAxisAlignment:
                widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isUser) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(widget.isUser ? 20 : 4),
                      bottomRight: Radius.circular(widget.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (widget.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}