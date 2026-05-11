import 'package:dart_frog/dart_frog.dart';
import 'package:project_backend/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async{
  final method=context.request.method; //http request

  if(method!=HttpMethod.get){
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );

  }

  //pagination(page number)
  final pagePosts = int.tryParse(
  context.request.uri.queryParameters['page'] ?? '1',
  ) ?? 1;
  //number of posts per page
  const limitPagePosts =  2;
  //calculate the offset for the query
  final offset = (pagePosts - 1) * limitPagePosts;

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
    .order('created_at', ascending: false)
    // the pagination (posts per page)
    .range(offset, offset + limitPagePosts-1);

   // .order('created_at',ascending: false);
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
