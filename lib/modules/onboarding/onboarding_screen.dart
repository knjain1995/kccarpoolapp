import 'package:flutter/material.dart';
import 'package:kccarpoolapp/core/routes.dart';
import 'package:kccarpoolapp/modules/auth/screens/login_screen.dart'; // Import Login screen

/// OnboardingScreen is the first screen shown to users when they open the app.
/// It introduces the app's features in a multi-page view format with swipe gestures.
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// PageController manages page navigation for onboarding screens.
  final PageController _pageController = PageController();
  int currentIndex = 0; // Tracks the current onboarding page index.

  /// List containing the title and description of each onboarding page.
  final List<Map<String, String>> onboardingData = [
    {"title": "Trusted Carpooling", "description": "Learn how our secure carpooling system works."},
    {"title": "Verified Users", "description": "We ensure safety by verifying every participant."},
    {"title": "Easy Scheduling", "description": "Set up and join carpools with just a few taps."},
    {"title": "Get Started!", "description": "Sign up now to start your trusted carpool journey."},
  ];

  /// Moves to the next onboarding screen or finishes onboarding.
  void nextPage() {
    if (currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500), // Smooth transition duration.
        curve: Curves.easeInOut, // Animation style.
      );
    } else {
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to Login screen
      // );
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// Main content: PageView to allow swiping between onboarding screens.
          Expanded(
            flex: 4, // Takes up most of the screen height.
            child: PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index; // Update progress indicator.
                });
              },
              itemBuilder: (context, index) => OnboardingPage(
                title: onboardingData[index]["title"]!,
                description: onboardingData[index]["description"]!,
              ),
            ),
          ),
          
          /// Row displaying progress dots to indicate current onboarding step.
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
              (index) => buildDot(index),
            ),
          ),
          SizedBox(height: 20),
          
          /// Navigation button to proceed to the next onboarding screen.
          ElevatedButton(
            onPressed: nextPage,
            child: Text(currentIndex < onboardingData.length - 1 ? "Next" : "Get Started"),
          ),
          
          if (currentIndex == onboardingData.length - 1) ...[
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement navigation to learn more screen.
                print("Navigate to Learn More screen (to be implemented)");
              },
              child: Text("Learn More"),
            ),
          ],
          
          SizedBox(height: 20),
          
          /// Login button, allowing users to skip onboarding and go to login screen.
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text("Already have an account? Login"),
          ),
          
          SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Builds the animated progress indicator dots below onboarding pages.
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: currentIndex == index ? 16 : 8,
      decoration: BoxDecoration(
        color: currentIndex == index ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// OnboardingPage represents each screen in the onboarding flow.
class OnboardingPage extends StatelessWidget {
  final String title, description;

  const OnboardingPage({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// The top section of each onboarding screen, displaying the title.
          Text(
            title,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.08, // Responsive font size
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 20),
          
          /// The lower section containing text description.
          Text(
            description,
            style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.05, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
