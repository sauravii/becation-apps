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
    description: "Score 90+ on 3 different quizzes in a row.",
    tier: "hardest",
    iconPath: "badges/Straight-A-Crusader.png",
    pointReward: 25,
    isSecret: false,
    repeatable: true,
    criteriaType: "quiz_streak",
  },
  {
    id: "studyaholic",
    name: "The Studyaholic",
    description: "Night owl. Access learning materials 5 times after 10:00 PM.",
    tier: "hard",
    iconPath: "badges/The-Studyholic.png",
    pointReward: 20,
    isSecret: true,
    repeatable: false,
    criteriaType: "late_night_access",
  },
  {
    id: "flash",
    name: "The Flash",
    description:
        "Be the first student to complete every material and pass every " +
        "quiz in a topic.",
    tier: "medium",
    iconPath: "badges/The-Flash.png",
    pointReward: 15,
    isSecret: false,
    repeatable: true,
    criteriaType: "topic_first_complete",
  },
  {
    id: "overachiever",
    name: "The Overachiever",
    description:
        "Maintain a 28-day login streak (re-earned every multiple of 28: " +
        "day 56, 84, ...).",
    tier: "easy",
    iconPath: "badges/The-Overachiever.png",
    pointReward: 10,
    isSecret: false,
    repeatable: true,
    criteriaType: "login_streak",
  },
  {
    id: "comeback_kid",
    name: "Comeback Kid",
    description:
        "Fail a quiz, then pass it on your next attempt.",
    tier: "easiest",
    iconPath: "badges/Comeback-Kid.png",
    pointReward: 5,
    isSecret: false,
    repeatable: true,
    criteriaType: "quiz_comeback",
  },
  {
    id: "top_of_world",
    name: "Top of the World",
    description: "Finish #1 on the class leaderboard at the end of the semester.",
    tier: "reward",
    iconPath: "badges/Top-Of-The-World.png",
    pointReward: 0,
    isSecret: false,
    repeatable: false,
    criteriaType: "semester_rank",
    rankPosition: 1,
  },
  {
    id: "almost",
    name: "Almost!",
    description: "Finish #2 on the class leaderboard at the end of the semester.",
    tier: "reward",
    iconPath: "badges/Almost!.png",
    pointReward: 0,
    isSecret: false,
    repeatable: false,
    criteriaType: "semester_rank",
    rankPosition: 2,
  },
  {
    id: "close_enough",
    name: "Close Enough!",
    description: "Finish #3 on the class leaderboard at the end of the semester.",
    tier: "reward",
    iconPath: "badges/Close-Enough!.png",
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
