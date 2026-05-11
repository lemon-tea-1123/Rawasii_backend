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
  final idUser = body['id_users'] as String?;
  final idPost = body['id_post'] as String?;

  if (idUser == null || idPost == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'User ID and post ID are required'},
    );
  }

  final existingSave = await supabase
      .from('save_post')
      .select('id_save_post')
      .eq('user_id', idUser)
      .eq('post_id', idPost)
      .maybeSingle();

  if (existingSave != null) {
    await supabase
        .from('save_post')
        .delete()
        .eq('user_id', idUser)
        .eq('post_id', idPost);

    return Response.json(
      body: {'message': 'Post unsaved successfully'},
    );
  }

  await supabase.from('save_post').insert({
    'user_id': idUser,
    'post_id': idPost,
  });

  return Response.json(
    body: {'message': 'Post saved successfully'},
  );
}
