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

  final idUser = body['user_id'];
  final title = body['title'];
  final description = body['description'];
  final localisation = body['localisation'];
  final historicalPeriod = body['historical_period'];
  final heritageType = body['heritage_type'];

  // final imagesPaths=body['images_paths'] as List<dynamic>;
  final imagesPaths = (body['images_paths'] as List<dynamic>?) ?? [];

  if (idUser == null || imagesPaths.isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required fields'},
    );
  }

  if (imagesPaths.length > 5) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Too many images. Maximum allowed is 5'},
    );
  }

  try {
    final post = await supabase
        .from('post')
        .insert({
          'user_id': idUser,
          'title': title,
          'description': description,
          'localisation': localisation,
          'historical_period': historicalPeriod,
          'heritage_type': heritageType,
          'views_count': 0,
          'share_count': 0,
          'comment_count': 0,
          'reaction_count': 0,
        })
        .select('id_post')
        .single();

    final postId = post['id_post'];

    final images = imagesPaths
        .map(
          (path) => {
            'image_path': path.toString(),
            'post_id': postId,
          },
        )
        .toList();

    await supabase.from('image').insert(images);

    return Response.json(
      statusCode: 201,
      body: {'message': 'Post created successfully'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
