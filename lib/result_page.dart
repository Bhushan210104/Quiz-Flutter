import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>> userAnswers;
  final String category;

  const ResultPage({
    Key? key,
    required this.score,
    required this.totalQuestions,
    required this.userAnswers,
    required this.category,
  }) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoadingLeaderboard = true;
  List<Map<String, dynamic>> leaderboard = [];

  @override
  void initState() {
    super.initState();
    fetchleaderboard();
  }

  Future<void> fetchleaderboard() async {
    try {
      final DocumentSnapshot snapshot = await _firestore
          .collection('leaderboard')
          .doc(widget.category) // Access document named after category
          .get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() as Map<String, dynamic>;
        List<dynamic> entries = data['entries'] ?? [];

        // Sort entries by score in descending order and limit to top 5
        entries
            .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
        entries = entries.take(5).toList();

        setState(() {
          leaderboard = List<Map<String, dynamic>>.from(entries);
          isLoadingLeaderboard = false;
        });
      } else {
        setState(() {
          leaderboard = [];
          isLoadingLeaderboard = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingLeaderboard = false;
      });
      print('Error fetching leaderboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage score
    final percentage = (widget.score / (widget.totalQuestions * 10)) * 100;
    final formattedPercentage = percentage.toStringAsFixed(0);

    // Count correct and incorrect answers
    final correctAnswers =
        widget.userAnswers.where((answer) => answer['isCorrect']).length;
    final incorrectAnswers = widget.totalQuestions - correctAnswers;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quiz Results',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color.fromARGB(255, 237, 237, 241),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Score section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Result animation (Trophy or similar)
                      percentage >= 60
                          ? Lottie.network(
                              'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json',
                              height: 180,
                              repeat: true,
                            )
                          : Lottie.network(
                              'https://assets1.lottiefiles.com/private_files/lf30_LOw4AL.json',
                              height: 180,
                              repeat: true,
                            ),

                      // Score display
                      Text(
                        'You Scored',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.score.toString(),
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '/${widget.totalQuestions * 10}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$formattedPercentage%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Statistics
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Correct answers stat
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.green.shade100),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    correctAnswers.toString(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Correct',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Incorrect answers stat
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade100),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    incorrectAnswers.toString(),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Incorrect',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Category leaderboard
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Leaderboard Title
                      Row(
                        children: [
                          const Icon(
                            Icons.leaderboard,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.category} Leaderboard',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Loading Indicator
                      if (isLoadingLeaderboard)
                        const CircularProgressIndicator()
                      // No Data Message
                      else if (leaderboard.isEmpty)
                        const Text('No leaderboard data yet')
                      // Display Leaderboard Entries
                      else
                        Column(
                          children: List.generate(
                            leaderboard.length,
                            (index) {
                              final data = leaderboard[index];
                              final username = data['username'] ?? 'User';
                              final score = data['score'] ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? Colors.amber.shade100
                                      : index == 1
                                          ? Colors.grey.shade200
                                          : index == 2
                                              ? Colors.brown.shade100
                                              : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: index == 0
                                        ? Colors.amber
                                        : index == 1
                                            ? Colors.grey.shade400
                                            : index == 2
                                                ? Colors.brown.shade300
                                                : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Rank Number
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: index == 0
                                            ? Colors.amber
                                            : index == 1
                                                ? Colors.grey.shade400
                                                : index == 2
                                                    ? Colors.brown.shade300
                                                    : Colors
                                                        .deepPurple.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: index <= 2
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Username
                                    Expanded(
                                      child: Text(
                                        username,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    // Score
                                    Text(
                                      '$score pts',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Questions Summary section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Question Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(
                        widget.userAnswers.length,
                        (index) {
                          final answer = widget.userAnswers[index];
                          final isCorrect = answer['isCorrect'];
                          final question = answer['question'];
                          final userAnswer =
                              answer['userAnswer'] ?? 'No answer';
                          final correctAnswer = answer['correctAnswer'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCorrect ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Q${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isCorrect ? 'Correct!' : 'Incorrect',
                                        style: TextStyle(
                                          color: isCorrect
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color:
                                          isCorrect ? Colors.green : Colors.red,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  question,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (!isCorrect)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Your answer: $userAnswer',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Correct answer: $correctAnswer',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Your answer: $userAnswer',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions buttons
                Row(
                  children: [
                    // Try Again Button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade100,
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Go back to quiz page
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Home Button
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomePage()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
