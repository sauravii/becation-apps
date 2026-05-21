/**
 * Point reward formulas — kelipatan 5 except daily streak.
 * Tweak nilai di sini; trigger code tinggal panggil function.
 */

const POINT_MATERIAL_COMPLETE = 5;

/**
 * Hitung point untuk hasil quiz.
 * - 0-89  → floor(score/10) * 5  (89 = 40, 50 = 25, 10 = 5, 9 = 0)
 * - 90-99 → 60                    (base 50 * 1.2 — "near perfect")
 * - 100 (not first) → 75          (base 50 * 1.5)
 * - 100 (first submitter) → 100   (base 50 * 2.0)
 */
function quizScoreReward(score, isFirstSubmitter) {
  if (typeof score !== "number" || score < 0) return 0;
  if (score < 90) return Math.floor(score / 10) * 5;
  if (score < 100) return 60;
  return isFirstSubmitter ? 100 : 75;
}

/**
 * Reward harian untuk streak login.
 * Escalating, capped di +5 saat day 30+. No grace — putus 1 hari restart day 1.
 */
function dailyStreakReward(streakDay) {
  if (streakDay < 1) return 0;
  if (streakDay <= 6) return 1;
  if (streakDay <= 13) return 2;
  if (streakDay <= 20) return 3;
  if (streakDay <= 29) return 4;
  return 5;
}

/** Threshold sentral untuk semua badge criteria. */
const BADGE_THRESHOLDS = {
  studyaholic: {
    lateNightHourMin: 22,
    requiredCount: 5,
  },
  straight_a: {
    consecutiveCount: 3,
    minScore: 90,
  },
  overachiever: {
    minStreakDays: 28,
  },
};

/** Timezone untuk streak day boundary. */
const STREAK_TIMEZONE_OFFSET_MINUTES = 7 * 60; // UTC+7 Asia/Jakarta

/** Format Date → "YYYY-MM-DD" pakai UTC+7 boundary. */
function dateKeyJakarta(date) {
  const ms = date.getTime() + STREAK_TIMEZONE_OFFSET_MINUTES * 60 * 1000;
  return new Date(ms).toISOString().slice(0, 10);
}

/** Hour-of-day di UTC+7 (0-23). Untuk badge Studyaholic late-night check. */
function hourLocalJakarta(date) {
  const ms = date.getTime() + STREAK_TIMEZONE_OFFSET_MINUTES * 60 * 1000;
  return new Date(ms).getUTCHours();
}

module.exports = {
  POINT_MATERIAL_COMPLETE,
  quizScoreReward,
  dailyStreakReward,
  BADGE_THRESHOLDS,
  STREAK_TIMEZONE_OFFSET_MINUTES,
  dateKeyJakarta,
  hourLocalJakarta,
};
