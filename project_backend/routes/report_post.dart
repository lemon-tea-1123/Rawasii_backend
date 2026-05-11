import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

// POST  /report_post
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;

  final userId = body['user_id'].toString();
  final postId = body['post_id'].toString();
  final commentId = body['comment_id']; // nullable
  final reason = body['reason'];

  if (userId == null || postId == null || reason == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'user_id, post_id and reason are required'},
    );
  }

  try {
    // ── Prevent duplicate reports from the same user ──────────────────
    final existing = await supabase
        .from('report')
        .select('report_id')
        .eq('user_id', userId)
        .eq('post_id', postId)
        .maybeSingle();

    if (existing != null) {
      return Response.json(
        statusCode: 409,
        body: {'error': 'You have already reported this post'},
      );
    }

    await supabase.from('report').insert({
      'user_id': userId,
      'post_id': postId,
      'comment_id': commentId,
      'reason': reason,
      'status': 'pending',
    });

    return Response.json(
      statusCode: 201,
      body: {'message': 'Report submitted successfully'},
    );
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
