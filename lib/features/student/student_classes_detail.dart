import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/class_model.dart';
import '../../models/topic_model.dart';
import '../../models/material_model.dart';
import '../../models/member_model.dart';
import '../../models/quiz_model.dart';
import '../../services/class_service.dart';
import '../../services/topic_service.dart';
import '../../services/material_service.dart';
import '../../services/quiz_service.dart';
import '../../components/cards/material_card.dart';
import '../../components/cards/quiz_card.dart';
import '../../components/cards/topic_section.dart';
import '../../components/navigation/nav_item.dart';
import '../../components/map/learning_map.dart';
import 'student_material_detail.dart';
import 'student_quiz_intro_screen.dart';
import 'student_quiz_result_page.dart';
import 'student_leaderboard.dart';

class StudentClassesDetail extends StatefulWidget {
  final String classId;
  final String classTitle;
  final Color classColor;

  const StudentClassesDetail({
    super.key,
    required this.classId,
    required this.classTitle,
    required this.classColor,
  });

  @override
  State<StudentClassesDetail> createState() => _StudentClassesDetailState();
}

class _StudentClassesDetailState extends State<StudentClassesDetail> {
  int _selectedIndex = 0;

  late final Stream<List<TopicModel>> _topicsStream;
  late final Stream<List<QuizModel>> _quizzesStream;

