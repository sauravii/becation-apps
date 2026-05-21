import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/leaderboard_service.dart';

/// Halaman leaderboard per-class. Top 100 ranked by point.
/// Current user di-highlight kalau ada di list.
///
/// Kalau [isTeacher] true, tampilkan menu "Tutup Semester" di app bar.
class LeaderboardPage extends StatefulWidget {
  final String classId;
  final String className;
  final bool isTeacher;

  const LeaderboardPage({
    super.key,
    required this.classId,
    required this.className,
    this.isTeacher = false,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<LeaderboardData> _future;
  late final String _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _future = LeaderboardService.getLeaderboard(widget.classId);
  }

  void _refresh() {
    setState(() {
      _future = LeaderboardService.getLeaderboard(widget.classId);
    });
  }

  Future<void> _confirmCloseSemester() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Semester?'),
        content: const Text(
          'Aksi ini akan kunci ranking final, award badge juara 1/2/3 ke '
          'top student, dan tidak bisa dibuka kembali. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tutup Semester'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await LeaderboardService.closeSemester(widget.classId);
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyClosed
                ? 'Semester sudah ditutup sebelumnya.'
                : 'Semester ditutup. ${result.awardsGranted.length} badge juara di-award.',
          ),
        ),
      );
      _refresh();
    } catch (err) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      final msg = err is ApiException ? err.message : err.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $msg')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Leaderboard — ${widget.className}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (widget.isTeacher)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'close') _confirmCloseSemester();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'close',
                  child: ListTile(
                    leading: Icon(Icons.flag, color: Colors.deepPurple),
                    title: Text('Tutup Semester'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          try {
            await _future;
          } catch (_) {}
        },
        child: FutureBuilder<LeaderboardData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final err = snap.error;
              final msg = err is ApiException ? err.message : err.toString();
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(msg, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final data = snap.data!;
            if (data.ranking.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Belum ada peserta di leaderboard.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: data.ranking.length + (data.closed ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                if (data.closed && i == 0) {
                  return Card(
                    color: Colors.purple.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.purple.shade100),
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.flag, color: Colors.purple),
                      title: Text('Semester ditutup'),
                      subtitle: Text('Ranking ini adalah hasil final.'),
                    ),
                  );
                }
                final idx = i - (data.closed ? 1 : 0);
                final entry = data.ranking[idx];
                return _LeaderboardTile(
                  entry: entry,
                  isCurrentUser: entry.uid == _currentUid,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
  });

  Color _rankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.grey.shade500;
    if (rank == 3) return Colors.brown.shade400;
    return Colors.blueGrey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isCurrentUser ? Colors.blue.shade50 : Colors.white,
      elevation: isCurrentUser ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isCurrentUser
            ? BorderSide(color: Colors.blue.shade300, width: 1.5)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _rankColor(entry.rank),
          child: Text(
            '${entry.rank}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          entry.displayName.isEmpty ? '(Tanpa nama)' : entry.displayName,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16, color: Colors.amber.shade700),
            const SizedBox(width: 4),
            Text(
              '${entry.point}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
