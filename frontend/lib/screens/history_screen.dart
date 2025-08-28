import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jawi_app/database/database.dart';
import 'package:jawi_app/database/profile.dart';
import 'package:intl/intl.dart';
import 'package:recase/recase.dart';

/// A screen that displays a list of saved detection results from the local database.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // A Future to hold the list of profiles fetched from the database.
  late Future<List<ProfileModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  /// Fetches all profiles from the database and updates the state.
  void loadHistory() {
    setState(() {
      _historyFuture = DatabaseHelper.getAllProfile();
    });
  }

  /// Deletes a specific item from the database by its [id].
  Future<void> _deleteItem(int id) async {
    await DatabaseHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item successfully deleted.'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ),
    );
    // Reload the history to reflect the deletion.
    loadHistory();
  }

  /// Shows a dialog with a larger preview of the saved item's image and description.
  void _showPreviewDialog(BuildContext context, ProfileModel item) {
    String formattedDate = "Time unknown";
    if (item.timestamp != null) {
      final dateTime = DateTime.parse(item.timestamp!);
      // Format the date and time for display.
      formattedDate = DateFormat(
        'dd MMM yyyy, HH:mm',
        'en_US',
      ).format(dateTime);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(item.name!.titleCase, textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(item.image64bit!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  item.description ?? "Description not available.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Saved on: $formattedDate",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DETECTION HISTORY',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      // RefreshIndicator allows the user to pull down to refresh the history list.
      body: RefreshIndicator(
        onRefresh: () async {
          loadHistory();
        },
        // FutureBuilder handles the asynchronous loading of history data.
        child: FutureBuilder<List<ProfileModel>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            // Show a loading spinner while data is being fetched.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Show a message if there is no history data.
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "History is still empty",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            // If data is available, display it in a ListView.
            final pList = snapshot.data!;
            // Sort the list to show the most recent items first.
            pList.sort(
              (a, b) => DateTime.parse(
                b.timestamp!,
              ).compareTo(DateTime.parse(a.timestamp!)),
            );

            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 8.0,
              ),
              itemCount: pList.length,
              itemBuilder: (context, index) {
                final item = pList[index];
                return _buildHistoryListItem(context, item);
              },
            );
          },
        ),
      ),
    );
  }

  /// Builds a single list item widget for the history screen.
  Widget _buildHistoryListItem(BuildContext context, ProfileModel item) {
    String formattedDate = "Time unknown";
    if (item.timestamp != null) {
      final dateTime = DateTime.parse(item.timestamp!);
      formattedDate = DateFormat(
        'dd MMM yyyy, HH:mm',
        'en_US',
      ).format(dateTime);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(item.image64bit!),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name!.titleCase,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Button to show the preview dialog.
            IconButton(
              icon: const Icon(
                Icons.remove_red_eye_outlined,
                color: Colors.blueAccent,
                size: 24,
              ),
              onPressed: () => _showPreviewDialog(context, item),
              tooltip: 'View Preview',
            ),
            // Button to show a confirmation dialog before deleting.
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 24,
              ),
              onPressed: () {
                _showConfirmDeleteDialog(context, item);
              },
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog to prevent accidental deletion.
  void _showConfirmDeleteDialog(BuildContext context, ProfileModel item) {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () => Navigator.pop(context),
    );
    Widget continueButton = TextButton(
      child: const Text("Delete", style: TextStyle(color: Colors.red)),
      onPressed: () {
        Navigator.pop(context);
        _deleteItem(item.id!);
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Confirm Deletion"),
      content: Text(
        "Are you sure you want to delete the item '${item.name?.titleCase}' from history?",
      ),
      actions: [cancelButton, continueButton],
    );
    showDialog(context: context, builder: (BuildContext context) => alert);
  }
}
