import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getComments();
    case HttpMethod.delete:
      return _deleteComment(context);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
  }
}

Future<Response> _getComments() async {
  try {
    final comments = await supabase.from('comment').select('''
          id_comments,
          content,
          reaction_count,
          created_at,
          user:user_id (
            id_users,
            username,
            email
          ),
          post:post_id (
            id_post,
            title
          )
        ''').order('created_at', ascending: false);

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'count': comments.length, 'comments': comments},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _deleteComment(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final commentId = body['comment_id'] as int?;

    if (commentId == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'comment_id is required'},
      );
    }

    final comment = await supabase
        .from('comment')
        .select('id_comments')
        .eq('id_comments', commentId)
        .maybeSingle();

    if (comment == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Comment not found'},
      );
    }

    await supabase.from('report').delete().eq('comment_id', commentId);
    await supabase.from('comment').delete().eq('id_comments', commentId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'Comment deleted successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
