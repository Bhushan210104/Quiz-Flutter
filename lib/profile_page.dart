import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'homepage.dart';
import 'leaderboard_page.dart';
import 'profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = "Loading...";
  final Random _random = Random();
  int _selectedIndex = 2; // Profile is selected by default

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(widget.userId).get();

      if (userSnapshot.exists) {
        setState(() {
          username = userSnapshot['username'] ?? "Unknown User";
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  String getRandomAvatar() {
    int randomNumber = _random.nextInt(50) + 1;
    return "https://avatar.iran.liara.run/public/$randomNumber";
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomePage();
        break;
      case 1:
        destination = const LeaderboardPage(category: "Science");
        break;
      case 2:
        return; // Already on Profile page
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade700,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 42),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Avatar
          CircleAvatar(
            radius: 70,
            backgroundImage: NetworkImage(getRandomAvatar()),
          ),
          const SizedBox(height: 20),
          // Username
          Text(
            username,
            style: const TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),

          // Badge Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Badges",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return buildBadge(index);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple, // Highlight selected item
        unselectedItemColor: Colors.grey, // Other items are grey
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: "Leaderboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // Badge Widget
  Widget buildBadge(int index) {
    List<String> badgeTitles = [
      "First Quiz",
      "5 Quizzes",
      "Full Score",
      "Consistent",
      "50 Quizzes",
      "Master"
    ];

    List<IconData> badgeIcons = [
      Icons.star,
      Icons.check_circle,
      Icons.emoji_events,
      Icons.timer,
      Icons.leaderboard,
      Icons.school
    ];

    bool isWon = index < 3; // Top 3 badges are won, others are pending

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isWon ? Colors.amber : Colors.grey.shade400,
          ),
          child: Icon(
            badgeIcons[index],
            size: 40,
            color: isWon ? Colors.white : Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badgeTitles[index],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isWon ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }
}
