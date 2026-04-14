import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../components/cards/material_card.dart';
import '../../components/cards/topic_section.dart';
import '../../components/navigation/nav_item.dart';

class StudentClassesDetail extends StatefulWidget {
  final String classTitle;
  final Color classColor;

  const StudentClassesDetail({
    super.key,
    required this.classTitle,
    required this.classColor,
  });

  @override
  State<StudentClassesDetail> createState() => _StudentClassesDetailState();
}

class _StudentClassesDetailState extends State<StudentClassesDetail> {
  int _selectedIndex = 1;
  String _userRole = 'student';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await UserService.getUserRole(user.uid);
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
            if (_userRole == 'teacher' && !_isLoading)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: FloatingActionButton(
                        onPressed: () {
                          _showAddOptions(context);
                        },
                        backgroundColor: const Color(0xFF6F5AAA),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Add Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1B20),
                ),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6F5AAA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.topic, color: Color(0xFF6F5AAA)),
              ),
              title: const Text('Add Topic'),
              subtitle: const Text('Create a new topic for this class'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement add topic functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add topic functionality coming soon!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6F5AAA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description, color: Color(0xFF6F5AAA)),
              ),
              title: const Text('Add Material'),
              subtitle: const Text('Add new material to existing topic'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement add material functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add material functionality coming soon!'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, top: 20, right: 20),

      child: Row(
        children: [
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
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Image.asset('lib/assets/img_animasi_class.png'),
          const SizedBox(height: 40),

          // Description text
          const Text(
            'This is where you can view your classwork.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F1F1F),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'You can view materials and quizzes from the class',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClassworkTab() {
    final topics = [
      TopicItem(
        id: '1',
        title: 'Topic 1',
        materials: [
          MaterialItem(
            id: '1',
            title: 'New material: Material Name',
            timestamp: '6:38 PM',
          ),
          MaterialItem(
            id: '2',
            title: 'New material: Material Name',
            timestamp: '6:38 PM',
          ),
        ],
      ),
      TopicItem(
        id: '2',
        title: 'Topic 2',
        materials: [
          MaterialItem(
            id: '3',
            title: 'New material: Material Name',
            timestamp: '6:38 PM',
          ),
          MaterialItem(
            id: '4',
            title: 'New material: Material Name',
            timestamp: '6:38 PM',
          ),
        ],
      ),
      TopicItem(
        id: '2',
        title: 'Topic 3',
        materials: [
          MaterialItem(
            id: '3',
            title: 'New material: Material Name',
            timestamp: '6:38 PM',
          ),
          MaterialItem(
            id: '4',
            title: 'New material: Material Name',
            timestamp: '6:38 PM',
          ),
        ],
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: topics
            .map<Widget>((topic) => TopicSection(topic: topic))
            .toList(),
      ),
    );
  }

  Widget _buildPeopleTab() {
    return const Center(
      child: Text(
        'People tab content',
        style: TextStyle(fontSize: 16, color: Colors.grey),
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
