import 'package:sqflite/sqflite.dart';

import '../domain/suggested_word.dart';

class Candidate {
  final String term;
  final String meaning;
  const Candidate(this.term, this.meaning);
  String get key => term.toLowerCase();
}

/// Bundled, frequency-ordered fallback data. Discover never needs the network.
const candidatePool = <Candidate>[
  Candidate('ability', 'יכולת; power to do something'),
  Candidate('accept', 'לקבל; agree to take'),
  Candidate('access', 'גישה; way to enter or use'),
  Candidate('account', 'חשבון; record or report'),
  Candidate('achieve', 'להשיג; succeed in doing'),
  Candidate('action', 'פעולה; something done'),
  Candidate('active', 'פעיל; doing things'),
  Candidate('admit', 'להודות; accept as true'),
  Candidate('affect', 'להשפיע; produce a change'),
  Candidate('agree', 'להסכים; have the same opinion'),
  Candidate('allow', 'לאפשר; let happen'),
  Candidate('amount', 'כמות; how much'),
  Candidate('appear', 'להופיע; become visible'),
  Candidate('apply', 'להגיש; make a request'),
  Candidate('approach', 'גישה; way of dealing with'),
  Candidate('argue', 'להתווכח; give reasons against'),
  Candidate('arrange', 'לארגן; put in order'),
  Candidate('assume', 'להניח; accept without proof'),
  Candidate('attend', 'להשתתף; go to'),
  Candidate('avoid', 'להימנע; keep away from'),
  Candidate('balance', 'איזון; a stable position'),
  Candidate('behave', 'להתנהג; act in a way'),
  Candidate('benefit', 'תועלת; a helpful result'),
  Candidate('calculate', 'לחשב; find a number'),
  Candidate('career', 'קריירה; working life'),
  Candidate('cause', 'לגרום; make happen'),
  Candidate('challenge', 'אתגר; difficult task'),
  Candidate('claim', 'לטעון; say something is true'),
  Candidate('compare', 'להשוות; examine differences'),
  Candidate('concern', 'דאגה; something important'),
  Candidate('conduct', 'לבצע; organize an activity'),
  Candidate('consider', 'לשקול; think about'),
  Candidate('contain', 'להכיל; have inside'),
  Candidate('contribute', 'לתרום; give to help'),
  Candidate('create', 'ליצור; make something new'),
  Candidate('decline', 'לסרב; say no'),
  Candidate('define', 'להגדיר; state the meaning'),
  Candidate('demand', 'דרישה; a need'),
  Candidate('depend', 'להיות תלוי; need something else'),
  Candidate('describe', 'לתאר; say what something is like'),
  Candidate('develop', 'לפתח; grow or improve'),
  Candidate('discover', 'לגלות; find for the first time'),
  Candidate('distance', 'מרחק; space between'),
  Candidate('effect', 'השפעה; a result'),
  Candidate('encourage', 'לעודד; give support'),
  Candidate('environment', 'סביבה; surrounding conditions'),
  Candidate('establish', 'להקים; start firmly'),
  Candidate('evidence', 'ראיה; facts showing truth'),
  Candidate('feature', 'מאפיין; important part'),
  Candidate('focus', 'להתמקד; give attention'),
  Candidate('frequent', 'תכוף; happening often'),
  Candidate('function', 'תפקיד; purpose'),
  Candidate('identify', 'לזהות; recognize'),
  Candidate('improve', 'לשפר; make better'),
  Candidate('include', 'לכלול; have as part'),
  Candidate('increase', 'להגדיל; become more'),
  Candidate('individual', 'אדם; one person'),
  Candidate('influence', 'השפעה; power to change'),
  Candidate('maintain', 'לשמור; keep in condition'),
  Candidate('measure', 'למדוד; find size'),
  Candidate('method', 'שיטה; way of doing'),
  Candidate('notice', 'להבחין; become aware'),
  Candidate('occur', 'להתרחש; happen'),
  Candidate('opportunity', 'הזדמנות; good chance'),
  Candidate('participate', 'להשתתף; take part'),
  Candidate('perform', 'לבצע; do'),
  Candidate('period', 'תקופה; length of time'),
  Candidate('policy', 'מדיניות; plan of action'),
  Candidate('prepare', 'להכין; get ready'),
  Candidate('prevent', 'למנוע; stop from happening'),
  Candidate('process', 'תהליך; series of actions'),
  Candidate('provide', 'לספק; give what is needed'),
  Candidate('purpose', 'מטרה; reason for doing'),
  Candidate('range', 'טווח; limits between'),
  Candidate('reduce', 'להפחית; make less'),
  Candidate('require', 'לדרוש; need'),
  Candidate('respond', 'להגיב; answer or react'),
  Candidate('result', 'תוצאה; what happens'),
  Candidate('reveal', 'לחשוף; make known'),
  Candidate('select', 'לבחור; choose'),
  Candidate('significant', 'משמעותי; important'),
  Candidate('similar', 'דומה; nearly the same'),
  Candidate('source', 'מקור; where something comes from'),
  Candidate('specific', 'מסוים; exact'),
  Candidate('suggest', 'להציע; put forward an idea'),
  Candidate('support', 'לתמוך; help'),
  Candidate('survey', 'סקר; study by questions'),
  Candidate('target', 'מטרה; intended result'),
  Candidate('tend', 'לנטות; usually do'),
  Candidate('transfer', 'להעביר; move between places'),
  Candidate('vary', 'להשתנות; be different'),
  Candidate('version', 'גרסה; form of something'),
];

