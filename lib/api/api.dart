import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/models/configuration.dart';

class CallApi {
  String? _url;

  Future<void> _ensureInitialized() async {
    if (_url == null) {
      final links = await Configuration().getCountryApiLink();
      _url = links['api']!;
    }
  }

  Future<http.Response> postData(data, apiUrl) async {
    await _ensureInitialized(); // ensures _url is set
    var fullUrl = _url! + apiUrl;
    return await http.post(Uri.parse(fullUrl),
        body: jsonEncode(data), headers: _setHeaders());
  }

  Future<http.Response> getData(apiUrl) async {
    await _ensureInitialized(); // ensures _url is set
    var fullUrl = _url! + apiUrl;
    return await http.get(Uri.parse(fullUrl), headers: _setHeaders());
  }

  Map<String, String> _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };
}
