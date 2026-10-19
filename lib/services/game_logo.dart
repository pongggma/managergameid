import 'dart:convert';

import 'package:http/http.dart' as http;

/// Finds a game's icon by name using Apple's public iTunes Search API
/// (no API key needed). It covers most mobile games: Free Fire, PUBG Mobile,
/// Mobile Legends, ROV, Genshin Impact ...
/// Returns null when nothing matches (the app then shows the lettered badge).
class GameLogoService {
  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ກ-໿]'), '');

  static Future<String?> find(String game) async {
    final q = game.trim();
    if (q.length < 2) return null;
    final key = _norm(q);
    if (key.isEmpty) return null;
    for (final country in const ['us', 'th']) {
      try {
        final uri = Uri.https('itunes.apple.com', '/search', {
          'term': q,
          'entity': 'software',
          'media': 'software',
          'country': country,
          'limit': '8',
        });
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) continue;
        final results = (jsonDecode(res.body)['results'] as List?) ?? [];
        for (final r in results) {
          final m = Map<String, dynamic>.from(r as Map);
          final name = _norm((m['trackName'] as String?) ?? '');
          // Only accept results whose name really contains what was typed,
          // so a wrong app icon is never shown for an unknown game.
          if (name.contains(key)) {
            final url = (m['artworkUrl512'] ?? m['artworkUrl100']) as String?;
            if (url != null && url.isNotEmpty) return url;
          }
        }
      } catch (_) {
        // offline / timeout: try the next storefront, then give up
      }
    }
    return null;
  }
}
