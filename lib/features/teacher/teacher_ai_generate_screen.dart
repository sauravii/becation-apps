import "package:flutter/material.dart";
import "package:cloud_functions/cloud_functions.dart";

import "teacher_create_question_screen.dart";

class TeacherAiGenerateScreen extends StatefulWidget {
  const TeacherAiGenerateScreen({super.key});

  @override
  State<TeacherAiGenerateScreen> createState() =>
      _TeacherAiGenerateScreenState();
}

class _TeacherAiGenerateScreenState extends State<TeacherAiGenerateScreen> {
  static const _purple = Color(0xFF6F5AAA);
  static const _bg = Color(0xFFF7F2FA);
  static const _label = Color(0xFF49454E);
  static const _hint = Color(0xFF9A9499);
  static const _ink = Color(0xFF1C1B20);

  final _promptController = TextEditingController();
  int _questionCount = 5;
  int _optionsCount = 4;
  bool _isLoading = false;

  final List<String> _examples = [
    "Linear Algebra dasar untuk Semester 1",
    "Sejarah Kemerdekaan Indonesia tingkat SMA",
    "Pemrograman Dasar Python: Loop & Function",
    "Ekonomi Mikro: Hukum Permintaan & Penawaran",
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tuliskan topik kuis terlebih dahulu")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable("generateQuizAI")
          .call({
            "prompt": prompt,
            "count": _questionCount,
            "optionsCount": _optionsCount,
          });

      if (!mounted) return;

      final List<dynamic> rawList = result.data["data"];

      final List<PendingQuestion> generatedQuestions = rawList.map((item) {
        return PendingQuestion(
          type: "Multiple Choice",
          question: item["question"],
          options: List<String>.from(item["options"]),
          correctIndex: item["correctIndex"],
        );
      }).toList();

      Navigator.of(context).pop(generatedQuestions);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal generate kuis: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AI Quiz Generator",
          style: TextStyle(color: _ink, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Berapa banyak soal yang ingin dibuat?",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _label,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuestionCountSelector(),
                const SizedBox(height: 24),
                const Text(
                  "Jumlah pilihan jawaban per soal",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _label,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOptionsCountSelector(),
                const SizedBox(height: 24),
                const Text(
                  "Topik atau instruksi kuis",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _label,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPromptField(),
                const SizedBox(height: 20),
                const Text(
                  "Contoh prompt:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _hint,
                  ),
                ),
                const SizedBox(height: 8),
                _buildExamples(),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Generate Quiz",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCountSelector() {
    final counts = [5, 10, 15, 20];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: counts.map((c) {
        final isSelected = _questionCount == c;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _questionCount = c),
            child: Container(
              margin: EdgeInsets.only(
                left: c == counts.first ? 0 : 4,
                right: c == counts.last ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _purple : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _purple : const Color(0xFFEAE3F2),
                ),
              ),
              child: Center(
                child: Text(
                  "$c",
                  style: TextStyle(
                    color: isSelected ? Colors.white : _ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionsCountSelector() {
    final counts = [2, 3, 4, 5];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: counts.map((c) {
        final isSelected = _optionsCount == c;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _optionsCount = c),
            child: Container(
              margin: EdgeInsets.only(
                left: c == counts.first ? 0 : 4,
                right: c == counts.last ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? _purple : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _purple : const Color(0xFFEAE3F2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$c",
                    style: TextStyle(
                      color: isSelected ? Colors.white : _ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (c == 2)
                    Text(
                      "T/F",
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : _hint,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPromptField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE3F2)),
      ),
      child: TextField(
        controller: _promptController,
        maxLines: 5,
        maxLength: 200,
        style: const TextStyle(fontSize: 15, color: _ink),
        decoration: InputDecoration(
          hintText:
              "Misal: Buatkan soal tentang Teori Relativitas tingkat kesulitan menengah...",
          hintStyle: const TextStyle(color: _hint),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          counterStyle: TextStyle(color: _hint.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildExamples() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _examples.map((ex) {
        return InkWell(
          onTap: () => setState(() => _promptController.text = ex),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE7DFF8).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7DFF8)),
            ),
            child: Text(
              ex,
              style: const TextStyle(
                fontSize: 12,
                color: _purple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _purple),
              SizedBox(height: 20),
              Text(
                "AI sedang menyusun soal...",
                style: TextStyle(fontWeight: FontWeight.bold, color: _ink),
              ),
              SizedBox(height: 8),
              Text(
                "Mohon tunggu sebentar",
                style: TextStyle(fontSize: 13, color: _hint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
