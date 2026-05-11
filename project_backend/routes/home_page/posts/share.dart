import 'package:dart_frog/dart_frog.dart' ;
import 'package:project_backend/supabase_client.dart';


Future<Response> onRequest(RequestContext context) async {
  final method=context.request.method; //http request

  if(method!=HttpMethod.post){
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );

  }
  final body = await context.request.json() as Map<String, dynamic>;
  final idPost = body['id_post'] as String?; 
  if (idPost == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Post ID is required'},
    );
  }

  //final supabase = context.read<supa.SupabaseClient>();
  final post = await supabase
  .from ('post')
  .select('id_post,share_count')
  .eq('id_post',idPost)
  .maybeSingle();

  if(post==null){
    return Response.json(
      statusCode: 404,
      body: {'error': 'Post not found'},
    );
  }

  await supabase
  .from('post')
  .update({'share_count': (post['share_count'] as int) + 1})
  .eq('id_post', idPost);

  return Response.json(
    body: {'message': 'Post shared successfully'},
  );

  
}
