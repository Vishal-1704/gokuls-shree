import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

class QuestionManagerScreen extends StatelessWidget {
  final int paperSetId;
  final String paperTitle;
  
  const QuestionManagerScreen({
    super.key, 
    required this.paperSetId,
    required this.paperTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.inkNavy900,
      appBar: AppBar(
        title: Text('Questions: $paperTitle'),
        backgroundColor: AppColors.inkNavy800,
      ),
      body: const Center(
        child: Text('Question manager coming soon.', style: TextStyle(color: AppColors.textPrimary)),
      ),
    );
  }
}