class SuggestedWordsRepository {
  final Database db;
  final List<Candidate> pool;
  SuggestedWordsRepository(this.db, {this.pool = candidatePool});

  Future<List<SuggestedWord>> batch() async {
    final rows = await db.query(
      'suggested_words',
      where: 'status = ?',
      whereArgs: ['batch'],
      orderBy: 'batch_order',
    );
    return rows
        .map(
          (row) => SuggestedWord(
            key: row['english_key'] as String,
            term: row['term'] as String,
            rank: row['frequency_rank'] as int?,
            meaning:
                pool
                    .where((c) => c.key == row['english_key'])
                    .map((c) => c.meaning)
                    .firstOrNull ??
                '',
            order: row['batch_order'] as int,
            revealed: row['revealed_before_action'] == 1,
          ),
        )
        .toList();
  }

  Future<List<SuggestedWord>> loadOrCreateBatch() async {
    final current = await batch();
    if (current.isNotEmpty) return current;
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM suggested_words'),
    );
    return existing == 0 ? newBatch() : current;
  }

  Future<List<SuggestedWord>> newBatch() async {
    final now = DateTime.now().toUtc();
    await db.update(
      'suggested_words',
      {
        'status': 'skipped',
        'next_eligible_at': now.add(const Duration(days: 14)).toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      where: 'status = ?',
      whereArgs: ['batch'],
    );
    final excluded = await _excluded(now);
    final center = await _band();
    final candidates = pool
        .where((candidate) => !excluded.contains(candidate.key))
        .toList();
    final queuedRows = await db.query(
      'suggested_words',
      where: 'status = ?',
      whereArgs: ['queued'],
      orderBy: 'created_at',
    );
    final libraryKeys = (await db.query(
      'words',
      columns: ['english_key'],
    )).map((row) => row['english_key'] as String).toSet();
    final queued = queuedRows
        .where((row) => !libraryKeys.contains(row['english_key']))
        .toList();
    final used = <String>{};
    Candidate? closest(int target) {
      Candidate? result;
      for (final candidate in candidates) {
        if (used.contains(candidate.key)) continue;
        if (result == null ||
            (pool.indexOf(candidate) + 1 - target).abs() <
                (pool.indexOf(result) + 1 - target).abs()) {
          result = candidate;
        }
      }
      if (result != null) used.add(result.key);
      return result;
    }

    final probeDistance = (pool.length * .1).round().clamp(1, pool.length);
    final targets = [
      center - probeDistance,
      center,
      center,
      center + probeDistance,
      if (queued.isEmpty) center,
    ];
    final batchCandidates = targets
        .map(closest)
        .whereType<Candidate>()
        .toList();
    for (var i = 0; i < batchCandidates.length; i++) {
      final c = batchCandidates[i];
      final row = await db.query(
        'suggested_words',
        where: 'english_key = ?',
        whereArgs: [c.key],
      );
      final values = {
        'english_key': c.key,
        'term': c.term,
        'frequency_rank': pool.indexOf(c) + 1,
        'status': 'batch',
        'batch_order': i,
        'revealed_before_action': 0,
        'updated_at': now.toIso8601String(),
      };
      if (row.isEmpty) {
        await db.insert('suggested_words', {
          ...values,
          'skip_count': 0,
          'created_at': now.toIso8601String(),
        });
      } else {
        await db.update(
          'suggested_words',
          values,
          where: 'english_key = ?',
          whereArgs: [c.key],
        );
      }
    }
    if (queued.isNotEmpty) {
      final suggestion = queued.first;
      await db.update(
        'suggested_words',
        {
          'status': 'batch',
          'batch_order': 4,
          'revealed_before_action': 0,
          'updated_at': now.toIso8601String(),
        },
        where: 'english_key = ?',
        whereArgs: [suggestion['english_key']],
      );
    }
    return batch();
  }

  Future<void> refillGeminiQueue(
    Future<List<String>> Function(Set<String> excluded) fetch,
  ) async {
    final queued = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM suggested_words WHERE status = 'queued'",
      ),
    )!;
    if (queued >= 3) {
      return;
    }
    try {
      final excluded = await _excluded(DateTime.now().toUtc());
      for (final term in (await fetch(excluded)).take(3 - queued)) {
        final trimmed = term.trim();
        final key = trimmed.toLowerCase();
        if (!RegExp(r"^[a-z]+(?:[ '-][a-z]+)*$").hasMatch(key) ||
            excluded.contains(key)) {
          continue;
        }
        await db.insert('suggested_words', {
          'english_key': key,
          'term': trimmed,
          'status': 'queued',
          'skip_count': 0,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        excluded.add(key);
      }
    } catch (_) {
      // Discover remains fully usable when Gemini is offline or unavailable.
    }
  }

  Future<int> bandCenter() => _band();

  Future<Set<String>> _excluded(DateTime now) async {
    final words = await db.query('words', columns: ['english_key']);
    final suggestions = await db.query('suggested_words');
    return {
      ...words.map((r) => r['english_key'] as String),
      ...suggestions
          .where(
            (r) =>
                r['status'] != 'skipped' ||
                DateTime.tryParse(
                      (r['next_eligible_at'] as String?) ?? '',
                    )?.isAfter(now) ==
                    true,
          )
          .map((r) => r['english_key'] as String),
    };
  }

  Future<void> reveal(String key) => db.update(
    'suggested_words',
    {'revealed_before_action': 1},
    where: 'english_key = ?',
    whereArgs: [key],
  );

  Future<void> known(SuggestedWord word) async {
    if (word.rank != null) {
      await _adjustBand(word.rank!, word.revealed ? 20 : 50);
    }
    await _setStatus(word.key, 'known');
  }

  Future<void> skip(String key) async {
    final rows = await db.query(
      'suggested_words',
      columns: ['skip_count'],
      where: 'english_key = ?',
      whereArgs: [key],
    );
    final count = (rows.single['skip_count'] as int) + 1;
    final days = count == 1
        ? 14
        : count == 2
        ? 30
        : 90;
    await db.update(
      'suggested_words',
      {
        'status': 'skipped',
        'skip_count': count,
        'batch_order': null,
        'next_eligible_at': DateTime.now()
            .toUtc()
            .add(Duration(days: days))
            .toIso8601String(),
      },
      where: 'english_key = ?',
      whereArgs: [key],
    );
  }

  Future<void> markLearned(String key) async {
    final row = (await db.query(
      'suggested_words',
      where: 'english_key = ?',
      whereArgs: [key],
    )).single;
    final center = await _band();
    final rank = row['frequency_rank'] as int?;
    if (rank == null) {
      await _setStatus(key, 'learned');
      return;
    }
    await _setBand(_clamp(center + ((rank - center) * .2).round()));
    await _setStatus(key, 'learned');
  }

  Future<void> markLearnedIfSaved(String suggestedWordKey, String savedKey) =>
      suggestedWordKey == savedKey
      ? markLearned(suggestedWordKey)
      : Future.value();

  Future<Map<String, dynamic>> exportHistory() async {
    final history = await db.query(
      'suggested_words',
      columns: ['english_key', 'term', 'status', 'updated_at'],
      where: "status IN ('known', 'learned')",
    );
    return {
      'bandCenter': await _band(),
      for (final status in ['known', 'learned'])
        status: history
            .where((row) => row['status'] == status)
            .map(
              (row) => {
                'key': row['english_key'],
                'term': row['term'],
                'updatedAt': row['updated_at'],
              },
            )
            .toList(),
    };
  }

  Future<void> mergeHistory(Map<String, dynamic> history) async {
    await db.transaction((txn) async {
      for (final status in ['known', 'learned']) {
        for (final record in history[status] as List) {
          final values = record as Map<String, dynamic>;
          final key = values['key'] as String;
          final term = (values['term'] as String?) ?? key;
          final existing = await txn.query(
            'suggested_words',
            where: 'english_key = ?',
            whereArgs: [key],
          );
          final candidate = pool
              .where((candidate) => candidate.key == key)
              .firstOrNull;
          final statusValues = {
            'term': term,
            'frequency_rank': candidate == null
                ? null
                : pool.indexOf(candidate) + 1,
            'status': status,
            'batch_order': null,
            'updated_at': values['updatedAt'],
          };
          if (existing.isEmpty) {
            await txn.insert('suggested_words', {
              'english_key': key,
              ...statusValues,
              'revealed_before_action': 0,
              'skip_count': 0,
              'created_at': values['updatedAt'],
            });
          } else {
            await txn.update(
              'suggested_words',
              statusValues,
              where: 'english_key = ?',
              whereArgs: [key],
            );
          }
        }
      }
      await txn.insert('settings', {
        'name': 'discovery_band_center',
        'value': '${_clamp(history['bandCenter'] as int)}',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> _setStatus(String key, String status) => db.update(
    'suggested_words',
    {
      'status': status,
      'batch_order': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    where: 'english_key = ?',
    whereArgs: [key],
  );
  Future<int> _band() async {
    final rows = await db.query(
      'settings',
      where: 'name = ?',
      whereArgs: ['discovery_band_center'],
    );
    return rows.isEmpty
        ? (pool.length ~/ 2)
        : int.tryParse(rows.single['value'] as String) ?? (pool.length ~/ 2);
  }

  Future<void> _adjustBand(int rank, int delta) async =>
      _setBand(_clamp((await _band()) + delta));
  Future<void> _setBand(int value) => db.insert('settings', {
    'name': 'discovery_band_center',
    'value': '$value',
  }, conflictAlgorithm: ConflictAlgorithm.replace);
  int _clamp(int value) => value.clamp(1, pool.length);
}
