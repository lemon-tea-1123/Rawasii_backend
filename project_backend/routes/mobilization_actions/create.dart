import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final body = await context.request.json() as Map<String, dynamic>;

  final creatorId = body['creator_id'] as int?;
  final monumentId = body['monument_in_danger_id'] as int?;
  final actionType = body['action_type'] as String?;
  final description = body['description'] as String?;
  final actionDate = body['action_date'] as String?;

  if (creatorId == null ||
      monumentId == null ||
      actionType == null ||
      actionDate == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Missing required fields'},
    );
  }

  try {
    final now = DateTime.now().toIso8601String();

    final result = await supabase
        .from('mobilization_actions')
        .insert({
          'creator_id': creatorId,
          'monument_in_danger_id': monumentId,
          'action_type': actionType,
          'description': description ?? '',
          'action_date': actionDate,
          'created_at': now,
          'updated_at': now,
        })
        .select()
        .single();

    return Response.json(
      statusCode: 201,
      body: {
        'message': 'Action created successfully!',
        'action_id': result['mobilization_actions_id'],
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
