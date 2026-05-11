import 'package:dart_frog/dart_frog.dart';
import 'package:project_backend/supabase_client.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method; //http request

  if (method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }
  final supabase = context.read<SupabaseClient>();

  final body = await context.request.json() as Map<String, dynamic>;
  final idUser = body['user_id'] as String?;
  final idPost = body['post_id'] as String?;

  if (idUser == null || idPost == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'User ID and post ID are required'},
    );
  }

  final post = await supabase
      .from('post')
      .select('id_post,reaction_count,user_id')
      .eq('id_post', idPost)
      .maybeSingle();

  if (post == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Post not found'},
    );
  }

  final postOwnerId = post['user_id'];

  final reactionExist = await supabase
      .from('reaction')
      .select('id_reaction')
      .eq('user_id', idUser)
      .eq('post_id', idPost)
      .maybeSingle();

  if (reactionExist != null) {
    await supabase
        .from('reaction')
        .delete()
        .eq('user_id', idUser)
        .eq('post_id', idPost);

    await supabase
        .from('post')
        .update({'reaction_count': (post['reaction_count'] as int) - 1}).eq(
            'id_post', idPost);
    return Response.json(
      body: {'message': 'Reaction removed successfully'},
    );
  }

  await supabase.from('reaction').insert({
    'user_id': idUser,
    'post_id': idPost,
  });
  await supabase
      .from('post')
      .update({'reaction_count': (post['reaction_count'] as int) + 1}).eq(
          'id_post', idPost);
  if (postOwnerId != idUser) {
    await supabase.from('notification').insert({
      'user_id': postOwnerId,
      'type': 'like',
      'sender_id': idUser,
      'post_id': idPost,
      'comment_id': null,
      'is_read': false,
    });
  }

  return Response.json(
    body: {'message': 'Reaction added successfully'},
  );
}
