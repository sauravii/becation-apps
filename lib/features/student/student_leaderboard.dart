import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/leaderboard_service.dart';

class StudentLeaderboard extends StatefulWidget {
  final String classId;
  final Color classColor;

  const StudentLeaderboard({
    super.key,
    required this.classId,
    required this.classColor,
  });

  @override
  State<StudentLeaderboard> createState() => _StudentLeaderboardState();
}

class _StudentLeaderboardState extends State<StudentLeaderboard> {
  late Future<LeaderboardData> _future;
  late final String _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _future = LeaderboardService.getLeaderboard(widget.classId);
  }

  Future<void> _refresh() async {
    final newFuture = LeaderboardService.getLeaderboard(widget.classId);
    setState(() {
      _future = newFuture;
    });
    // Tunggu future selesai supaya RefreshIndicator spinner tetap visible
    // sampai data baru datang. Swallow error — sudah dihandle FutureBuilder.
    try {
      await newFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeaderboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          final err = snapshot.error;
          final msg = err is ApiException ? err.message : err.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white70, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final entries = data.ranking;

        if (entries.isEmpty) {
          return _buildEmptyState(context);
        }

        final leaderboardList = entries
            .map((e) => LeaderboardItem(
                  uid: e.uid,
                  displayName: e.displayName,
                  photoUrl: e.photoUrl,
                  xp: e.point,
                  rank: e.rank,
                  isCurrentUser: e.uid == _currentUid,
                ))
            .toList();

        final top3 = leaderboardList.take(3).toList();

        // Pass clean data ke stateful content widget biar drag tidak trigger rebuild.
        return LeaderboardContent(
          leaderboardList: leaderboardList,
          top3: top3,
          onRefresh: _refresh,
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 16, right: 12, bottom: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 8),
          const Text(
            'Leaderboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  'No students in this class yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Once students join, they will appear here.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LeaderboardContent extends StatefulWidget {
  final List<LeaderboardItem> leaderboardList;
  final List<LeaderboardItem> top3;
  final Future<void> Function() onRefresh;

  const LeaderboardContent({
    super.key,
    required this.leaderboardList,
    required this.top3,
    required this.onRefresh,
  });

  @override
  State<LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends State<LeaderboardContent> with TickerProviderStateMixin {
  double _sheetFraction = 0.48; // Initial height fraction (52% of parent height)
  late AnimationController _animationController;
  Animation<double>? _fractionAnimation;

  // Staggered podium entry animations
  late AnimationController _entryController;
  late Animation<Offset> _firstPlaceOffset;
  late Animation<Offset> _secondPlaceOffset;
  late Animation<Offset> _thirdPlaceOffset;
  late Animation<double> _firstPlaceOpacity;
  late Animation<double> _secondPlaceOpacity;
  late Animation<double> _thirdPlaceOpacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animationController.addListener(() {
      if (_fractionAnimation != null) {
        setState(() {
          _sheetFraction = _fractionAnimation!.value;
        });
      }
    });

    // Initialize podium entry animation controller (1 second duration)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Staggered slide up & fade animations using fine-tuned easing
    _secondPlaceOffset = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _secondPlaceOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _firstPlaceOffset = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOutBack),
      ),
    );
    _firstPlaceOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeIn),
      ),
    );

    _thirdPlaceOffset = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _thirdPlaceOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    // Trigger the entrance animations on load
    _entryController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _animateToFraction(double targetFraction) {
    _fractionAnimation = Tween<double>(
      begin: _sheetFraction,
      end: targetFraction,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final sheetHeight = maxHeight * _sheetFraction;

        return Stack(
          children: [
            // Deep Purple Background
            Container(color: const Color(0xFF6F5AAA)),

            // Podium dibungkus RefreshIndicator + scrollable agar pull-down
            // di area ungu (atas) trigger refresh data leaderboard.
            // top: 56 = di bawah app bar, padding 19 supaya podium tetap
            // start di y=75 seperti layout lama.
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              bottom: sheetHeight,
              child: RefreshIndicator(
                color: const Color(0xFF6F5AAA),
                backgroundColor: Colors.white,
                onRefresh: widget.onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 19),
                  children: [
                    widget.top3.isNotEmpty
                        ? _buildPodium(widget.top3)
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),

            // Bottom Sheet containing the leaderboard list (max 7 items) - Custom Drag height
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: sheetHeight,
              child: _buildLeaderboardListContainer(
                fullList: widget.leaderboardList,
                maxHeight: maxHeight,
              ),
            ),

            // Custom App Bar positioned on top so back button is always clickable and not hidden by background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildAppBar(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 16, right: 12, bottom: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 8),
          const Text(
            'Leaderboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardItem> top3) {
    // Top 3 positions in podium order: 2nd place (left), 1st place (center), 3rd place (right)
    LeaderboardItem? first = top3.isNotEmpty ? top3[0] : null;
    LeaderboardItem? second = top3.length > 1 ? top3[1] : null;
    LeaderboardItem? third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 2nd Place Column
          if (second != null)
            FadeTransition(
              opacity: _secondPlaceOpacity,
              child: SlideTransition(
                position: _secondPlaceOffset,
                child: _buildPodiumColumn(
                  item: second,
                  height: 230, // Lowered for a more balanced and compact layout
                  avatarSize: 72, // Mathematically flush (68 + 5 pink + 7 purple = 80 width)
                  columnColor: const Color(0xFFD6C7FF).withOpacity(0.85),
                ),
              ),
            )
          else
            const SizedBox(width: 80), // Matched to new column width 80

          // 1st Place Column
          if (first != null)
            FadeTransition(
              opacity: _firstPlaceOpacity,
              child: SlideTransition(
                position: _firstPlaceOffset,
                child: _buildPodiumColumn(
                  item: first,
                  height: 260, // Lowered for a more balanced and compact layout
                  avatarSize: 72, // Mathematically flush (68 + 5 pink + 7 purple = 80 width)
                  columnColor: const Color(0xFFE2D9FF),
                ),
              ),
            )
          else
            const SizedBox(width: 80), // Matched to new column width 80

          // 3rd Place Column
          if (third != null)
            FadeTransition(
              opacity: _thirdPlaceOpacity,
              child: SlideTransition(
                position: _thirdPlaceOffset,
                child: _buildPodiumColumn(
                  item: third,
                  height: 210, // Lowered for a more balanced and compact layout
                  avatarSize: 72, // Mathematically flush (68 + 5 pink + 7 purple = 80 width)
                  columnColor: const Color(0xFFD6C7FF).withOpacity(0.65),
                ),
              ),
            )
          else
            const SizedBox(width: 80), // Matched to new column width 80
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardItem item,
    required double height,
    required double avatarSize,
    required Color columnColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rank Indicator Number
        Text(
          '${item.rank}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        // Ribbon Medal
        RibbonMedal(rank: item.rank, size: 28),
        
        // Dynamic spacer to account for the avatar's upward overflow (-avatarSize / 2)
        // plus a beautiful 6px gap above the avatar!
        SizedBox(height: avatarSize / 2 + 6),
        
        // Stack for the Capsule Column and overlapping Avatar
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // The Capsule Column
            Container(
              width: 80, // Decreased to 80 for a sleek, modern, narrow look where avatar slightly overflows
              height: height,
              decoration: BoxDecoration(
                color: columnColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Spacer inside the column to prevent text overlapping with the head ring cutout
                  SizedBox(height: avatarSize / 2 + 35),
                  // Username
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      item.displayName.isNotEmpty
                          ? item.displayName
                          : 'Username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5E4B8B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // XP Score
                  Text(
                    '${item.xp} XP',
                    style: const TextStyle(
                      color: Color(0xFF6F5AAA),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Overlapping Circle Avatar with Background Cutout Ring
            Positioned(
              top: -avatarSize / 2, // Floating exactly half-way over the top edge of the column
              child: Container(
                padding: const EdgeInsets.all(3.5), // Deep purple ring that masks the column in a U-shape
                decoration: const BoxDecoration(
                  color: Color(0xFF6F5AAA), // Matches scaffold deep purple background!
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.5), // Pink ring
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBBEC4),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: Colors.white,
                    backgroundImage: item.photoUrl.isNotEmpty
                        ? NetworkImage(item.photoUrl)
                        : null,
                    child: item.photoUrl.isEmpty
                        ? Text(
                            item.displayName.isNotEmpty
                                ? item.displayName[0].toUpperCase()
                                : 'S',
                            style: TextStyle(
                              color: const Color(0xFF6F5AAA),
                              fontWeight: FontWeight.bold,
                              fontSize: avatarSize * 0.45,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeaderboardListContainer({
    required List<LeaderboardItem> fullList,
    required double maxHeight,
  }) {
    // Limit to max 7 data points as requested: "max 7 data saja pas dinaikkan"
    final displayList = fullList.take(7).toList();

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (_animationController.isAnimating) {
          _animationController.stop();
        }
        final dy = details.delta.dy;
        final heightDivider = maxHeight > 0 ? maxHeight : 600.0;
        setState(() {
          // Dragging UP decreases y-coordinate, so we subtract to increase fraction
          _sheetFraction = (_sheetFraction - dy / heightDivider).clamp(0.48, 0.75);
        });
      },
      onVerticalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;
        if (velocity < -300) {
          // Flicked/Dragged UP quickly -> snap to fully open (0.75)
          _animateToFraction(0.75);
        } else if (velocity > 300) {
          // Flicked/Dragged DOWN quickly -> snap to fully closed (0.48)
          _animateToFraction(0.48);
        } else {
          // Slowly released -> snap to closest state (midpoint is 0.615)
          if (_sheetFraction >= 0.615) {
            _animateToFraction(0.75);
          } else {
            _animateToFraction(0.48);
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white, // Pure white background!
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4), // Elegant upward shadow separating from purple background
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Grey sliding sheet handle bar
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCAC4D0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            // List items - physics set to NeverScrollableScrollPhysics to let parent GestureDetector handle all drag events smoothly
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  final item = displayList[index];
                  return _buildListTile(item);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(LeaderboardItem item) {
    final bool isTop3 = item.rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100, // Thin, premium bottom border
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Rank Badge / Number
          Container(
            width: 30,
            alignment: Alignment.center, // Center both to align perfectly on the same vertical axis
            child: isTop3
                ? RibbonMedal(rank: item.rank, size: 24)
                : Text(
                    '${item.rank}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
          ),
          const SizedBox(width: 12), // Premium, consistent spacing before the avatar
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE9DFF0),
            backgroundImage: item.photoUrl.isNotEmpty
                ? NetworkImage(item.photoUrl)
                : null,
            child: item.photoUrl.isEmpty
                ? Text(
                    item.displayName.isNotEmpty
                        ? item.displayName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Color(0xFF6F5AAA),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Display Name
          Expanded(
            child: Text(
              item.displayName.isNotEmpty
                  ? item.displayName
                  : 'Username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1B20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Points / XP
          Text(
            '${item.xp} XP',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A757F),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardItem {
  final String uid;
  final String displayName;
  final String photoUrl;
  final int xp;
  final int rank;
  final bool isCurrentUser;

  LeaderboardItem({
    required this.uid,
    required this.displayName,
    required this.xp,
    required this.rank,
    required this.isCurrentUser,
    this.photoUrl = '',
  });

  LeaderboardItem copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    int? xp,
    int? rank,
    bool? isCurrentUser,
  }) {
    return LeaderboardItem(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      xp: xp ?? this.xp,
      rank: rank ?? this.rank,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

class RibbonMedal extends StatelessWidget {
  final int rank;
  final double size;

  const RibbonMedal({
    super.key,
    required this.rank,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    String assetPath;

    if (rank == 1) {
      assetPath = 'lib/assets/1st_medal.png';
    } else if (rank == 2) {
      assetPath = 'lib/assets/2nd_medal.png';
    } else if (rank == 3) {
      assetPath = 'lib/assets/3rd_medal.png';
    } else {
      return const SizedBox();
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
