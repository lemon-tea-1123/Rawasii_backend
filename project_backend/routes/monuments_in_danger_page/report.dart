import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  // ✅ user_id depuis le token
  final user = context.read<Map<String, dynamic>>();
  final userId = user['id_users'] as int;

  final body = await context.request.json() as Map<String, dynamic>;

  final monumentName = body['monument_name'] as String?;
  final region = body['region'] as String?;
  final description = body['description'] as String?;
  final urgenceLevel = body['urgence_level'] as String?;
  final dangerType = body['danger_type'] as String?;
  final imageUrls = body['image_urls'] as List<dynamic>?;

  if (monumentName == null || region == null || description == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required fields'},
    );
  }

  try {
    final now = DateTime.now().toIso8601String();

    final result = await supabase
        .from('monument_in_danger')
        .insert({
          'user_id': userId,
          'monument_name': monumentName,
          'region': region,
          'description': description,
          'urgence_level': urgenceLevel ?? 'Medium',
          'status': 'Reported',
          'danger_type': dangerType ?? '',
          'views_count': 0,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    final monumentId = result['monument_in_danger_id'] as int;

    // ✅ Sauvegarde les images
    if (imageUrls != null && imageUrls.isNotEmpty) {
      for (final url in imageUrls) {
        await supabase.from('image').insert({
          'monument_in_danger_id': monumentId,
          'image_path': url.toString(),
          'created_at': now,
        });
      }
    }

    return Response.json(
      statusCode: 201,
      body: {
        'message': 'Monument reported successfully!',
        'monument_id': monumentId,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
