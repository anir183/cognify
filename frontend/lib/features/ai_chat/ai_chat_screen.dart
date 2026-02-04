import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath; // For display on mobile
  final Uint8List? imageBytes; // For web and sending to API
  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    this.imageBytes,
  });
}

class ChatController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text:
            "Greetings, seeker of knowledge. I am the Oracle, your AI guide through the realm of learning. Ask me anything!",
        isUser: false,
      ),
    ];
  }

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // Build conversation context from previous messages (last 6 messages)
  String _buildContext() {
    final messages = state;
    if (messages.length <= 1) return '';

    final recentMessages = messages.length > 6
        ? messages.sublist(messages.length - 6)
        : messages;

    return recentMessages
        .map((m) {
          return m.isUser ? 'User: ${m.text}' : 'Oracle: ${m.text}';
        })
        .join('\n');
  }

  Future<void> sendMessage(
    String text, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (text.trim().isEmpty && imageBytes == null) return;

    String displayText = text;
    if (imageBytes != null) {
      displayText = text.isEmpty
          ? '[Image attached]'
          : '$text\n[Image attached]';
    }

    state = [
      ...state,
      ChatMessage(text: displayText, isUser: true, imageBytes: imageBytes),
    ];
    _isTyping = true;
    ref.notifyListeners();

    try {
      Map<String, dynamic> response;

      if (imageBytes != null) {
        // Use image-chat endpoint for image analysis
        response = await ApiService.postMultipart(
          '/api/ai/image-chat',
          imageBytes: imageBytes,
          filename: imageName ?? 'image.jpg',
          message: text,
        );
      } else {
        // Use regular chat endpoint
        final context = _buildContext();
        response = await ApiService.post('/api/ai/chat', {
          'message': text,
          'context': context,
        });
      }

      if (response['success'] == true && response['response'] != null) {
        state = [
          ...state,
          ChatMessage(text: response['response'], isUser: false),
        ];
      } else {
        state = [
          ...state,
          ChatMessage(
            text:
                "I'm having trouble connecting to the ether. Please try again.",
            isUser: false,
          ),
        ];
      }
    } catch (e) {
      state = [...state, ChatMessage(text: "Error: $e", isUser: false)];
    } finally {
      _isTyping = false;
      ref.notifyListeners();
    }
  }
}

final chatProvider = NotifierProvider<ChatController, List<ChatMessage>>(
  ChatController.new,
);

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Voice input
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Image picker - store bytes for cross-platform compatibility
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  final List<String> _suggestions = [
    "Explain Flutter widgets",
    "Quiz me on Dart",
    "Tips for learning faster",
    "What is state management?",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _sendMessage(String text) {
    ref
        .read(chatProvider.notifier)
        .sendMessage(
          text,
          imageBytes: _selectedImageBytes,
          imageName: _selectedImageName,
        );
    _controller.clear();
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
    _scrollToBottom();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          setState(() => _isListening = false);
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
      );
      debugPrint('Speech available: $available');
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
        );
      } else {
        // Show snackbar if speech not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition not available. Please check microphone permissions.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        // Read bytes for cross-platform compatibility
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final controller = ref.read(chatProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentPurple.withOpacity(0.3),
                              AppTheme.primaryCyan.withOpacity(0.3),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentPurple.withOpacity(0.5),
                          ),
                        ),
                        child: const Text("🔮", style: TextStyle(fontSize: 24)),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(duration: 2.seconds),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("AI Oracle", style: AppTheme.headlineMedium),
                        Text(
                          controller.isTyping
                              ? "Typing..."
                              : "Online • Ready to assist",
                          style: TextStyle(
                            color: controller.isTyping
                                ? AppTheme.primaryCyan
                                : AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/dashboard'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            // Quick Suggestions
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                        onTap: () => _sendMessage(_suggestions[index]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.accentPurple.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            _suggestions[index],
                            style: TextStyle(
                              color: AppTheme.accentPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (100 * index).ms)
                      .slideX(begin: 0.2, end: 0);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length + (controller.isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && controller.isTyping) {
                    return _buildTypingIndicator();
                  }
                  final message = messages[index];
                  return _buildMessageBubble(message, index);
                },
              ),
            ),

            // Image Preview (if selected)
            if (_selectedImageBytes != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppTheme.cardColor.withOpacity(0.5),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedImageName ?? 'Image attached',
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => setState(() {
                        _selectedImageBytes = null;
                        _selectedImageName = null;
                      }),
                    ),
                  ],
                ),
              ),

            // Input Area
            GlassContainer(
              height: 80,
              width: double.infinity,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              borderColor: Colors.white.withOpacity(0.1),
              blur: 20,
              frostedOpacity: 0.1,
              color: AppTheme.cardColor.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Image Button
                    IconButton(
                      icon: Icon(
                        Icons.image_outlined,
                        color: _selectedImageBytes != null
                            ? AppTheme.primaryCyan
                            : AppTheme.textGrey,
                      ),
                      onPressed: _pickImage,
                    ),
                    // Voice Button
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : AppTheme.textGrey,
                      ),
                      onPressed: _toggleListening,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? "Listening..."
                              : "Ask the Oracle...",
                          hintStyle: TextStyle(
                            color: _isListening
                                ? Colors.red.shade200
                                : AppTheme.textGrey,
                          ),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(_controller.text),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryCyan,
                              AppTheme.accentPurple,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ).animate().scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
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

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [AppTheme.primaryCyan, Color(0xFF00A893)],
                    )
                  : LinearGradient(
                      colors: [
                        AppTheme.accentPurple.withOpacity(0.3),
                        AppTheme.cardColor,
                      ],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(16),
              ),
              border: isUser
                  ? null
                  : Border.all(color: AppTheme.accentPurple.withOpacity(0.3)),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: isUser ? 0.1 : -0.1, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppTheme.accentPurple.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _typingDot(0),
            const SizedBox(width: 4),
            _typingDot(100),
            const SizedBox(width: 4),
            _typingDot(200),
          ],
        ),
      ),
    );
  }

  Widget _typingDot(int delayMs) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.accentPurple,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(delay: delayMs.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 400.ms,
        );
  }
}
