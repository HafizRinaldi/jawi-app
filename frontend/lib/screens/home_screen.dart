import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jawi_app/services/onnx_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jawi_app/database/database.dart';
import 'package:jawi_app/database/profile.dart';
import 'package:jawi_app/screens/chat_screen.dart';
import 'package:jawi_app/screens/help_screen.dart';
import 'package:jawi_app/services/chat_api_service.dart';

/// A data class to hold the result of an image prediction.
class PredictionResult {
  final File imageFile;
  final String label;
  final String base64Image;

  PredictionResult({
    required this.imageFile,
    required this.label,
    required this.base64Image,
  });
}

/// The main screen of the application for Jawi letter detection.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // State Variables
  bool _isProcessing = false;
  PredictionResult? _predictionResult;
  String? _llmDescription;
  String _processingStatus = "";

  // Creates an instance of the ONNX service to handle all inference logic.
  final OnnxService _onnxService = OnnxService();

  @override
  void initState() {
    super.initState();
    // Initialize the ONNX model once when the screen is first loaded for efficiency.
    _onnxService.initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Opens the image picker to select an image from the [source] (Camera or Gallery).
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image != null) {
      _processImage(image);
    }
  }

  /// The main logic flow for processing a selected image.
  /// This function orchestrates the on-device inference and the cloud LLM call.
  Future<void> _processImage(XFile image) async {
    // Update UI to show the initial processing state.
    setState(() {
      _isProcessing = true;
      _predictionResult = null;
      _llmDescription = null;
      _processingStatus = "Detecting letter...";
    });

    try {
      final imageBytes = await image.readAsBytes();

      // Step 1: Run on-device inference using the ONNX service.
      final topPrediction = await _onnxService.runInference(imageBytes);

      final result = PredictionResult(
        imageFile: File(image.path),
        label: topPrediction,
        base64Image: base64Encode(imageBytes),
      );

      // Update UI to show the prediction and start fetching the description.
      setState(() {
        _processingStatus = "Requesting explanation from JawiAI...";
        _predictionResult = result;
      });

      // Step 2: Call the backend API to get a description from the LLM.
      if (topPrediction != 'Unrecognized') {
        final prompt =
            "Explain briefly and clearly in one paragraph about the Jawi letter: ${topPrediction}";
        final description = await ChatApiService.getChatResponse(prompt);
        setState(() => _llmDescription = description);
      } else {
        setState(
          () => _llmDescription =
              "This letter was not recognized. Please try again with a clearer image.",
        );
      }
    } catch (e) {
      // Show an error message if anything goes wrong.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Ensure the processing indicator is turned off, even if there's an error.
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // UI Widget Builders

  /// Builds the view that displays after a prediction is made.
  Widget _buildResultView(PredictionResult result) {
    // Helper function to save the current result to the database.
    Future<void> _saveToHistory(BuildContext context) async {
      if (_llmDescription == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the description to finish loading.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final profile = ProfileModel(
        name: result.label,
        image64bit: result.base64Image,
        timestamp: DateTime.now().toIso8601String(),
        description: _llmDescription,
      );
      await DatabaseHelper.insertProfile(profile.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Result and description saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(result.imageFile, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    result.label,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Colors.grey),
                  ),
                  // Shows a loading indicator while fetching the description.
                  _llmDescription == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Loading explanation...",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          _llmDescription!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // A button to start a chat session about the detected letter.
          if (result.label != "Unrecognized")
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(initialContext: result.label),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
              label: Text(
                'Ask AI about "${result.label}"',
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // A button to save the result to the history database.
          ElevatedButton.icon(
            onPressed: () => _saveToHistory(context),
            icon: const Icon(Icons.save_alt, color: Colors.white),
            label: const Text(
              'Save to History',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // A button to reset the view and perform another detection.
          ElevatedButton.icon(
            onPressed: () => setState(() => _predictionResult = null),
            icon: const Icon(Icons.refresh, color: Colors.black),
            label: const Text(
              'Detect Again',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a tappable card that navigates to the Help screen.
  Widget _buildHowToUseCard(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: Colors.green.shade800,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How to Use JawiAI",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap here to see the full guide and learn about the AI.",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A helper widget for displaying a row in the "Technology Used" card.
  Widget _buildTechnologyRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the initial view shown to the user before an image is selected.
  Widget _buildInitialAndInteractiveView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //nst SizedBox(height: 24),
          Icon(Icons.auto_awesome, size: 50, color: Colors.green.shade700),
          const SizedBox(height: 16),
          Text(
            "Welcome to JawiAI!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "An application specialized in detecting 22 Jawi letterforms.",
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          _buildHowToUseCard(context),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Technology Used:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildTechnologyRow(
                  Icons.camera_alt_outlined,
                  "Image Detection (On-Device)",
                  "Model: MobileNetV3 (ONNX Format)",
                ),
                const Divider(height: 16),
                _buildTechnologyRow(
                  Icons.cloud_queue_outlined,
                  "AI Assistant & Chat (Cloud)",
                  "Model: Qwen3-4B Instruct",
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Made by M Hafiz Rinaldi",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JAWI DETECTION',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Colors.green),
        ),
      ),
      body: SafeArea(
        // AnimatedSwitcher provides a smooth transition between the initial view and the result view.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isProcessing
              ? Center(
                  key: const ValueKey('processing'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 20),
                      Text(
                        _processingStatus,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please wait a moment...",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : _predictionResult != null
              ? _buildResultView(_predictionResult!)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    key: const ValueKey('initial'),
                    children: [
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: _buildInitialAndInteractiveView(),
                          ),
                        ),
                      ),
                      // Contains the main action buttons for the user.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Take a Picture',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(
                                Icons.image,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Choose from Gallery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
