import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  final postId = context.request.uri.queryParameters['post_id'];
  final userId = context.request.uri.queryParameters['user_id'];

  if (postId == null || userId == null) {
    return Response.json(statusCode: 400, body: {'error': 'Missing params'});
  }

  final supabase = context.read<SupabaseClient>();

  try {
    final result = await supabase
        .from('reaction')           // ← your reactions table name
        .select('id_reaction')      // ← just check if row exists
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();             // ← returns null if not found

    return Response.json(body: {
      'is_liked': result != null,   // ← true if row exists
    });
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}