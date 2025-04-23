import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'homepage.dart';
import 'profile_page.dart';

class LeaderboardPage extends StatefulWidget {
  final String category;

  const LeaderboardPage({Key? key, required this.category}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> leaderboard = [];
  bool isLoading = true;
  final Random _random = Random();
  int _selectedIndex = 1; // Default selected tab is Leaderboard

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('leaderboard').doc(widget.category).get();

      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        List<dynamic> entries = data?['entries'] ?? [];

        List<Map<String, dynamic>> leaderboardData = [];

        for (var entry in entries) {
          String userId = entry['userId'];
          int score = entry['score'];

          DocumentSnapshot userSnapshot =
              await _firestore.collection('users').doc(userId).get();

          if (userSnapshot.exists) {
            Map<String, dynamic>? userData =
                userSnapshot.data() as Map<String, dynamic>?;

            leaderboardData.add({
              'username': userData?['username'] ?? "Unknown",
              'score': score,
            });
          }
        }

        leaderboardData
            .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

        setState(() {
          leaderboard = leaderboardData;
          isLoading = false;
        });
      } else {
        setState(() {
          leaderboard = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching leaderboard: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String getRandomAvatar(int index) {
    int randomNumber = _random.nextInt(50) + 1;
    return "https://avatar.iran.liara.run/public/$randomNumber";
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 2 && userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade700,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Leaderboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : leaderboard.isEmpty
              ? const Center(
                  child: Text(
                    "No leaderboard data yet",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : Column(
                  children: [
                    buildPodium(),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30)),
                        ),
                        child: ListView.builder(
                          itemCount: leaderboard.length,
                          itemBuilder: (context, index) {
                            return buildLeaderboardEntry(
                                leaderboard[index], index + 1);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
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

  Widget buildPodium() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (leaderboard.length > 1) buildAnimatedPodium(1, 2),
          if (leaderboard.isNotEmpty) buildAnimatedPodium(0, 1, isTop: true),
          if (leaderboard.length > 2) buildAnimatedPodium(2, 3),
        ],
      ),
    );
  }

  Widget buildAnimatedPodium(int index, int rank, {bool isTop = false}) {
    if (index >= leaderboard.length) return const SizedBox.shrink();

    final user = leaderboard[index];

    // Define rank colors
    Color rankColor = (rank == 1)
        ? Colors.yellow.shade700 // Gold
        : (rank == 2)
            ? Colors.grey.shade400 // Silver
            : Colors.brown.shade600; // Bronze

    return Column(
      children: [
        CircleAvatar(
          radius: isTop ? 65 : 55,
          backgroundImage: NetworkImage(getRandomAvatar(index)),
        ),
        const SizedBox(height: 12),
        Text(
          user['username'] ?? "User",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        Text(
          "${user['score']} POINTS",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: rankColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            rank.toString(),
            style: const TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLeaderboardEntry(Map<String, dynamic> user, int rank) {
    // Define rank colors for the list
    Color rankColor = (rank == 1)
        ? const Color.fromARGB(255, 248, 184, 20) // Gold
        : (rank == 2)
            ? const Color.fromARGB(255, 183, 180, 180)
            // Silver
            : (rank == 3)
                ? const Color.fromARGB(255, 234, 99, 50)
                // Bronze
                : const Color.fromARGB(0, 243, 2, 2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: rankColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(getRandomAvatar(rank)),
        ),
        title: Text(
          user['username'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Text("Rank: $rank"),
        trailing: Text(
          "${user['score']} Points",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
