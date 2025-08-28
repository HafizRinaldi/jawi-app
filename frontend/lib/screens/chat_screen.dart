import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:bubble/bubble.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jawi_app/services/chat_api_service.dart';
import 'package:uuid/uuid.dart';

/// A screen that provides a chat interface for users to interact with the JawiAI assistant.
class ChatScreen extends StatefulWidget {
  // An optional context (e.g., a letter name) passed from the HomeScreen to start the conversation.
  final String? initialContext;
  const ChatScreen({super.key, this.initialContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // State Variables
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _bot = const types.User(id: 'bot', firstName: 'JawiAI');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Display a welcoming message when the chat screen is first opened.
    _addInitialMessage();
  }

  /// Creates and adds the initial greeting message from the bot.
  void _addInitialMessage() {
    String greetingText;
    // Customize the greeting if an initial context is provided.
    if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
      greetingText =
          "Assalamualaikum! I am JawiAI. How can I help you with the Jawi script, or more specifically about the letter '${widget.initialContext}'?";
    } else {
      greetingText =
          "Assalamualaikum! I am JawiAI. How can I help you with the Jawi script?";
    }
    _addMessage(
      types.TextMessage(
        author: _bot,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: greetingText,
      ),
      // This metadata is used to exclude the greeting from the conversation history sent to the API.
      meta: {'is_initial_greeting': true},
    );
  }

  /// A helper function to add a new message to the top of the message list.
  void _addMessage(types.Message message, {Map<String, dynamic>? meta}) {
    final messageWithMeta = message.copyWith(metadata: meta);
    setState(() {
      _messages.insert(0, messageWithMeta);
    });
  }

  /// Handles the logic when the user presses the send button.
  void _handleSendPressed(types.PartialText message) async {
    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );
    _addMessage(userMessage);
    setState(() {
      _isLoading = true; // Show a typing indicator.
    });

    // Prepare the last 6 messages as conversation history to send to the backend.
    // This gives the AI memory of the recent conversation.
    final history =
        _messages
            .where(
              (m) =>
                  m is types.TextMessage &&
                  (m.metadata?['is_initial_greeting'] != true),
            )
            .take(6)
            .map((m) {
              final textMessage = m as types.TextMessage;
              final role = (m.author.id == _bot.id) ? 'assistant' : 'user';
              return {'role': role, 'content': textMessage.text};
            })
            .toList()
            .reversed
            .toList();

    // A list of keywords that trigger the creative/generative AI mode.
    const creativeKeywords = [
      'make',
      'create',
      'give another example',
      'new word example',
      'translate',
    ];
    final isCreativeQuery = creativeKeywords.any(
      (keyword) => message.text.toLowerCase().contains(keyword),
    );

    // Decide which API endpoint to call based on the presence of creative keywords.
    String botResponse;
    if (isCreativeQuery) {
      botResponse = await ChatApiService.getCreativeResponse(message.text);
    } else {
      botResponse = await ChatApiService.getChatResponse(
        message.text,
        context: widget.initialContext,
        history: history,
      );
    }

    // Add the bot's response to the message list.
    final botMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: botResponse,
    );
    _addMessage(botMessage);
    setState(() {
      _isLoading = false; // Hide the typing indicator.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ask JawiAI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _user,
        showUserAvatars: false,
        showUserNames: true,
        typingIndicatorOptions: TypingIndicatorOptions(
          typingUsers: _isLoading ? [_bot] : [],
        ),
        // Custom builder for chat messages to support Markdown and a copy button.
        textMessageBuilder: (
          types.TextMessage message, {
          required int messageWidth,
          required bool showName,
        }) {
          if (message.author.id == _bot.id) {
            // Custom layout for bot messages.
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage('assets/images/logo_jawi.png'),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Bubble(
                            nip: BubbleNip.leftTop,
                            color: const Color(0xfff5f5f7),
                            // Use MarkdownBody to correctly render bold/italic text from the AI.
                            child: MarkdownBody(
                              data: message.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // A button to copy the bot's response to the clipboard.
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.copy_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: message.text),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Text copied successfully!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: 'Copy text',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          // Default layout for user messages.
          return Bubble(
            nip: BubbleNip.rightTop,
            color: Colors.green,
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        theme: DefaultChatTheme(
          primaryColor: Colors.green,
          inputBackgroundColor: Colors.grey.shade100,
          inputTextColor: Colors.black87,
          sendButtonIcon: const Icon(Icons.send, color: Colors.green),
        ),
      ),
    );
  }
}
