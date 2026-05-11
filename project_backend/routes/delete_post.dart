import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

// DELETE  /delete_post  — delete own post
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.delete) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;

  final postId = body['post_id'].toString();
  final userId = body['user_id'].toString();

  if (postId == null || userId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'post_id and user_id are required'},
    );
  }

  try {
    // ── Verify ownership ──────────────────────────────────────────────
    final existing = await supabase
        .from('post')
        .select('user_id')
        .eq('id_post', postId)
        .maybeSingle();

    if (existing == null) {
      return Response.json(statusCode: 404, body: {'error': 'Post not found'});
    }
    if (existing['user_id'].toString() != userId.toString()) {
      return Response.json(
          statusCode: 403,
          body: {'error': 'Not authorised to delete this post'});
    }

    // ── Delete child rows first (images, reactions, comments, notifs) ─
    await Future.wait([
      supabase.from('image').delete().eq('post_id', postId),
      supabase.from('reaction').delete().eq('post_id', postId),
      supabase.from('notification').delete().eq('post_id', postId),
    ]);
    // comments may have sub-rows — delete them after reactions
    await supabase.from('comment').delete().eq('post_id', postId);

    // ── Delete the post itself ────────────────────────────────────────
    await supabase.from('post').delete().eq('id_post', postId);

    return Response.json(body: {'message': 'Post deleted successfully'});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
