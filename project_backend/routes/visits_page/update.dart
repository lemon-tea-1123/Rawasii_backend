import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  // user_id vient du token automatiquement
  final user = context.read<Map<String, dynamic>>();
  final userId = user['id_users'] as int;

  final body = await context.request.json() as Map<String, dynamic>;
  final visitId = body['visit_id'] as int?;

  if (visitId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'visit_id is required'},
    );
  }

  try {
    // Vérifier que c'est bien la visite de cet utilisateur
    final check = await supabase
        .from('visit')
        .select('user_id')
        .eq('id_visit', visitId)
        .maybeSingle();

    if (check == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Visit not found'},
      );
    }

    if (check['user_id'] != userId) {
      return Response.json(
        statusCode: 403,
        body: {'error': 'Not authorized'},
      );
    }

    // Construire les champs à mettre à jour
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'updated_at': now,
    };

    if (body['monument_name'] != null)
      updates['monument_name'] = body['monument_name'];
    if (body['localisation'] != null)
      updates['localisation'] = body['localisation'];
    if (body['description'] != null)
      updates['description'] = body['description'];
    if (body['historical_period'] != null)
      updates['historical_period'] = body['historical_period'];
    if (body['heritage_type'] != null)
      updates['heritage_type'] = body['heritage_type'];

    // Mettre à jour la visite
    await supabase.from('visit').update(updates).eq('id_visit', visitId);

    // Mettre à jour les photos si envoyées
    final imageUrls = body['image_urls'] as List<dynamic>?;
    if (imageUrls != null) {
      if (imageUrls.length > 5) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Maximum 5 photos autorisées'},
        );
      }

      // Supprimer les anciennes photos
      await supabase.from('image').delete().eq('visit_id', visitId);

      // Insérer les nouvelles photos
      for (final url in imageUrls) {
        await supabase.from('image').insert({
          'visit_id': visitId,
          'image_path': url.toString(),
          'created_at': now,
          'max': 5,
        });
      }
    }

    return Response.json(
      statusCode: 200,
      body: {'message': 'Visit updated successfully!'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
