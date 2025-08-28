import 'package:flutter/material.dart';

/// A screen that provides helpful information about the application.
/// It explains the app's purpose, the AI models used, and how to use the features.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & About',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About The Application Section
            _buildSectionCard(
              context,
              icon: Icons.info_outline,
              title: 'About The Application',
              content:
                  "JawiAI is a specialized application designed to detect 22 Jawi letterforms. The app utilizes two different AI models to provide a comprehensive experience: an on-device model for image recognition and a cloud-based Large Language Model (LLM) for chat. The front-end application and the Python backend server were independently designed and built by M Hafiz Rinaldi.",
            ),
            // About The Detection Scope
            _buildSectionCard(
              context,
              icon: Icons.checklist_rtl,
              title: 'Detection Scope',
              contentWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "The on-device model is specifically trained to recognize 22 forms of the 6 additional Jawi letters:",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _buildLetterDetailRow(
                    context,
                    "Ca (چ)",
                    "Isolated, Initial, Medial, Final",
                  ),
                  _buildLetterDetailRow(
                    context,
                    "Ga (ݢ)",
                    "Isolated, Initial, Medial, Final",
                  ),
                  _buildLetterDetailRow(
                    context,
                    "Nga (ڠ)",
                    "Isolated, Initial, Medial, Final",
                  ),
                  _buildLetterDetailRow(
                    context,
                    "Nya (ڽ)",
                    "Isolated, Initial, Medial, Final",
                  ),
                  _buildLetterDetailRow(
                    context,
                    "Pa (ڤ)",
                    "Isolated, Initial, Medial, Final",
                  ),
                  _buildLetterDetailRow(context, "Va (ۏ)", "Isolated, Final"),
                ],
              ),
            ),

            // About The AI Models Section
            _buildSectionCard(
              context,
              icon: Icons.auto_awesome,
              title: 'About The AI Models',
              contentWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  _buildStep(
                    'Image Detection Model',
                    'The application uses the **MobileNetV3 in ONNX format) for fast and accurate letter recognition directly on your device. This process does not require an internet connection.',
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    'Large Language Model (LLM)',
                    'All explanations and chat features are powered by the **Qwen3-4B-Instruct** model. This is a powerful language model that provides contextual and creative responses.',
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    'The Purpose of RAG (Fact-Based AI)',
                    "To ensure accuracy, the AI uses a technique called Retrieval-Augmented Generation (RAG). The AI first retrieves relevant facts from its built-in knowledge base. It then uses only these facts to construct its answer. This 'grounding' process prevents the AI from making up information.",
                  ),
                  const SizedBox(height: 16),
                  _buildStep(
                    'How the AI Switches Modes',
                    'The AI operates in different modes to best handle your questions:',
                  ),
                  const SizedBox(height: 8),
                  _buildSubStep(
                    'Factual Mode (Default):',
                    'This is the primary mode. The AI uses RAG to provide accurate, fact-based answers about Jawi.',
                  ),
                  _buildSubStep(
                    'Creative Mode:',
                    "If your message contains keywords like 'create' or 'translate', the AI switches to a generative mode to create new examples or content for you.",
                  ),
                  _buildSubStep(
                    'Smart Suggestions:',
                    "If you ask for more examples and the AI runs out of facts, it will offer to switch to Creative Mode to generate a new one for you.",
                  ),
                ],
              ),
            ),
            // How to Use Section
            _buildSectionCard(
              context,
              icon: Icons.integration_instructions_outlined,
              title: 'How to Use the App',
              contentWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep(
                    '1. Detect a Letter',
                    'On the main screen, use "Take a Picture" to scan a Jawi letter, or "Choose from Gallery" to select an existing image.',
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    '2. View the Result',
                    'The app will display the detected letter and a brief, AI-generated description.',
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    '3. Chat with the AI',
                    'Press the "Ask AI about..." button to open the chat screen and ask more detailed questions.',
                  ),
                  const SizedBox(height: 12),
                  _buildStep(
                    '4. Save & View History',
                    'You can save detection results. Access all saved items from the "History" tab on the bottom navigation bar.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A helper widget to display a row for letter detection scope.
  Widget _buildLetterDetailRow(
    BuildContext context,
    String letter,
    String forms,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: TextStyle(color: Colors.grey.shade700)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
                children: [
                  TextSpan(
                    text: '$letter: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: forms,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A helper widget to create a consistent card layout for each section.
  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? content,
    Widget? contentWidget,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            contentWidget ??
                Text(
                  content ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
          ],
        ),
      ),
    );
  }

  /// A helper widget to format a step with a title and subtitle.
  Widget _buildStep(String title, String subtitle) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontFamily: 'Poppins',
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: subtitle),
        ],
      ),
    );
  }

  /// A helper widget for formatting a sub-step, indented with a bullet point.
  Widget _buildSubStep(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: subtitle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
