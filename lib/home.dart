import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quiz_screen.dart';

class MCQHome extends StatefulWidget {
  const MCQHome({super.key});

  @override
  MCQHomeState createState() => MCQHomeState();
}

class MCQHomeState extends State<MCQHome> {
  final List<Map<String, dynamic>> questions = [];
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _correctAnswerController =
      TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(3, (index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedQuestions = prefs.getStringList('questions');

    if (storedQuestions != null) {
      setState(() {
        questions.addAll(storedQuestions.map((q) {
          final parts = q.split('|');
          return {
            'question': parts[0],
            'correctAnswer': parts[1],
            'options': parts.sublist(2)
          };
        }));
      });
    }
  }

  void _saveQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> questionList = questions.map((q) {
      return '${q['question']}|${q['correctAnswer']}|${(q['options'] as List).join('|')}';
    }).toList();
    await prefs.setStringList('questions', questionList);
  }

  void _addQuestion() {
    final question = _questionController.text;
    final correctAnswer = _correctAnswerController.text;
    final options =
        _optionControllers.map((controller) => controller.text).toList();

    if (question.isNotEmpty &&
        correctAnswer.isNotEmpty &&
        options.every((opt) => opt.isNotEmpty)) {
      setState(() {
        questions.add({
          'question': question,
          'correctAnswer': correctAnswer,
          'options': [...options, correctAnswer]
        });
        _shuffleOptions(questions.last);
        _questionController.clear();
        _correctAnswerController.clear();
        for (var controller in _optionControllers) {
          controller.clear();
        }
      });
      _saveQuestions();
    }
  }

  void _shuffleOptions(Map<String, dynamic> question) {
    final options = question['options'] as List<String>;
    options.shuffle(Random());
  }

  void _startQuiz() {
    if (questions.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => QuizScreen(
                  questions: questions,
                  onDeleteQuestion: (index) {
                    setState(() {
                      questions.removeAt(index);
                    });
                    _saveQuestions();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Question deleted!')));
                  },
                )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add some questions first!')));
    }
  }

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              TextField(
                controller: _correctAnswerController,
                decoration: const InputDecoration(labelText: 'Correct Answer'),
              ),
              ..._optionControllers.map((controller) {
                return TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Option'),
                );
              }),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _addQuestion();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
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
        title: const Text('MCQ Quiz App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showAddQuestionDialog,
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _startQuiz,
          child: const Text('Start Quiz'),
        ),
      ),
    );
  }
}
