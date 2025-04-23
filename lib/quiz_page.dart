import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'result_page.dart';
import 'package:lottie/lottie.dart';

class QuizPage extends StatefulWidget {
  final String category;

  const QuizPage({Key? key, required this.category}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool isAnswered = false;
  int? selectedAnswerIndex;
  bool isCorrect = false;
  int timeLeft = 10;
  Timer? timer;
  Map<int, Map<String, dynamic>> userAnswers = {};
  late AnimationController _correctAnimController;
  late AnimationController _wrongAnimController;

  @override
  void initState() {
    super.initState();
    _correctAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _wrongAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    fetchQuestions();
  }

  @override
  void dispose() {
    timer?.cancel();
    _correctAnimController.dispose();
    _wrongAnimController.dispose();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0) {
            timeLeft--;
          } else {
            timer.cancel();
            if (!isAnswered) {
              // Time's up, mark as wrong answer
              handleAnswer(-1);
            }
          }
        });
      }
    });
  }

  Future<void> fetchQuestions() async {
    const apiKey = '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';
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant that generates quiz questions.'
            },
            {
              'role': 'user',
              'content':
                  'Generate 10 multiple-choice questions about ${widget.category}. For each question, provide exactly 4 answer options with exactly one correct answer. Format your response as a JSON array where each question is an object with the following structure: {"question": "Question text", "options": ["option1", "option2", "option3", "option4"], "correctIndex": X} where X is the zero-based index of the correct answer (0, 1, 2, or 3).'
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final content = responseBody['choices'][0]['message']['content'];

        // Extract JSON from the content
        final extractedJson = extractJsonFromText(content);
        if (extractedJson != null) {
          List<dynamic> parsedQuestions = jsonDecode(extractedJson);
          setState(() {
            questions = List<Map<String, dynamic>>.from(parsedQuestions);
            isLoading = false;
          });
          startTimer();
        } else {
          // Show error if JSON extraction failed
          print("Failed to extract JSON from API response");
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print("API Error: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String? extractJsonFromText(String text) {
    // Look for JSON array pattern
    final RegExp jsonPattern = RegExp(r'\[.*\]', dotAll: true);
    final match = jsonPattern.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  void handleAnswer(int index) {
    if (isAnswered) return;

    setState(() {
      isAnswered = true;
      selectedAnswerIndex = index;
      timer?.cancel();

      // Check if answer is correct
      if (index == questions[currentQuestionIndex]['correctIndex']) {
        isCorrect = true;
        score += 10;
        _correctAnimController.forward();
      } else {
        isCorrect = false;
        _wrongAnimController.forward();
      }

      // Store user's answer
      userAnswers[currentQuestionIndex] = {
        'question': questions[currentQuestionIndex]['question'],
        'options': questions[currentQuestionIndex]['options'],
        'correctIndex': questions[currentQuestionIndex]['correctIndex'],
        'selectedIndex': index,
        'isCorrect': index == questions[currentQuestionIndex]['correctIndex']
      };
    });

    // Move to next question after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      _correctAnimController.reset();
      _wrongAnimController.reset();

      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          isAnswered = false;
          selectedAnswerIndex = null;
          timeLeft = 10;
        });
        startTimer();
      } else {
        // Quiz finished, save score and navigate to results
        saveScoreToFirebase();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(
              score: score,
              totalQuestions: questions.length,
              userAnswers:
                  userAnswers.values.toList(), // ✅ Convert Map values to List
              category: widget.category,
            ),
          ),
        );
      }
    });
  }

  Future<void> saveScoreToFirebase() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get current timestamp
        final timestamp = FieldValue.serverTimestamp();

        // Save score to user's quiz history
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('quizHistory')
            .add({
          'category': widget.category,
          'score': score,
          'totalQuestions': questions.length,
          'timestamp': timestamp,
        });

        // Update or create leaderboard entry
        DocumentReference leaderboardRef = FirebaseFirestore.instance
            .collection('leaderboard')
            .doc(widget.category);

        FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(leaderboardRef);

          if (!snapshot.exists) {
            // Create new leaderboard for this category
            transaction.set(leaderboardRef, {
              'entries': [
                {
                  'userId': user.uid,
                  'username': await getUserName(user.uid),
                  'score': score,
                }
              ]
            });
          } else {
            // Update existing leaderboard
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            List<dynamic> entries = data['entries'] ?? [];

            // Check if user already has an entry
            int existingIndex =
                entries.indexWhere((entry) => entry['userId'] == user.uid);

            if (existingIndex != -1) {
              // Update if new score is higher
              if (entries[existingIndex]['score'] < score) {
                entries[existingIndex] = {
                  'userId': user.uid,
                  'username': await getUserName(user.uid),
                  'score': score,
                };
              }
            } else {
              // Add new entry
              entries.add({
                'userId': user.uid,
                'username': await getUserName(user.uid),
                'score': score,
              });
            }

            // Sort entries by score (descending)
            entries.sort((a, b) => b['score'].compareTo(a['score']));

            // Keep only top 100 entries
            if (entries.length > 100) {
              entries = entries.sublist(0, 100);
            }

            transaction.update(leaderboardRef, {'entries': entries});
          }
        });
      }
    } catch (e) {
      print("Error saving score: $e");
    }
  }

  Future<String> getUserName(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return userDoc['username'] ?? 'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 237, 241),
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 20),
                  Text(
                    "Preparing your quiz...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : questions.isEmpty
              ? const Center(
                  child: Text(
                    "Failed to load questions. Please try again.",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress bar
                        LinearProgressIndicator(
                          value: (currentQuestionIndex + 1) / questions.length,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 10),

                        // Question progress text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Question ${currentQuestionIndex + 1}/${questions.length}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.timer,
                                    color: Colors.deepPurple),
                                const SizedBox(width: 5),
                                Text(
                                  "$timeLeft sec",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: timeLeft <= 3
                                        ? Colors.red
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Timer progress
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: timeLeft / 10,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              timeLeft <= 3 ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Question text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            questions[currentQuestionIndex]['question'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Answer options
                        Expanded(
                          child: ListView.builder(
                            itemCount: questions[currentQuestionIndex]
                                    ['options']
                                .length,
                            itemBuilder: (context, index) {
                              bool isSelected = selectedAnswerIndex == index;
                              bool isCorrectAnswer =
                                  questions[currentQuestionIndex]
                                          ['correctIndex'] ==
                                      index;

                              // Determine the container color based on selection and correctness
                              Color borderColor = Colors.transparent;
                              Color bgColor = Colors.white;

                              if (isAnswered) {
                                if (isSelected) {
                                  borderColor =
                                      isCorrect ? Colors.green : Colors.red;
                                  bgColor = isCorrect
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1);
                                } else if (isCorrectAnswer && !isCorrect) {
                                  borderColor = Colors.green;
                                  bgColor = Colors.green.withOpacity(0.1);
                                }
                              }

                              return GestureDetector(
                                onTap: isAnswered
                                    ? null
                                    : () => handleAnswer(index),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          questions[currentQuestionIndex]
                                              ['options'][index],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),

                                      // Show icon if answered
                                      if (isAnswered &&
                                          (isSelected ||
                                              (isCorrectAnswer && !isCorrect)))
                                        isCorrectAnswer
                                            ? Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  const Icon(Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 28),
                                                  // if (isSelected && isCorrect)
                                                  //   SizedBox(
                                                  //     width: 40,
                                                  //     height: 40,
                                                  //     child: Lottie.network(
                                                  //       'https://assets6.lottiefiles.com/packages/lf20_touohxv0.json',
                                                  //       controller:
                                                  //           _correctAnimController,
                                                  //       fit: BoxFit.cover,
                                                  //     ),
                                                  //   ),
                                                ],
                                              )
                                            : Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  const Icon(Icons.cancel,
                                                      color: Colors.red,
                                                      size: 28),
                                                  // if (isSelected && !isCorrect)
                                                  //   SizedBox(
                                                  //     width: 40,
                                                  //     height: 40,
                                                  //     child: Lottie.network(
                                                  //       'https://assets5.lottiefiles.com/temp/lf20_QYm4n5.json',
                                                  //       controller:
                                                  //           _wrongAnimController,
                                                  //       fit: BoxFit.cover,
                                                  //     ),
                                                  //   ),
                                                ],
                                              ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Score display
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 8),
                              Text(
                                "Score: $score",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
