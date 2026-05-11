import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  // user_id vient du token automatiquement
  final user = context.read<Map<String, dynamic>>();
  final userId = user['id_users'] as int;

  final body = await context.request.json() as Map<String, dynamic>;

  final monumentName = body['monument_name'] as String?;
  final localisation = body['localisation'] as String?;
  final description = body['description'] as String?;
  final historicalPeriod = body['historical_period'] as String?;
  final heritageType = body['heritage_type'] as String?;
  final imageUrls = body['image_urls'] as List<dynamic>?;

  if (monumentName == null || localisation == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required fields'},
    );
  }

  if (imageUrls != null && imageUrls.length > 5) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Maximum 5 photos autorisées'},
    );
  }

  try {
    final now = DateTime.now().toIso8601String();

    // 1. Insérer dans la table visit
    final result = await supabase
        .from('visit')
        .insert({
          'user_id': userId,
          'monument_name': monumentName,
          'localisation': localisation,
          'description': description ?? '',
          'historical_period': historicalPeriod ?? '',
          'heritage_type': heritageType ?? '',
          'reaction_count': 0,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    final visitId = result['id_visit'] as int;

    // 2. Insérer les photos dans la table image
    if (imageUrls != null && imageUrls.isNotEmpty) {
      for (final url in imageUrls.take(5)) {
        await supabase.from('image').insert({
          'visit_id': visitId,
          'image_path': url.toString(),
          'created_at': now,
          'max': 5,
        });
      }
    }

    return Response.json(
      statusCode: 201,
      body: {
        'message': 'Visit created successfully!',
        'visit_id': visitId,
        'images_saved': imageUrls?.length ?? 0,
      },
    );
  } catch (e, stack) {
    print('CREATE ERROR: $e');
    print('STACK: $stack');
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
