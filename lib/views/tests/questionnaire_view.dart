import 'package:flutter/material.dart';

class QuestionnaireView extends StatelessWidget {
  final String title;
  const QuestionnaireView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Questionnaire for $title',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
