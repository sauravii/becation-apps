import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'teacher_material_detail.dart';
import 'teacher_quiz_detail.dart';
import 'teacher_classes_dialogs.dart';
import '../../models/class_model.dart';
import '../../models/member_model.dart';
import '../../models/topic_model.dart';
import '../../models/material_model.dart';
import '../../models/quiz_model.dart';
import '../../services/user_service.dart';
import '../../services/class_service.dart';
import '../../services/topic_service.dart';
import '../../services/material_service.dart';
import '../../services/quiz_service.dart';
import '../../components/cards/topic_section.dart';
import '../../components/cards/material_card.dart';
import '../../components/cards/quiz_card.dart';
import '../../components/member_avatar.dart';
import '../../components/navigation/nav_item.dart';

class TeacherClassesDetail extends StatefulWidget {
  final String classId;
  final String classTitle;
  final Color classColor;

  const TeacherClassesDetail({
    super.key,
    required this.classId,
    required this.classTitle,
    required this.classColor,
  });

  @override
  State<TeacherClassesDetail> createState() => _TeacherClassesDetailState();
}

class _TeacherClassesDetailState extends State<TeacherClassesDetail> {
  int _selectedIndex = 0;
  // 0 = Quiz, 1 = Material. Default Material.
  int _activeContentTab = 1;
  String _userRole = 'teacher';
  bool _isLoading = true;
  // Select mode untuk People tab — pilih student untuk di-remove.
  bool _isSelectMode = false;
  final Set<String> _selectedStudentUids = {};