  @override
  void initState() {
    super.initState();
    _topicsStream = TopicService.topicsStream(widget.classId);
    _quizzesStream = QuizService.quizzesStream(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    final isLeaderboard = _selectedIndex == 1;

    return Scaffold(
      backgroundColor: isLeaderboard ? const Color(0xFF6F5AAA) : const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Column(
          children: [
            if (!isLeaderboard) _buildHeader(),
            Expanded(child: _buildContent()),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // Dialog konfirmasi leave class dengan countdown 3 detik.
  void _showLeaveClassDialog() {
    int countdown = 3;
    Timer? timer;
    bool isLeaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (countdown > 0) {
              setDialogState(() => countdown--);
            } else {
              t.cancel();
            }
          });

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('Leave Class'),
              ],
            ),
            content: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1C1B20),
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to leave '),
                  TextSpan(
                    text: '"${widget.classTitle}"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        '? You will lose access to all materials in this class.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLeaving
                    ? null
                    : () {
                        timer?.cancel();
                        Navigator.pop(dialogContext);
                      },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: (countdown > 0 || isLeaving)
                    ? null
                    : () async {
                        setDialogState(() => isLeaving = true);

                        try {
                          await ClassService.leaveClass(widget.classId);

                          timer?.cancel();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) {
                            Navigator.of(this.context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('You left the class'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isLeaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to leave: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: countdown > 0 ? Colors.grey : Colors.red,
                ),
                child: isLeaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(countdown > 0 ? 'Leave ($countdown)' : 'Leave'),
              ),
            ],
          );
        },
      ),
    ).then((_) => timer?.cancel());
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 20, right: 8),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1C1B20)),
            onSelected: (value) {
              if (value == 'leave') {
                _showLeaveClassDialog();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Leave Class', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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
        return StudentLeaderboard(
          classId: widget.classId,
          classColor: widget.classColor,
        );
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
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Detail Card
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.all(20),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(16),
              //     border: Border.all(color: Colors.grey.shade200),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       // Subject badge
              //       Container(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 12,
              //           vertical: 6,
              //         ),
              //         decoration: BoxDecoration(
              //           color: widget.classColor,
              //           borderRadius: BorderRadius.circular(30),
              //         ),
              //         child: Text(
              //           classData?.subject ?? '...',
              //           style: const TextStyle(
              //             color: Colors.white,
              //             fontSize: 12,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //       ),
              //       const SizedBox(height: 16),
              //       // Teacher
              //       Row(
              //         children: [
              //           const Icon(Icons.person, size: 18, color: Colors.grey),
              //           const SizedBox(width: 8),
              //           Text(
              //             classData?.teacherName.isNotEmpty == true
              //                 ? classData!.teacherName
              //                 : 'Teacher',
              //             style: const TextStyle(
              //               fontSize: 15,
              //               fontWeight: FontWeight.w500,
              //               color: Color(0xFF1C1B20),
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 10),
              //       // Student count
              //       Row(
              //         children: [
              //           const Icon(Icons.groups_2_outlined,
              //               size: 18, color: Colors.grey),
              //           const SizedBox(width: 8),
              //           Text(
              //             '${classData?.studentCount ?? 0} Students',
              //             style: const TextStyle(
              //               fontSize: 14,
              //               color: Color(0xFF1C1B20),
              //             ),
              //           ),
              //         ],
              //       ),
              //       if (classData?.description.isNotEmpty == true) ...[
              //         const SizedBox(height: 16),
              //         const Divider(height: 1),
              //         const SizedBox(height: 16),
              //         Text(
              //           classData!.description,
              //           style: const TextStyle(
              //             fontSize: 14,
              //             color: Colors.grey,
              //             height: 1.5,
              //           ),
              //         ),
              //       ],
              //     ],
              //   ),
              // ),
              const SizedBox(height: 24),

              // // Learning Path Section
              // _buildSectionHeader('Learning Path'),
              // const Divider(
              //     color: Color(0xFF49454E), thickness: 1, height: 20),
              // const SizedBox(height: 10),
              _buildLearningMap(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C1B20),
        ),
      ),
    );
  }

  Widget _buildLearningMap() {
    return StreamBuilder<List<TopicModel>>(
      stream: _topicsStream,
      builder: (context, topicSnapshot) {
        return StreamBuilder<List<QuizModel>>(
          stream: _quizzesStream,
          builder: (context, quizSnapshot) {
            return StreamBuilder<List<MaterialModel>>(
              stream: MaterialService.materialsStream(widget.classId),
              builder: (context, materialSnapshot) {
                final topics = topicSnapshot.data ?? [];
                final quizzes = quizSnapshot.data ?? [];
                final materials = materialSnapshot.data ?? [];

                final learningTopics = <LearningTopic>[];
                final usedMaterials = <String>{};
                final usedQuizzes = <String>{};

                // Create a topic section for each defined topic
                for (int i = 0; i < topics.length; i++) {
                  final t = topics[i];
                  final nodes = <LearningNode>[];

                  final topicMaterials = materials
                      .where((m) => m.topicTitle == t.title)
                      .toList();

                  final topicQuizzes = quizzes
                      .where((q) => q.topicTitle == t.title)
                      .toList();

                  usedMaterials.addAll(topicMaterials.map((m) => m.id));
                  usedQuizzes.addAll(topicQuizzes.map((q) => q.id));

                  for (final m in topicMaterials) {
                    nodes.add(
                      LearningNode(
                        id: m.id,
                        title: m.title,
                        type: 'material',
                        color: const Color(0xFF7A6B9E),
                        shadowColor: const Color(0xFF5A4A8A),
                        icon: 'assets/icons/class_material.png',
                        onTap: () => _handleMaterialTap(m),
                        createdAt: m.createdAt?.toDate(),
                      ),
                    );
                  }

                  for (final q in topicQuizzes) {
                    nodes.add(
                      LearningNode(
                        id: q.id,
                        title: q.title,
                        type: 'quiz',
                        color: const Color(0xFF9E6B7B),
                        shadowColor: const Color(0xFF8A4A5D),
                        icon: 'assets/icons/class_quiz.png',
                        onTap: () => _handleQuizTap(q),
                        createdAt: q.createdAt?.toDate(),
                      ),
                    );
                  }

                  // Sort nodes by timestamp (oldest first)
                  nodes.sort((a, b) {
                    if (a.createdAt == null && b.createdAt == null) return 0;
                    if (a.createdAt == null) return 1;
                    if (b.createdAt == null) return -1;
                    return a.createdAt!.compareTo(b.createdAt!);
                  });

                  learningTopics.add(
                    LearningTopic(id: t.id, title: t.title, nodes: nodes),
                  );
                }

                // Add any uncategorized materials or quizzes to a generic "Other" topic
                final unusedMaterials = materials
                    .where((m) => !usedMaterials.contains(m.id))
                    .toList();

                final unusedQuizzes = quizzes
                    .where((q) => !usedQuizzes.contains(q.id))
                    .toList();

                if (unusedMaterials.isNotEmpty ||
                    unusedQuizzes.isNotEmpty ||
                    topics.isEmpty) {
                  final nodes = <LearningNode>[];

                  for (final m in unusedMaterials) {
                    nodes.add(
                      LearningNode(
                        id: m.id,
                        title: m.title,
                        type: 'material',
                        color: const Color(0xFF7A6B9E),
                        shadowColor: const Color(0xFF5A4A8A),
                        icon: 'assets/icons/class_material.png',
                        onTap: () => _handleMaterialTap(m),
                        createdAt: m.createdAt?.toDate(),
                      ),
                    );
                  }

                  for (final q in unusedQuizzes) {
                    nodes.add(
                      LearningNode(
                        id: q.id,
                        title: q.title,
                        type: 'quiz',
                        color: const Color(0xFF9E6B7B),
                        shadowColor: const Color(0xFF8A4A5D),
                        icon: 'assets/icons/class_quiz.png',
                        onTap: () => _handleQuizTap(q),
                        createdAt: q.createdAt?.toDate(),
                      ),
                    );
                  }

                  // Sort nodes by timestamp (oldest first)
                  nodes.sort((a, b) {
                    if (a.createdAt == null && b.createdAt == null) return 0;
                    if (a.createdAt == null) return 1;
                    if (b.createdAt == null) return -1;
                    return a.createdAt!.compareTo(b.createdAt!);
                  });

                  learningTopics.add(
                    LearningTopic(
                      id: 'other',
                      title: 'Classwork',
                      nodes: nodes,
                    ),
                  );
                }

                return LearningMap(topics: learningTopics);
              },
            );
          },
        );
      },
    );
  }

  void _handleMaterialTap(MaterialModel m) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentMaterialDetail(
          classId: widget.classId,
          materialId: m.id,
          materialTitle: m.title,
          materialTimestamp: m.formattedTime,
          topicTitle: m.topicTitle,
          topicColor: widget.classColor,
        ),
      ),
    );
  }

  Future<void> _handleQuizTap(QuizModel q) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final attempts = await QuizService.getStudentAttemptsCount(
        widget.classId,
        q.id,
      );
      if (!context.mounted) return;
      Navigator.pop(context); // close loading modal

      if (attempts > 0) {
        final bool reachedLimit = attempts >= q.attemptLimit;
        final proceed = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              reachedLimit ? 'Attempt Limit Reached' : 'Quiz Attempt',
            ),
            content: Text(
              reachedLimit
                  ? 'You have reached the maximum attempt limit (${q.attemptLimit}) for this quiz.\nWould you like to review your last attempt?'
                  : 'You have made $attempts out of ${q.attemptLimit} attempts.\nWhat would you like to do?',
            ),
            actionsOverflowButtonSpacing: 10,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'check'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6F5AAA),
                ),
                child: const Text('Check Answer'),
              ),
              if (!reachedLimit)
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'attempt'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6F5AAA),
                  ),
                  child: const Text('Attempt Again'),
                ),
            ],
          ),
        );

        if (proceed == null || proceed == 'cancel') return;

        if (proceed == 'check') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          try {
            final questionsSnap = await QuizService.getQuestionsFuture(
              widget.classId,
              q.id,
            );
            final latestAttempt = await QuizService.getLatestStudentAttempt(
              widget.classId,
              q.id,
            );

            if (!context.mounted) return;
            Navigator.pop(context); // close loading

            if (latestAttempt == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No attempt data found.')),
              );
              return;
            }

            final answersMap =
                (latestAttempt['answers'] as Map?)?.cast<String, int>() ?? {};
            final correctAnswersMap = <String, List<int>>{};
            final questionSnap = latestAttempt['questionSnapshot'] as List?;
            if (questionSnap != null) {
              for (final qData in questionSnap) {
                if (qData is Map) {
                  final id = qData['id']?.toString();
                  final indices = qData['correctIndices'];
                  if (id != null && indices is List) {
                    correctAnswersMap[id] = indices
                        .whereType<num>()
                        .map((n) => n.toInt())
                        .toList();
                  }
                }
              }
            }

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentQuizResultPage(
                  quiz: q,
                  questions: questionsSnap,
                  answers: answersMap,
                  correctAnswers: correctAnswersMap,
                  score: (latestAttempt['score'] as num?)?.toInt() ?? 0,
                  correct: (latestAttempt['correct'] as num?)?.toInt() ?? 0,
                  total: (latestAttempt['total'] as num?)?.toInt() ?? 0,
                  passed: latestAttempt['passed'] == true,
                  isFinalAttempt: reachedLimit,
                ),
              ),
            );
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
          return;
        }
        // If 'attempt', it falls through to push StudentQuizIntroScreen
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentQuizIntroScreen(
            classId: widget.classId,
            quiz: q,
            attemptCount: attempts,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking attempts: $e')));
    }
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
                  'Your teacher will add topics and materials here.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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

                  final topicItem = TopicItem(
                    id: topic.id,
                    title: topic.title,
                    materials: materials
                        .map(
                          (m) => MaterialItem(
                            id: m.id,
                            title: m.title,
                            timestamp: m.formattedTime,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudentMaterialDetail(
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
                          ),
                        )
                        .toList(),
                  );

                  return TopicSection(topic: topicItem);
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
        final members = membersData.map((m) => MemberModel.fromMap(m)).toList();

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

              Text(
                'Students (${students.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F5AAA),
                ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: member.isTeacher
            ? const Color(0xFF6F5AAA)
            : const Color(0xFFE9DFF0),
        child: Icon(
          member.isTeacher ? Icons.school : Icons.person,
          color: member.isTeacher ? Colors.white : const Color(0xFF6F5AAA),
          size: 20,
        ),
      ),
      title: Text(
        member.displayName.isNotEmpty ? member.displayName : 'No name',
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
            label: 'Roadmap',
            active: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          NavItem(
            icon: Icons.leaderboard,
            label: 'Leaderboard',
            active: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
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
