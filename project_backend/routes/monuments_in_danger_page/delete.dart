import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

// DELETE  /delete_post  — delete own post and all its child rows
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.delete) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;

  final postId = int.tryParse(['post_id'].toString());
  final userId = int.tryParse(body['user_id'].toString());

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

    // ── Step 1: delete all tables that reference post_id directly ─────
    // All run in parallel — none of these reference each other so order
    // between them doesn't matter. They MUST all finish before step 2.
    await Future.wait([
      supabase.from('image').delete().eq('post_id', postId),
      supabase.from('reaction').delete().eq('post_id', postId),
      supabase.from('notification').delete().eq('post_id', postId),
      supabase.from('save_post').delete().eq('post_id', postId),
      supabase.from('comment').delete().eq('post_id', postId),
    ]);

    // ── Step 2: delete the post itself — only after all children gone ─
    await supabase.from('post').delete().eq('id_post', postId);

    return Response.json(body: {'message': 'Post deleted successfully'});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
