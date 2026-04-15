import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TeacherMaterialListPage extends StatefulWidget {
  const TeacherMaterialListPage({Key? key}) : super(key: key);

  @override
  State<TeacherMaterialListPage> createState() => _TeacherMaterialListPageState();
}

class _TeacherMaterialListPageState extends State<TeacherMaterialListPage> {

  bool hasMaterials = true; 
  int _selectedIndex = 1; 


  final List<Map<String, dynamic>> topics = [
    {
      'topicName': 'Topic 1',
      'items': [
        {'title': 'New material: Material Name', 'time': '6:38 PM'},
        {'title': 'New material: Material Name', 'time': '6:38 PM'},
      ]
    },
    {
      'topicName': 'Topic 2',
      'items': [
        {'title': 'New material: Material Name', 'time': '6:38 PM'},
        {'title': 'New material: Material Name', 'time': '6:38 PM'},
      ]
    },
  ];


  void _showCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(LucideIcons.clipboardList, color: Color(0xFF453676)),
                title: const Text('Quiz', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.clipboardSignature, color: Color(0xFF453676)),
                title: const Text('Material', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      
    
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(LucideIcons.messageCircle, color: Color(0xFF453676)), 
        ),
        leadingWidth: 40,
        title: const Text(
          'Class Title',
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

     
      body: hasMaterials ? _buildMaterialList() : _buildEmptyState(),

      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0), 
        child: SizedBox(
          width: 60,
          height: 60,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF6D5E9E),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
            onPressed: _showCreateBottomSheet,
            child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
          ),
        ),
      ),


      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF6D5E9E),
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(LucideIcons.messageCircle)),
              label: 'Class',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1 ? const Color(0xFFEBE7FA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(LucideIcons.clipboardList),
              ),
              label: 'Classwork',
            ),
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(LucideIcons.users)),
              label: 'People',
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          
            Icon(LucideIcons.userCheck, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 32),
            const Text(
              'This is where you can hand out assignments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'You can add assignments for the class, then organize it into topics',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMaterialList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        final items = topic['items'] as List;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
       
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  topic['topicName'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.moreVertical, color: Colors.black87, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
            Divider(color: Colors.grey.shade300, height: 1, thickness: 1),
            const SizedBox(height: 12),

            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEBE7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6D5E9E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.bookBookmark, color: Colors.white, size: 20),
                ),
                title: Text(
                  item['title'],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                subtitle: Text(
                  item['time'],
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.moreVertical, color: Colors.black54, size: 20),
                  onPressed: () {},
                ),
              ),
            )).toList(),
            const SizedBox(height: 16), 
          ],
        );
      },
    );
  }
}
