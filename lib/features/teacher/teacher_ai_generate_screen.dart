import "dart:math";

import "package:flutter/material.dart";

import "../../services/api_client.dart";
import "teacher_create_question_screen.dart";

class TeacherAiGenerateScreen extends StatefulWidget {
  const TeacherAiGenerateScreen({super.key});

  @override
  State<TeacherAiGenerateScreen> createState() => _TeacherAiGenerateScreenState();
}

class _TeacherAiGenerateScreenState extends State<TeacherAiGenerateScreen> {
  static const _purple = Color(0xFF6F5AAA);
  static const _bg = Color(0xFFF7F2FA);
  static const _label = Color(0xFF49454E);
  static const _hint = Color(0xFF9A9499);
  static const _ink = Color(0xFF1C1B20);

  static const _difficulties = ["Easy", "Medium", "Hard", "Expert"];
  static const _languages = ["English", "Bahasa Indonesia"];

  static const int _examplesShown = 3;

  // Pool besar contoh prompt — di-shuffle setiap initState supaya guru lihat
  // varian berbeda saat buka layar. Tiap prompt ditulis untuk demonstrasiin
  // template yang baik: subject + audience/level + scope/focus.
  static const List<_PromptExample> _examplesPool = [
    _PromptExample(
      "Indonesian Independence (High School)",
      "Indonesian Independence history focusing on key events 1942-1945. For grade 10-12 students. Include questions on important figures and significant dates.",
    ),
    _PromptExample(
      "Python Basics: Loops & Functions",
      "Python programming basics for first-year computer science students. Focus on for/while loops and function definitions. Include code reading scenarios.",
    ),
    _PromptExample(
      "Linear Algebra Foundations",
      "Linear Algebra foundations for first-semester university: vectors, matrices, basic linear equations. Mix of conceptual understanding and simple computation.",
    ),
    _PromptExample(
      "Microeconomics: Supply & Demand",
      "Microeconomics fundamentals for grade 11: supply and demand, equilibrium price, market mechanisms. Focus on conceptual understanding, not heavy calculation.",
    ),
    _PromptExample(
      "Photosynthesis (Middle School)",
      "Photosynthesis process for grade 7-8 biology: components, stages, and factors affecting it. Include real-world applications and observation-based questions.",
    ),
    _PromptExample(
      "English Tenses Review",
      "English grammar tenses review for grade 10-11: simple, continuous, perfect forms. Mix of usage scenarios and error identification questions.",
    ),
    _PromptExample(
      "Newton's Laws of Motion",
      "Newton's three laws of motion for grade 10 physics. Include real-world examples and scenarios applying each law. Mix conceptual and simple calculation.",
    ),
    _PromptExample(
      "Periodic Table Basics",
      "Periodic table fundamentals for grade 9 chemistry: groups, periods, atomic structure, and trends. Focus on understanding patterns rather than memorization.",
    ),
    _PromptExample(
      "Cell Biology: Structure & Function",
      "Cell biology for grade 10: organelles structure and function, prokaryotic vs eukaryotic differences. Include diagram-based identification questions.",
    ),
    _PromptExample(
      "Indonesian Geography (Junior High)",
      "Indonesian geography for grade 7-9: provinces, islands, climate zones, and natural resources. Focus on Indonesian-specific facts and regional understanding.",
    ),
    _PromptExample(
      "World War II Major Events",
      "World War II major events for high school history: causes, key battles, and outcomes 1939-1945. Include questions on impact to Asia-Pacific region.",
    ),
    _PromptExample(
      "Statistics: Mean, Median, Mode",
      "Statistics measures of central tendency for grade 8: mean, median, mode calculations and interpretation. Include scenarios choosing the appropriate measure.",
    ),
    _PromptExample(
      "Climate Change Basics",
      "Climate change fundamentals for high school: greenhouse effect, human impacts, mitigation strategies. Mix scientific concepts and policy considerations.",
    ),
    _PromptExample(
      "Shakespeare's Macbeth (Literature)",
      "Shakespeare's Macbeth for grade 11-12 literature: themes, characters, plot points, and famous quotes. Include analysis of character motivations.",
    ),
    _PromptExample(
      "Database SQL Queries",
      "Basic SQL queries for college intro database course: SELECT, WHERE, JOIN, GROUP BY. Include reading queries and identifying expected output.",
    ),
  ];

