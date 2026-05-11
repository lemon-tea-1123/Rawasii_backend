
import 'package:dart_frog/dart_frog.dart' ;
import 'package:project_backend/supabase_client.dart';

Future<Response> onRequest(RequestContext context)async {
  final method=context.request.method; //http request

  if(method!=HttpMethod.post){
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );

  }

  final body =await context.request.json() as Map<String, dynamic>;
  final idUser = body['id_user'] as String?;
  final idPost = body['id_post'] as String?;
  final reason = body['reason'] as String?;

  if(idPost==null || idUser==null || reason==null){
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required fields'},
    );
  }


  final post= await supabase
  .from('post')
  .select('id_post')
  .eq('id_post',idPost)
  .maybeSingle();

  if(post==null){
    return Response.json(
      statusCode: 404,
      body: {'error': 'Post not found'},
    );
  }




//---------------------------------------
  final existingReport=await supabase
  .from('report')
  .select('user_id,post_id')
  .eq('user_id',idUser)
  .eq('post_id',idPost)
  .maybeSingle();
  if(existingReport != null){
    return Response.json(
      statusCode: 400,
      body: {'error': 'You have already reported this post'},
    );
  }
  //--------------------------------------
   

   await supabase
    .from('report')
    .insert({
      'user_id': idUser,
      'comment_id': null,
      'post_id': idPost,
      'reason': reason.trim(),
      'status': 'pending',
    });

  return Response.json(
    statusCode: 201,
    body: {'message': 'Post reported successfully'},
    );
}
