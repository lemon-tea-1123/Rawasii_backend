import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method not allowed'},
    );
  }

  try {
    final body = await request.json() as Map<String, dynamic>;

    final commentId = body['comment_id'] as int?;
    final userId = body['user_id'] as int?;

    if (commentId == null || userId == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'error': 'comment_id and user_id are required'
        },
      );
    }

    // Check if user already liked this comment
    final existingLike = await supabase
        .from('comment_likes')
        .select()
        .eq('comment_id', commentId)
        .eq('user_id', userId)
        .maybeSingle();

    // Get current comment
    final comment = await supabase
        .from('comment')
        .select('reaction_count')
        .eq('id_comments', commentId)
        .single();

    int currentLikes = int.tryParse(comment['reaction_count'].toString()) ?? 0;
    bool isLiked = existingLike != null;

    if (isLiked) {
      // UNLIKE
      await supabase
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', userId);

      currentLikes = currentLikes - 1;
      if (currentLikes < 0) currentLikes = 0;
    } else {
      // LIKE
      await supabase.from('comment_likes').insert({
        'comment_id': commentId,
        'user_id': userId,
      });

      currentLikes = currentLikes + 1;
    }

    // Update comment
    await supabase.from('comment').update({
      'reaction_count': currentLikes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id_comments', commentId);

    return Response.json(
      body: {
        'success': true,
        'liked': !isLiked,
        'likes': currentLikes,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'error': e.toString()},
    );
  }
}
