import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getPosts();
    case HttpMethod.delete:
      return _deletePost(context);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
  }
}

Future<Response> _getPosts() async {
  try {
    final posts = await supabase.from('post').select('''
          id_post,
          title,
          description,
          localisation,
          reaction_count,
          comment_count,
          created_at,
          user:user_id (
            id_users,
            username,
            email
          ),
          image (
            id_image,
            image_path
          ),
          reaction (
            user:user_id (
              username
            )
          ),
          comment (
            id_comments,
            content,
            created_at,
            user:user_id (
              username
            ),
            report!report_comment_id_fkey (
              report_id,
              reason,
              status
            )
          )
        ''').order('created_at', ascending: false);

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'count': posts.length, 'posts': posts},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _deletePost(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final postId = body['post_id'] as int?;

    if (postId == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'post_id is required'},
      );
    }

    final post = await supabase
        .from('post')
        .select('id_post')
        .eq('id_post', postId)
        .maybeSingle();

    if (post == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Post not found'},
      );
    }

    await supabase.from('image').delete().eq('post_id', postId);
    await supabase.from('reaction').delete().eq('post_id', postId);
    await supabase.from('report').delete().eq('post_id', postId);
    await supabase.from('comment').delete().eq('post_id', postId);
    await supabase.from('post').delete().eq('id_post', postId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'Post deleted successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
