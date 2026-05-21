/**
 * Static metadata untuk 8 badge achievement.
 * Di-seed ke Firestore `badge_definitions/{badgeId}` via scripts/seed_badges.js.
 *
 * Trigger code baca via getBadgeDef(id) — gak query Firestore per-event.
 * Update di sini → re-run seed script → live.
 *
 * iconPath = path di Firebase Storage bucket (folder "badges/"). URL publik
 * di-resolve oleh seed script via getDownloadURL() dan disimpan jadi field
 * iconUrl di Firestore doc.
 *
 * criteriaType (dipakai trigger untuk dispatch logic):
 *   quiz_streak | late_night_access | topic_first_complete |
 *   login_streak | quiz_comeback | semester_rank
 */

const BADGES = [
  {
    id: "straight_a",
    name: "Straight-A Crusader",
    description: "Dapat nilai 90+ di 3 quiz berbeda berturut-turut.",
    tier: "hardest",
    iconPath: "badges/straight_a.png",
    pointReward: 25,
    isSecret: false,
    repeatable: true,
    criteriaType: "quiz_streak",
  },
  {
    id: "studyaholic",
    name: "The Studyaholic",
    description: "Si lembur. Akses materi 5x setelah jam 22:00.",
    tier: "hard",
    iconPath: "badges/studyaholic.png",
    pointReward: 20,
    isSecret: true,
    repeatable: false,
    criteriaType: "late_night_access",
  },
  {
    id: "flash",
    name: "The Flash",
    description:
        "Student pertama yang menyelesaikan semua materi + pass semua quiz " +
        "di sebuah topic.",
    tier: "medium",
    iconPath: "badges/flash.png",
    pointReward: 15,
    isSecret: false,
    repeatable: true,
    criteriaType: "topic_first_complete",
  },
  {
    id: "overachiever",
    name: "The Overachiever",
    description:
        "Login streak 28 hari (re-earn setiap kelipatan 28: day 56, 84, ...).",
    tier: "easy",
    iconPath: "badges/overachiever.png",
    pointReward: 10,
    isSecret: false,
    repeatable: true,
    criteriaType: "login_streak",
  },
  {
    id: "comeback_kid",
    name: "Comeback Kid",
    description:
        "Pernah gagal sebuah quiz, lalu lulus saat attempt berikutnya.",
    tier: "easiest",
    iconPath: "badges/comeback_kid.png",
    pointReward: 5,
    isSecret: false,
    repeatable: true,
    criteriaType: "quiz_comeback",
  },
  {
    id: "top_of_world",
    name: "Top of the World",
    description: "Juara 1 leaderboard kelas di akhir semester.",
    tier: "reward",
    iconPath: "badges/top_of_world.png",
    pointReward: 0,
    isSecret: false,
    repeatable: false,
    criteriaType: "semester_rank",
    rankPosition: 1,
  },
  {
    id: "almost",
    name: "Almost!",
    description: "Juara 2 leaderboard kelas di akhir semester.",
    tier: "reward",
    iconPath: "badges/almost.png",
    pointReward: 0,
    isSecret: false,
    repeatable: false,
    criteriaType: "semester_rank",
    rankPosition: 2,
  },
  {
    id: "close_enough",
    name: "Close Enough!",
    description: "Juara 3 leaderboard kelas di akhir semester.",
    tier: "reward",
    iconPath: "badges/close_enough.png",
    pointReward: 0,
    isSecret: false,
    repeatable: false,
    criteriaType: "semester_rank",
    rankPosition: 3,
  },
];

const BADGES_BY_ID = Object.fromEntries(BADGES.map((b) => [b.id, b]));

function getBadgeDef(id) {
  return BADGES_BY_ID[id] || null;
}

function listBadgeIds() {
  return BADGES.map((b) => b.id);
}

module.exports = {BADGES, BADGES_BY_ID, getBadgeDef, listBadgeIds};
