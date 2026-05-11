import 'package:dart_frog/dart_frog.dart';
import '../../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final posts = await supabase.from('post').select('created_at');

    final Map<String, int> dayCount = {};
    for (final post in posts) {
      final date = DateTime.parse(post['created_at'].toString());
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dayCount[key] = (dayCount[key] ?? 0) + 1;
    }

    final result = dayCount.entries
        .map((e) => {'month': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));

    return Response.json(statusCode: 200, body: {'data': result});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
