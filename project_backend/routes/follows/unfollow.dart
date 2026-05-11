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



return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to fetch posts'},
    );
}