  final _promptController = TextEditingController();
  int _questionCount = 5;
  int _optionsCount = 4;
  String _difficulty = "Medium";
  String _language = "English";
  bool _isLoading = false;
  late final List<_PromptExample> _displayedExamples;

  @override
  void initState() {
    super.initState();
    final shuffled = [..._examplesPool]..shuffle(Random());
    _displayedExamples = shuffled.take(_examplesShown).toList();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a quiz topic first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiClient.post("/quizzes/generate-ai", {
        "prompt": prompt,
        "count": _questionCount,
        "optionsCount": _optionsCount,
        "difficulty": _difficulty,
        "language": _language,
      }) as Map<String, dynamic>;

      if (!mounted) return;

      final List<dynamic> rawList = result["data"] as List<dynamic>;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate quiz: $e")),
      );
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
                  "How many questions do you want to create?",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _label),
                ),
                const SizedBox(height: 12),
                _buildQuestionCountSelector(),
                const SizedBox(height: 24),
                const Text(
                  "Number of answer options per question",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _label),
                ),
                const SizedBox(height: 12),
                _buildOptionsCountSelector(),
                const SizedBox(height: 24),
                const Text(
                  "Difficulty level",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _label),
                ),
                const SizedBox(height: 12),
                _buildDifficultySelector(),
                const SizedBox(height: 24),
                const Text(
                  "Quiz language",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _label),
                ),
                const SizedBox(height: 12),
                _buildLanguageSelector(),
                const SizedBox(height: 24),
                const Text(
                  "Quiz topic or instruction",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _label),
                ),
                const SizedBox(height: 12),
                _buildPromptField(),
                const SizedBox(height: 20),
                const Text(
                  "Example prompts (tap to use):",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _hint),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  // Selalu render Text dengan font 10 supaya semua tombol tinggi
                  // sama. Untuk c==2 isinya "T/F", lainnya space agar konsisten.
                  Text(
                    c == 2 ? "T/F" : " ",
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

  Widget _buildDifficultySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _difficulties.asMap().entries.map((entry) {
        final idx = entry.key;
        final d = entry.value;
        final isSelected = _difficulty == d;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = d),
            child: Container(
              margin: EdgeInsets.only(
                left: idx == 0 ? 0 : 4,
                right: idx == _difficulties.length - 1 ? 0 : 4,
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
                  d,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageSelector() {
    return Row(
      children: _languages.asMap().entries.map((entry) {
        final idx = entry.key;
        final lang = entry.value;
        final isSelected = _language == lang;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _language = lang),
            child: Container(
              margin: EdgeInsets.only(
                left: idx == 0 ? 0 : 4,
                right: idx == _languages.length - 1 ? 0 : 4,
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
                  lang,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
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
          hintText: "e.g., Create questions about Theory of Relativity at intermediate difficulty...",
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
      children: _displayedExamples.map((ex) {
        return InkWell(
          onTap: () => setState(() => _promptController.text = ex.prompt),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE7DFF8).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7DFF8)),
            ),
            child: Text(
              ex.label,
              style: const TextStyle(fontSize: 12, color: _purple, fontWeight: FontWeight.w500),
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
                "AI is generating questions...",
                style: TextStyle(fontWeight: FontWeight.bold, color: _ink),
              ),
              SizedBox(height: 8),
              Text(
                "Please wait...",
                style: TextStyle(fontSize: 13, color: _hint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptExample {
  final String label;
  final String prompt;
  const _PromptExample(this.label, this.prompt);
}
