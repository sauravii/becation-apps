import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_material_detail.dart';
import '../../services/user_service.dart';

// Data Models
class MaterialItem {
  final String id;
  final String title;
  final String timestamp;
  final IconData icon;
  final VoidCallback? onTap;

  MaterialItem({
    required this.id,
    required this.title,
    required this.timestamp,
    this.icon = Icons.description_outlined,
    this.onTap,
  });
}

class TopicItem {
  final String id;
  final String title;
  final List<MaterialItem> materials;
  final VoidCallback? onMoreTap;

  TopicItem({
    required this.id,
    required this.title,
    required this.materials,
    this.onMoreTap,
  });
}

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
          _NavItem(
            icon: Icons.class_rounded,
            label: 'Class',
            active: _selectedIndex == 0,
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          _NavItem(
            icon: Icons.assignment_rounded,
            label: 'Classwork',
            active: _selectedIndex == 1,
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          _NavItem(
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

// Reusable Components
class TopicSection extends StatelessWidget {
  final TopicItem topic;

  const TopicSection({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TopicHeader(title: topic.title, onMoreTap: topic.onMoreTap),
        const Divider(color: Color(0xFF49454E), thickness: 1, height: 20),
        const SizedBox(height: 10),
        ...topic.materials.map(
          (material) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MaterialCard(
              material: material,
              topicTitle: topic.title,
              topicColor: const Color(0xFF6F5AAA),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class TopicHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMoreTap;

  const TopicHeader({super.key, required this.title, this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1B20),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1C1B20)),
            onPressed: onMoreTap,
          ),
        ],
      ),
    );
  }
}

class MaterialCard extends StatelessWidget {
  final MaterialItem material;
  final String topicTitle;
  final Color topicColor;

  const MaterialCard({
    super.key,
    required this.material,
    required this.topicTitle,
    required this.topicColor,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudentMaterialDetail(
                materialTitle: material.title,
                materialTimestamp: material.timestamp,
                topicTitle: topicTitle,
                topicColor: topicColor,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFE7DFF8),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(color: Color(0xFF63568F), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF615B71),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(material.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1B20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      material.timestamp,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF1C1B20)),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF6F5AAA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? activeColor : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
