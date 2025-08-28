import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:jawi_app/screens/history_screen.dart';
import 'package:jawi_app/screens/home_screen.dart';
import 'package:jawi_app/screens/chat_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

// The main entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for the 'en_US' locale to ensure consistent date displays.
  await initializeDateFormatting('en_US', null);

  // Run the root widget of the application.
  runApp(const MyApp());
}

// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The title of the application, used by the OS.
      title: 'JawiAI',

      // Defines the overall theme of the application.
      theme: ThemeData(
        primarySwatch: Colors.green, // Sets the primary color swatch.
        scaffoldBackgroundColor:
            Colors
                .grey[100], // Sets the default background color for Scaffolds.
        fontFamily: 'Poppins', // Sets the default font for the app.
      ),

      // The main screen that holds the bottom navigation.
      home: const MainNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// A stateful widget that manages the main navigation structure with a bottom bar.
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  // Controller to manage the pages in the PageView. Starts at index 1 (HomeScreen).
  final _pageController = PageController(initialPage: 1);

  // Controller for the animated notch bottom bar. Starts at index 1 to match the PageController.
  final _notchBottomBarController = NotchBottomBarController(index: 1);

  @override
  Widget build(BuildContext context) {
    // A list of the widgets to be displayed as pages.
    final List<Widget> pages = [
      const ChatScreen(),
      const HomeScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        // Disables swiping between pages; navigation is controlled only by the bottom bar.
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),

      // Allows the body to be drawn behind the bottom navigation bar.
      extendBody: true,

      // The custom animated bottom navigation bar.
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _notchBottomBarController,
        color: Colors.white,
        showLabel: true,
        itemLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        shadowElevation: 5,
        kBottomRadius: 28.0,
        notchColor: Colors.green,

        // Defines the items in the bottom navigation bar.
        bottomBarItems: const [
          // Chat AI screen navigation item.
          BottomBarItem(
            inActiveItem: Icon(
              Icons.chat_bubble_outline,
              color: Colors.blueGrey,
            ),
            activeItem: Icon(Icons.chat_bubble, color: Colors.white),
            itemLabel: 'Chat AI',
          ),

          // Home/Detect screen navigation item.
          BottomBarItem(
            inActiveItem: Icon(
              Icons.camera_alt_outlined,
              color: Colors.blueGrey,
            ),
            activeItem: Icon(Icons.camera_alt, color: Colors.white),
            itemLabel: 'Detect',
          ),

          // History screen navigation item.
          BottomBarItem(
            inActiveItem: Icon(Icons.history_outlined, color: Colors.blueGrey),
            activeItem: Icon(Icons.history, color: Colors.white),
            itemLabel: 'History',
          ),
        ],

        // Callback function that is triggered when a bottom bar item is tapped.
        onTap: (index) {
          // Jumps to the corresponding page without an animation.
          _pageController.jumpToPage(index);
        },
        kIconSize: 24.0, // The size of the icons in the bottom bar.
      ),
    );
  }

  // Clean up the controller when the widget is removed from the widget tree.
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
