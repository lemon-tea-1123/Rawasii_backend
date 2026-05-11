import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

// PUT  /update_post  — edit own post
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;

  final postId   = body['post_id'].toString();
  final userId   = body['user_id'];   // used to verify ownership
  final title    = body['title'];
  final description     = body['description'];
  final localisation    = body['localisation'];
  final historicalPeriod = body['historical_period'];
  final heritageType    = body['heritage_type'];

  if (postId == null || userId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'post_id and user_id are required'},
    );
  }

  try {
    
    // ── Verify the post belongs to this user ──────────────────────────
    final existing = await supabase
        .from('post')
        .select('user_id')
        .eq('id_post', postId)
        .maybeSingle();

    if (existing == null) {
      return Response.json(
          statusCode: 404, body: {'error': 'Post not found'});
    }
    if (existing['user_id'].toString() != userId.toString()) {
      return Response.json(
          statusCode: 403, body: {'error': 'Not authorised to edit this post'});
    }

    // ── Build only the fields that were actually sent ─────────────────
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title          != null) updates['title']             = title;
    if (description    != null) updates['description']       = description;
    if (localisation   != null) updates['localisation']      = localisation;
    if (historicalPeriod != null) updates['historical_period'] = historicalPeriod;
    if (heritageType   != null) updates['heritage_type']     = heritageType;

    await supabase.from('post').update(updates).eq('id_post', postId);

    return Response.json(body: {'message': 'Post updated successfully'});
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}