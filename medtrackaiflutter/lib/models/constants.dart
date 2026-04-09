// ══════════════════════════════════════════════
// CONSTANTS & DESIGN TOKENS
// ══════════════════════════════════════════════

const String kModel = 'claude-sonnet-4-20250514';
const String kAnthropicBaseUrl = 'https://api.anthropic.com/v1/messages';

// Promo codes
const Map<String, Map<String, dynamic>> kPromoCodes = {
  'WELCOME': {'discount': 100, 'label': 'Free 30 days', 'type': 'trial'},
  'HEALTH50': {
    'discount': 50,
    'label': '50% off first month',
    'type': 'percent'
  },
  'PILL30': {'discount': 30, 'label': '30% off', 'type': 'percent'},
  'MEDAI': {'discount': 100, 'label': 'Free 14 days', 'type': 'trial'},
  'FRIEND': {'discount': 20, 'label': '20% off forever', 'type': 'forever'},
};

// Pill colors (hex strings)
const List<String> kPillColors = [
  '#10B981',
  '#3B82F6',
  '#8B5CF6',
  '#F59E0B',
  '#EF4444',
  '#14B8A6',
  '#EC4899',
  '#F97316',
];

const List<String> kDays7 = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const List<String> kDays7Short = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

// Quick alarm presets
const List<Map<String, dynamic>> kQuickTimes = [
  {'label': 'Morning', 'h': 8, 'm': 0, 'emoji': '☀️'},
  {'label': 'Afternoon', 'h': 13, 'm': 0, 'emoji': '✨'},
  {'label': 'Evening', 'h': 18, 'm': 0, 'emoji': '🌊'},
  {'label': 'Night', 'h': 21, 'm': 0, 'emoji': '🌌'},
];

// Streak milestones
const List<Map<String, dynamic>> kMilestones = [
  {'days': 3, 'emoji': '🛡️', 'label': '3 Days'},
  {'days': 7, 'emoji': '⚡', 'label': '1 Week'},
  {'days': 14, 'emoji': '⚔️', 'label': '2 Weeks'},
  {'days': 30, 'emoji': '🏆', 'label': '1 Month'},
  {'days': 60, 'emoji': '💎', 'label': '2 Months'},
  {'days': 100, 'emoji': '👑', 'label': '100 Days'},
  {'days': 365, 'emoji': '🪐', 'label': '1 Year'},
];

// Gender options
const List<Map<String, String>> kGenders = [
  {'v': 'Male', 'e': '🧬'},
  {'v': 'Female', 'e': '🧬'},
  {'v': 'Non-binary', 'e': '✨'},
  {'v': 'Prefer not', 'e': '🔐'},
];

// Health goals
const List<Map<String, String>> kHealthGoals = [
  {'v': 'Manage chronic condition', 'e': '🔬'},
  {'v': 'Stay on top of prescriptions', 'e': '🛡️'},
  {'v': 'Support family member', 'e': '🤝'},
  {'v': 'Post-surgery recovery', 'e': '🪄'},
  {'v': 'General wellness', 'e': '✨'},
  {'v': 'Mental health support', 'e': '🌊'},
];

// Health conditions
const List<Map<String, String>> kConditions = [
  {'v': 'Diabetes', 'e': '🩸'},
  {'v': 'Hypertension', 'e': '💓'},
  {'v': 'Heart disease', 'e': '❤️'},
  {'v': 'Asthma', 'e': '🫧'},
  {'v': 'Thyroid', 'e': '🧬'},
  {'v': 'Arthritis', 'e': '🦴'},
  {'v': 'Depression', 'e': '🌌'},
  {'v': 'Anxiety', 'e': '🌊'},
  {'v': 'None', 'e': '🛡️'},
];

// Pain points / Struggle
const List<Map<String, String>> kPainPoints = [
  {'v': 'Forgetting to take doses', 'e': '📉'},
  {'v': 'Complex schedules (e.g. alternating days)', 'e': '🗓️'},
  {'v': 'Running out of pills', 'e': '⚠️'},
  {'v': 'Not having data for my doctor', 'e': '📊'},
  {'v': 'Managing for someone else', 'e': '👥'},
];

// Med count options
const List<Map<String, String>> kMedCounts = [
  {'v': '1', 'e': '1️⃣'},
  {'v': '2–3', 'e': '2️⃣'},
  {'v': '4–6', 'e': '🔢'},
  {'v': '7+', 'e': '📦'},
];

// Forget patterns
const List<Map<String, String>> kForgetPatterns = [
  {'v': 'Morning rush', 'e': '☕'},
  {'v': 'After work', 'e': '🌆'},
  {'v': 'Bedtime', 'e': '🌙'},
  {'v': 'Midday', 'e': '☀️'},
  {'v': 'Varies', 'e': '🎲'},
];

// Doctor visit frequency
const List<Map<String, String>> kDoctorVisits = [
  {'v': 'Weekly', 'e': '📅'},
  {'v': 'Monthly', 'e': '🗓️'},
  {'v': 'Every 3 months', 'e': '📆'},
  {'v': 'Twice a year', 'e': '📋'},
  {'v': 'Rarely', 'e': '🌬️'},
];

// Support options
const List<Map<String, String>> kSupport = [
  {'v': 'Yes, family member', 'e': '🫂'},
  {'v': 'Yes, caregiver', 'e': '🧑‍🔬'},
  {'v': 'Managing alone', 'e': '🦾'},
  {'v': 'It varies', 'e': '🔄'},
];

