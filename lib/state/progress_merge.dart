import 'dart:convert';
import 'dart:math' as math;

/// The saved keys that sync to the cloud. Settings (goal, sounds, reminder)
/// stay per device, and so does premium: it comes from the store's restore,
/// because a learner can write to their own cloud copy.
const List<String> kSyncedKeys = [
  'xp',
  'completed',
  'perfect',
  'streak',
  'bestStreak',
  'lastActive',
  'history',
  'challengeDay',
  'challengesDone',
];

/// Combines two copies of the learner's progress (this phone and the cloud)
/// without losing anything either side earned: the union of finished lessons,
/// the larger of each count, the most recent streak, and each day's best XP.
Map<String, String> mergeProgress(Map<String, String> a, Map<String, String> b) {
  int i(Map<String, String> m, String k) => int.tryParse(m[k] ?? '') ?? 0;
  Set<String> set(Map<String, String> m, String k) => (m[k] ?? '').split(',').where((s) => s.isNotEmpty).toSet();
  String? later(String? x, String? y) => x == null ? y : (y == null || x.compareTo(y) >= 0 ? x : y);
  Map<String, int> hist(Map<String, String> m) {
    try {
      return (jsonDecode(m['history'] ?? '{}') as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    } on Object {
      return {};
    }
  }

  final out = <String, String>{
    'xp': '${math.max(i(a, 'xp'), i(b, 'xp'))}',
    'completed': ({...set(a, 'completed'), ...set(b, 'completed')}.toList()..sort()).join(','),
    'perfect': ({...set(a, 'perfect'), ...set(b, 'perfect')}.toList()..sort()).join(','),
    'bestStreak': '${math.max(i(a, 'bestStreak'), i(b, 'bestStreak'))}',
    'challengesDone': '${math.max(i(a, 'challengesDone'), i(b, 'challengesDone'))}',
  };

  // The current streak belongs to whichever copy was active most recently.
  final lastA = a['lastActive'], lastB = b['lastActive'];
  final lastActive = later(lastA, lastB);
  if (lastActive != null) {
    out['lastActive'] = lastActive;
    out['streak'] =
        '${lastA == lastB ? math.max(i(a, 'streak'), i(b, 'streak')) : i(lastActive == lastA ? a : b, 'streak')}';
  } else {
    out['streak'] = '0';
  }

  final challengeDay = later(a['challengeDay'], b['challengeDay']);
  if (challengeDay != null) out['challengeDay'] = challengeDay;

  final ha = hist(a), hb = hist(b);
  out['history'] = jsonEncode({
    for (final day in {...ha.keys, ...hb.keys}) day: math.max(ha[day] ?? 0, hb[day] ?? 0),
  });
  return out;
}