  late final Stream<List<TopicModel>> _topicsStream;
  late final Stream<List<QuizModel>> _quizzesStream;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _topicsStream = TopicService.topicsStream(widget.classId);
    _quizzesStream = QuizService.quizzesStream(widget.classId);
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await UserService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFab =
        _userRole == 'teacher' && !_isLoading && _selectedIndex != 2;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            _buildBottomNav(),
          ],
        ),
      ),
      floatingActionButton: showFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton(
                onPressed: () {
                  showAddOptionsSheet(context, classId: widget.classId);
                },
                backgroundColor: const Color(0xFF6F5AAA),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1B20)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.class_rounded, color: Color(0xFF1C1B20), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.classTitle,
              style: const TextStyle(
                color: Color(0xFF1C1B20),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildClassTab();
      case 1:
        return _buildClassworkTab();
      case 2:
        return _buildPeopleTab();
      default:
        return _buildClassTab();
    }
  }

  Widget _buildClassTab() {
    return StreamBuilder<ClassModel?>(
      stream: ClassService.classStream(widget.classId),
      builder: (context, snapshot) {
        final classData = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClassBanner(classData),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildContentTabButton('Quiz', 0)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildContentTabButton('Material', 1)),
                ],
              ),
              const SizedBox(height: 16),
              if (_activeContentTab == 0)
                _buildAllQuizzesList()
              else
                _buildAllMaterialsList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassBanner(ClassModel? classData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE7DFF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.classColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              classData?.subject.isNotEmpty == true
                  ? classData!.subject
                  : 'Subject',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.classTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1B20),
            ),
          ),
          if (classData?.description.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              classData!.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF49454E),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentTabButton(String label, int index) {
    final isActive = _activeContentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeContentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6F5AAA) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF6F5AAA), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF6F5AAA),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassCodeCard() {
    return StreamBuilder<ClassModel?>(
      stream: ClassService.classStream(widget.classId),
      builder: (context, snapshot) {
        final classCode = snapshot.data?.classCode ?? '...';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              const Text(
                'Class Code',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                classCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F5AAA),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: classCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Class code copied!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6F5AAA),
                  side: const BorderSide(color: Color(0xFF6F5AAA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllQuizzesList() {
    return StreamBuilder<List<QuizModel>>(
      stream: _quizzesStream,
      builder: (context, snapshot) {
        final quizzes = snapshot.data ?? [];

        if (quizzes.isEmpty) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE7DFF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No quizzes yet',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
        }

        return Column(
          children: quizzes
              .map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: QuizCard(
                      title: q.title,
                      questionCount: q.questionCount,
                      timeLimit: q.timeLimit,
                      passingGrade: q.passingGrade,
                      topicTitle: q.topicTitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TeacherQuizDetail(
                              classId: widget.classId,
                              quizId: q.id,
                              classColor: widget.classColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildAllMaterialsList() {
    return StreamBuilder<List<MaterialModel>>(
      stream: MaterialService.materialsStream(widget.classId),
      builder: (context, snapshot) {
        final materials = snapshot.data ?? [];

        if (materials.isEmpty) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE7DFF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No materials yet',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          );
        }

        return Column(
          children: materials
              .map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MaterialCard(
                      material: MaterialItem(
                        id: m.id,
                        title: m.title,
                        timestamp: m.formattedTime,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TeacherMaterialDetail(
                                classId: widget.classId,
                                materialId: m.id,
                                materialTitle: m.title,
                                materialTimestamp: m.formattedTime,
                                topicTitle: m.topicTitle,
                                topicColor: widget.classColor,
                              ),
                            ),
                          );
                        },
                      ),
                      topicTitle: m.topicTitle,
                      topicColor: widget.classColor,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildClassworkTab() {
    return StreamBuilder<List<TopicModel>>(
      stream: _topicsStream,
      builder: (context, topicSnapshot) {
        if (topicSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final topics = topicSnapshot.data ?? [];

        if (topics.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.topic_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No topics yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap + to create your first topic.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topics.map<Widget>((topic) {
              return StreamBuilder<List<MaterialModel>>(
                stream: MaterialService.materialsStream(
                  widget.classId,
                  topicId: topic.id,
                ),
                builder: (context, materialSnapshot) {
                  final materials = materialSnapshot.data ?? [];

                  return StreamBuilder<List<QuizModel>>(
                    stream: QuizService.quizzesStream(
                      widget.classId,
                      topicId: topic.id,
                    ),
                    builder: (context, quizSnapshot) {
                      final quizzes = quizSnapshot.data ?? [];

                      final topicItem = TopicItem(
                        id: topic.id,
                        title: topic.title,
                        onEdit: () => showEditTopicDialog(context,
                            classId: widget.classId, topic: topic),
                        onDelete: () => showDeleteTopicDialog(context,
                            classId: widget.classId,
                            topic: topic,
                            materialCount: materials.length,
                            quizCount: quizzes.length),
                        materials: materials
                            .map((m) => MaterialItem(
                                  id: m.id,
                                  title: m.title,
                                  timestamp: m.formattedTime,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TeacherMaterialDetail(
                                          classId: widget.classId,
                                          materialId: m.id,
                                          materialTitle: m.title,
                                          materialTimestamp: m.formattedTime,
                                          topicTitle: topic.title,
                                          topicColor: widget.classColor,
                                        ),
                                      ),
                                    );
                                  },
                                ))
                            .toList(),
                        quizzes: quizzes
                            .map((q) => QuizItem(
                                  id: q.id,
                                  title: q.title,
                                  questionCount: q.questionCount,
                                  timeLimit: q.timeLimit,
                                  passingGrade: q.passingGrade,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TeacherQuizDetail(
                                          classId: widget.classId,
                                          quizId: q.id,
                                          classColor: widget.classColor,
                                        ),
                                      ),
                                    );
                                  },
                                ))
                            .toList(),
                      );

                      return TopicSection(topic: topicItem);
                    },
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ClassService.classMembersStream(widget.classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final membersData = snapshot.data ?? [];
        final members =
            membersData.map((m) => MemberModel.fromMap(m)).toList();

        members.sort((a, b) {
          if (a.isTeacher && !b.isTeacher) return -1;
          if (!a.isTeacher && b.isTeacher) return 1;
          return a.displayName.compareTo(b.displayName);
        });

        if (members.isEmpty) {
          return const Center(
            child: Text(
              'No members yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final teachers = members.where((m) => m.isTeacher).toList();
        final students = members.where((m) => !m.isTeacher).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClassCodeCard(),
              const SizedBox(height: 24),
              Text(
                'Teacher (${teachers.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F5AAA),
                ),
              ),
              const Divider(color: Color(0xFF6F5AAA)),
              ...teachers.map((m) => _buildMemberTile(m)),

              const SizedBox(height: 20),

              // Students section header + tombol pensil / aksi select mode
              Row(
                children: [
                  Text(
                    'Students (${students.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F5AAA),
                    ),
                  ),
                  const Spacer(),
                  if (_isSelectMode) ...[
                    if (_selectedStudentUids.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          final selected = students
                              .where((s) =>
                                  _selectedStudentUids.contains(s.uid))
                              .toList();
                          showRemoveStudentsDialog(
                            context,
                            classId: widget.classId,
                            selectedUids:
                                selected.map((s) => s.uid).toList(),
                            selectedNames: selected
                                .map((s) => s.displayName.isNotEmpty
                                    ? s.displayName
                                    : s.email)
                                .toList(),
                            onSuccess: () {
                              setState(() {
                                _selectedStudentUids.clear();
                                _isSelectMode = false;
                              });
                            },
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.delete,
                            color: Colors.red.shade700,
                            size: 18,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSelectMode = false;
                          _selectedStudentUids.clear();
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.green.shade700,
                          size: 18,
                        ),
                      ),
                    ),
                  ] else if (students.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() => _isSelectMode = true);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F5AAA).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xFF6F5AAA),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(color: Color(0xFF6F5AAA)),
              if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No students yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...students.map((m) => _buildMemberTile(m)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberTile(MemberModel member) {
    final isSelected = _selectedStudentUids.contains(member.uid);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: (_isSelectMode && !member.isTeacher)
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedStudentUids.remove(member.uid);
                } else {
                  _selectedStudentUids.add(member.uid);
                }
              });
            }
          : null,
      leading: _isSelectMode && !member.isTeacher
          ? CircleAvatar(
              backgroundColor: isSelected
                  ? const Color(0xFF6F5AAA)
                  : const Color(0xFFE9DFF0),
              child: Icon(
                isSelected ? Icons.check : Icons.person,
                color: isSelected ? Colors.white : const Color(0xFF6F5AAA),
                size: 20,
              ),
            )
          : MemberAvatar(
              uid: member.uid,
              isTeacher: member.isTeacher,
            ),
      title: MemberDisplayName(
        uid: member.uid,
        fallback: member.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        member.email,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
            icon: Icons.class_rounded,
            label: 'Class',
            active: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
                _isSelectMode = false;
                _selectedStudentUids.clear();
              });
            },
          ),
          NavItem(
            icon: Icons.assignment_rounded,
            label: 'Classwork',
            active: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
                _isSelectMode = false;
                _selectedStudentUids.clear();
              });
            },
          ),
          NavItem(
            icon: Icons.groups_rounded,
            label: 'People',
            active: _selectedIndex == 2,
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
            },
          ),
        ],
      ),
    );
  }
}
