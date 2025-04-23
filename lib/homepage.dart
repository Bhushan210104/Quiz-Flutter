import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'leaderboard_page.dart';
// import 'signin_page.dart';
import 'login.dart';
import 'quiz_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = "User";
  String profilePicUrl =
      "https://avatar.iran.liara.run/public"; // Random avatar placeholder
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  final List<Color> categoryColors = [
    Colors.greenAccent.shade100,
    Colors.blueAccent.shade100,
    Colors.purpleAccent.shade100,
    Colors.orangeAccent.shade100,
    Colors.redAccent.shade100,
  ];

  final List<IconData> categoryIcons = [
    Icons.menu_book,
    Icons.tv,
    Icons.fastfood,
    Icons.science,
    Icons.account_balance,
    Icons.category,
    Icons.sports_esports,
    Icons.music_note,
    Icons.flight,
    Icons.computer,
  ];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'];
          int randomNumber =
              Random().nextInt(50) + 1; // Generate a number between 1-50
          profilePicUrl =
              "https://avatar.iran.liara.run/public/$randomNumber"; // Random avatar
        });
      }
    }
  }

  Stream<QuerySnapshot> fetchCategories() {
    return FirebaseFirestore.instance.collection('categories').snapshots();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    User? user = _auth.currentUser; // Get the current user

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const LeaderboardPage(category: 'Science')),
        );
        break;
      case 2:
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ProfilePage(userId: user.uid)), // Pass user ID
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 237, 241),
      appBar: AppBar(
        title: const Text(
          "QUIZZIFY",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Good Morning Section with Background Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100, // Background color
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "GOOD MORNING",
                          style: TextStyle(
                              fontSize: 22, // Increased font size
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                        Text(
                          username,
                          style: const TextStyle(
                              fontSize: 34, // Increased font size
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ],
                    ),
                    // Profile Picture
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(profilePicUrl),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quiz Categories Section
              const Text(
                "Quiz Categories",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: fetchCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var categories = snapshot.data!.docs;
                    return Scrollbar(
                      thickness: 6,
                      radius: const Radius.circular(10),
                      child: SingleChildScrollView(
                        child: Column(
                          children: List.generate(categories.length, (index) {
                            var data = categories[index].data()
                                as Map<String, dynamic>;
                            Color boxColor =
                                categoryColors[index % categoryColors.length];
                            IconData icon =
                                categoryIcons[index % categoryIcons.length];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QuizPage(category: data['name']),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 25),
                                decoration: BoxDecoration(
                                  color: boxColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(2, 2)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        icon,
                                        color: Colors.black87,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        data['name'],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard), label: "Leaderboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
