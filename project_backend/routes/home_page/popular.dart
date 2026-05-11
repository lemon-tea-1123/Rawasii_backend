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
  try{
    final postData=await supabase
    .from('post')
    .select('''
           id_post,
           user_id,
           title,
           description,
           localisation,
           historical_period,
           heritage_type,
           views_count,
           share_count,
           comment_count,
           reaction_count, 
           created_at,
           updated_at,
           image(
              id_image,
              image_path
           ),
           user(
              username,
              user_profile(
                  full_name,
                  profile_image_url

              )
           )
           ''')
    //sortting by 
    .order('views_count', ascending: false)
    .order('reaction_count', ascending: false)
    .order('comment_count', ascending: false)
    .order('share_count', ascending: false)
    .order('created_at',ascending: false)
    
    .limit(20);//the limit of popular posts
    return Response.json(
      body: postData,
    );

  }catch(e){
    return Response.json(
      statusCode: 500,
      body: {'error': 'Failed to fetch posts'},
    );
  }

}
