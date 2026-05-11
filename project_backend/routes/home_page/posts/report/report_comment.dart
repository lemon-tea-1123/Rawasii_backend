
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
  final idComment = body['id_comment'] as String?;
  final reason = body['reason'] as String?;

  if(idComment==null || idUser==null || reason==null){
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required fields'},
    );
  }


  final comment= await supabase
  .from('comment')
  .select('id_comments')
  .eq('id_comments',idComment)
  .maybeSingle();

  if(comment==null){
    return Response.json(
      statusCode: 404,
      body: {'error': 'Comment not found'},
    );
  }




//---------------------------------------
  final existingReport=await supabase
  .from('report')
  .select('user_id,comment_id')
  .eq('user_id',idUser)
  .eq('comment_id',idComment)
  .maybeSingle();
  if(existingReport != null){
    return Response.json(
      statusCode: 400,
      body: {'error': 'You have already reported this comment'},
    );
  }
  //--------------------------------------
   

   await supabase
    .from('report')
    .insert({
      'user_id': idUser,
      'comment_id': idComment,
      'post_id':null,
      'reason': reason.trim(),
      'status': 'pending',
    });

  return Response.json(
    statusCode: 201,
    body: {'message': 'Comment reported successfully'},
    );
}
