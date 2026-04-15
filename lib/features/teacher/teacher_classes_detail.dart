import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TeacherClassDetail extends StatefulWidget {
  const TeacherClassDetail({Key? key}) : super(key: key);

  @override
  State<TeacherClassDetail> createState() => _TeacherClassDetailState();
}

class _TeacherClassDetailState extends State<TeacherClassDetail> {
  
  bool hasMaterials = false;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () {
            
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
         
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
              
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6D5E9E),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6D5E9E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Subject',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Class Title',
                                style: TextStyle(color: Color(0xFF453676), fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Class Description',
                                style: TextStyle(color: Color(0xFF453676), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
              
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6D5E9E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(LucideIcons.fileText, size: 16),
                        label: const Text('Create quiz', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6D5E9E),
                          side: const BorderSide(color: Color(0xFF6D5E9E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(LucideIcons.filePlus, size: 16),
                        label: const Text('Create material', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: hasMaterials ? _buildMaterialList() : _buildEmptyState(),
          ),
        ],
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
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0 ? const Color(0xFFEBE7FA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(LucideIcons.messageCircle),
              ),
              label: 'Class',
            ),
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Icon(LucideIcons.clipboardList)),
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

  // WIDGET 1: TAMPILAN MATERI KOSONG
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.bookOpen, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'This is where quiz and materials will be shared',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the classwork page to share materials or create quizzes for your students',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET 2: TAMPILAN MATERI
  Widget _buildMaterialList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      itemCount: 3, 
      itemBuilder: (context, index) {
        return Container(
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
            title: const Text(
              'New material: Material Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            subtitle: const Text(
              '6:38 PM',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            trailing: IconButton(
              icon: const Icon(LucideIcons.moreVertical, color: Colors.black54, size: 20),
              onPressed: () {
              },
            ),
          ),
        );
      },
    );
  }
}
