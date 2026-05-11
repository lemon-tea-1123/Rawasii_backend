import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod; // ← only this

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final supabase = context.read<SupabaseClient>();

  final body = await context.request.json() as Map<String, dynamic>;
  final idUser = body['id_users'] as String?;
  final content = body['content'] as String?;
  final idPost = body['id_post'] as String?;
  final idPostUser = body['id_post_user'] as String?;

  if (idUser == null ||
      content == null ||
      idPost == null ||
      idPostUser == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'All fields are required  '},
    );
  }

  try {
    // ── 1. insert comment ────────────────────────────────────────────────
    final addComment = await supabase
        .from('comment')
        .insert({
          'user_id': idUser,
          'post_id': idPost,
          'content': content,
        })
        .select() // ← select THEN single
        .single();

    print('Comment inserted: $addComment');

    // ── 2. update comment count ──────────────────────────────────────────
    final post = await supabase
        .from('post')
        .select('comment_count')
        .eq('id_post', idPost)
        .single();

    final currentCount = (post['comment_count'] as num?)?.toInt() ?? 0;

    await supabase
        .from('post')
        .update({'comment_count': currentCount + 1}).eq('id_post', idPost);

    // ── 3. insert notification (only if commenter != post owner) ─────────
    if (idUser != idPostUser) {
      final notif = await supabase
          .from('notification')
          .insert({
            'user_id': idPostUser, // ← post owner receives it
            'type': 'comment',
            'sender_id': idUser, // ← commenter
            'post_id': idPost,
            'comment_id': addComment['id_comments'],
            'is_read': false,
          })
          .select()
          .single();
      print('Notification inserted: $notif');
    } else {
      print('Skipped notification — user commenting on own post');
    }

    return Response.json(
      body: {
        'message': 'Comment added successfully',
        'comment': addComment,
      },
    );
  } catch (e) {
    print('CREATE COMMENT ERROR: $e'); // ← shows exact error in terminal
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
