import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizzify/signin_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final TextEditingController _option3Controller = TextEditingController();
  final TextEditingController _option4Controller = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();

  String? selectedCategory;

  // Function to add a new category to Firestore
  Future<void> addCategory() async {
    String categoryName = _categoryController.text.trim();
    if (categoryName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('categories').add({
        'name': categoryName,
        'createdAt': Timestamp.now(),
      });
      _categoryController.clear();
    }
  }

  // Function to add a new question to Firestore
  Future<void> addQuestion() async {
    if (selectedCategory == null || _questionController.text.trim().isEmpty) {
      return;
    }

    List<String> options = [
      _option1Controller.text.trim(),
      _option2Controller.text.trim(),
      _option3Controller.text.trim(),
      _option4Controller.text.trim(),
    ];

    await FirebaseFirestore.instance
        .collection('categories')
        .doc(selectedCategory)
        .collection('questions')
        .add({
      'question': _questionController.text.trim(),
      'options': options,
      'correctAnswer': _correctAnswerController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    _questionController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    _correctAnswerController.clear();
  }

  Widget buildInputField(String hintText, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignInPage()),
            );
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add Quiz Category",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              buildInputField("Enter Category Name", _categoryController),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Add Category"),
              ),
              const SizedBox(height: 20),

              // Dropdown to select a category
              const Text(
                "Select Category to Add Questions",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  var categories = snapshot.data!.docs;
                  return DropdownButton<String>(
                    dropdownColor: Colors.deepPurple[400],
                    value: selectedCategory,
                    hint: const Text("Select Category",
                        style: TextStyle(color: Colors.white)),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                    items: categories.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['name'],
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Add Question Section
              const Text(
                "Add Questions",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              buildInputField("Enter Question", _questionController),
              const SizedBox(height: 10),

              // Options
              for (var controller in [
                _option1Controller,
                _option2Controller,
                _option3Controller,
                _option4Controller
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: buildInputField("Enter Option", controller),
                ),

              const SizedBox(height: 10),
              buildInputField("Enter Correct Answer", _correctAnswerController),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: addQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Add Question"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
