import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:khuspus/db/queries/setting_queries.dart';

Future<String> sendAIRequest(String prompt) async {
  var modelName = await getSetting("aiModel");

  final response = await http.post(
    Uri.parse('http://localhost:11434/api/generate'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"model": modelName, "prompt": prompt, "stream": false}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["response"];
  } else {
    throw Exception(response.reasonPhrase);
  }
}