// Challenges
const List<Map<String, String>> kChallenges = [
  {'v': 'Remembering times', 'e': '⏰'},
  {'v': 'Side effects', 'e': '⚠️'},
  {'v': 'Cost of meds', 'e': '💳'},
  {'v': 'Complex schedule', 'e': '📋'},
  {'v': 'Motivation', 'e': '⚡'},
  {'v': 'Tracking refills', 'e': '📦'},
];

// Previous app experience
const List<Map<String, String>> kPrevApp = [
  {'v': 'Never', 'e': '💎'},
  {'v': 'Yes, but stopped using', 'e': '🛠️'},
  {'v': 'Currently using one', 'e': '🔄'},
  {'v': 'Used many apps', 'e': '📱'},
];

// Motivation
const List<Map<String, String>> kMotivation = [
  {'v': 'Living longer', 'e': '⏳'},
  {'v': 'My family', 'e': '🫂'},
  {'v': 'Feeling better', 'e': '✨'},
  {'v': "Doctor's orders", 'e': '🩺'},
  {'v': 'Saving money', 'e': '💰'},
  {'v': 'Sport & fitness', 'e': '🏅'},
];

// Reminder styles
const List<Map<String, String>> kReminderStyles = [
  {'v': 'Gentle nudge', 'e': '🫧'},
  {'v': 'Firm reminder', 'e': '🔔'},
  {'v': 'With health tip', 'e': '🔬'},
  {'v': 'With motivation', 'e': '⚡'},
];

// Caregiver avatars
const List<String> kCgAvatars = [
  '👨',
  '👩',
  '👴',
  '👵',
  '👦',
  '👧',
  '🧑',
  '👨‍⚕️',
  '👩‍⚕️',
  '🧓',
  '🧑‍🦱',
  '🧑‍🦳',
];

// Caregiver relations
const List<String> kCgRelations = [
  'Spouse',
  'Parent',
  'Son',
  'Daughter',
  'Sibling',
  'Friend',
  'Doctor',
  'Caregiver',
];

// Medicine forms
const List<String> kMedForms = [
  'tablet',
  'capsule',
  'pill',
  'liquid',
  'syrup',
  'spray',
  'inhaler',
  'drops',
  'cream',
  'injection',
  'other',
];

// Supported countries for regional AI context
const List<Map<String, String>> kCountries = [
  {'v': 'United States', 'e': '🇺🇸', 'c': 'US'},
  {'v': 'United Kingdom', 'e': '🇬🇧', 'c': 'GB'},
  {'v': 'Spain', 'e': '🇪🇸', 'c': 'ES'},
  {'v': 'Mexico', 'e': '🇲🇽', 'c': 'MX'},
  {'v': 'Colombia', 'e': '🇨🇴', 'c': 'CO'},
  {'v': 'Argentina', 'e': '🇦🇷', 'c': 'AR'},
  {'v': 'Chile', 'e': '🇨🇱', 'c': 'CL'},
  {'v': 'Japan', 'e': '🇯🇵', 'c': 'JP'},
  {'v': 'Australia', 'e': '🇦🇺', 'c': 'AU'},
  {'v': 'Canada', 'e': '🇨🇦', 'c': 'CA'},
  {'v': 'Germany', 'e': '🇩🇪', 'c': 'DE'},
  {'v': 'France', 'e': '🇫🇷', 'c': 'FR'},
  {'v': 'India', 'e': '🇮🇳', 'c': 'IN'},
  {'v': 'Brazil', 'e': '🇧🇷', 'c': 'BR'},
  {'v': 'Singapore', 'e': '🇸🇬', 'c': 'SG'},
  {'v': 'South Korea', 'e': '🇰🇷', 'c': 'KR'},
  {'v': 'Israel', 'e': '🇮🇱', 'c': 'IL'},
];

// ══════════════════════════════════════════════
// CAL AI STYLE DEMOGRAPHIC CONSTANTS
// ══════════════════════════════════════════════

// Demographic tracking target
const List<Map<String, String>> kTrackingTargets = [
  {'v': 'Just myself', 'e': '🙋'},
  {'v': 'A family member', 'e': '🫂'},
  {'v': 'Both', 'e': '👪'},
];

// Age brackets
const List<Map<String, String>> kAgeBrackets = [
  {'v': '18 - 29', 'e': '🌱'},
  {'v': '30 - 39', 'e': '🌿'},
  {'v': '40 - 49', 'e': '🌳'},
  {'v': '50 - 59', 'e': '🍂'},
  {'v': '60+', 'e': '🏔️'},
];

// Biological Sex for algorithms
const List<Map<String, String>> kBiologicalSex = [
  {'v': 'Male', 'e': '🧬'},
  {'v': 'Female', 'e': '🧬'},
  {'v': 'Other / Prefer not to say', 'e': '✨'},
];

// Current Tracking Methods
const List<Map<String, String>> kCurrentMethods = [
  {'v': 'I just try to remember', 'e': '🧠'},
  {'v': 'Pillbox / Organizer', 'e': '🍱'},
  {'v': 'Notes app or alarm', 'e': '📱'},
  {'v': 'Another tracking app', 'e': '🔄'},
];

// Forget frequency
const List<Map<String, String>> kForgetFreq = [
  {'v': 'Rarely (0-1 times/month)', 'e': '🏆'},
  {'v': 'Sometimes (1-2 times/week)', 'e': '⚠️'},
  {'v': 'Often (3+ times/week)', 'e': '📉'},
];
