import 'package:dart_frog/dart_frog.dart';
import '../../lib/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final monumentId = int.tryParse(
    context.request.uri.queryParameters['monument_id'] ?? '',
  );

  if (monumentId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'monument_id is required'},
    );
  }

  try {
    final actions = await supabase
        .from('mobilization_actions')
        .select()
        .eq('monument_in_danger_id', monumentId)
        .order('action_date', ascending: true);

    return Response.json(
      statusCode: 200,
      body: {'actions': actions},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
