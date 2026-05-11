import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.put) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final user = context.read<Map<String, dynamic>>();
  final userId = user['id_users'] as int;

  final body = await context.request.json() as Map<String, dynamic>;
  final monumentId = body['monument_id'] as int?;
  final newStatus = body['status'] as String?;

  if (monumentId == null || newStatus == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'monument_id and status are required'},
    );
  }

  final validStatuses = ['Reported', 'Under intervention', 'Saved', 'Lost'];
  if (!validStatuses.contains(newStatus)) {
    return Response.json(
      statusCode: 400,
      body: {
        'error':
            'Invalid status. Use: Reported, Under intervention, Saved, Lost'
      },
    );
  }

  try {
    // ✅ Vérifie que c'est bien le créateur du monument
    final check = await supabase
        .from('monument_in_danger')
        .select('user_id')
        .eq('monument_in_danger_id', monumentId)
        .maybeSingle();

    if (check == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Monument not found'},
      );
    }

    if (check['user_id'] != userId) {
      return Response.json(
        statusCode: 403,
        body: {'error': 'Not authorized'},
      );
    }

    final now = DateTime.now().toIso8601String();
    await supabase.from('monument_in_danger').update({
      'status': newStatus,
      'updated_at': now,
    }).eq('monument_in_danger_id', monumentId);

    return Response.json(
      statusCode: 200,
      body: {'message': 'Status updated successfully!'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
