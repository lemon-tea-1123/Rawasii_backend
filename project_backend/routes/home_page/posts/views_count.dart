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


  try{
    final post = await supabase
    .from('post')
    .select('views_count')
    .eq('id_post', idPost)
    .single();

  final currentViews = post['views_count'] as int? ?? 0;


    await supabase
    .from('post')
    .update({'views_count': currentViews + 1,})
    .eq('id_post', idPost);
    return Response.json(
      body: {'message': 'Views count updated successfully'},
    );

  }catch(e){
    return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to update views count'},
    );
  }
  
}
