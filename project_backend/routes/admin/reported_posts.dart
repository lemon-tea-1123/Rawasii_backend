import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.get:
      return _getReportedPosts();
    case HttpMethod.delete:
      return _deletePost(context);
    case HttpMethod.put:
      return _approvePost(context);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
  }
}

Future<Response> _getReportedPosts() async {
  try {
    final reports = await supabase
        .from('report')
        .select('''
          report_id,
          reason,
          status,
          created_at,
          post_id,
          reporter:user_id (
            id_users,
            username,
            email
          ),
          post:post_id (
            id_post,
            title,
            description,
            status,
            reaction_count,
            comment_count,
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
          )
        ''')
        .not('post_id', 'is', null)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final Map<int, Map<String, dynamic>> postMap = {};

    for (final report in reports) {
      final postId = report['post_id'] as int?;
      if (postId == null) continue;

      if (!postMap.containsKey(postId)) {
        postMap[postId] = {
          ...report,
          'reporters': <Map<String, dynamic>>[],
          'signalements_count': 0,
        };
      }

      final reporter = report['reporter'] as Map<String, dynamic>? ?? {};
      final reason = report['reason'] ?? 'Non spécifié';
      final reportDate = report['created_at'] ?? '';

      (postMap[postId]!['reporters'] as List).add({
        'username': reporter['username'] ?? 'Unknown',
        'email': reporter['email'] ?? '',
        'reason': reason,
        'date': reportDate,
      });

      postMap[postId]!['signalements_count'] =
          (postMap[postId]!['signalements_count'] as int) + 1;
    }

    final result = postMap.values.toList();

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'count': result.length, 'reports': result},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _approvePost(RequestContext context) async {
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

    await supabase
        .from('report')
        .update({'status': 'resolved'}).eq('post_id', postId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'Post approved successfully'},
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
