import 'package:dart_frog/dart_frog.dart';
import 'package:project_backend/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async{
  final method=context.request.method; 
  if(method!=HttpMethod.get){
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );

  }

  final userIdParam = context.request.uri.queryParameters['user_id'];

  final userId = int.tryParse(userIdParam ?? '');
  if(userId == null){
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required field: user_id'},
    );
  }

  final followersCountResult=await supabase
  .from('user')
  .select('followers_count')
  .eq('id_users', userId)
  .single();

  return Response.json(
    body: {
      'followers_count': followersCountResult['followers_count'],
    },
  );
    
}
