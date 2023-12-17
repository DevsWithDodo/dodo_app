import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:csocsort_szamla/config.dart';
import 'package:csocsort_szamla/data/providers/api/token_manager.dart';
import 'package:http/http.dart' as http;
export 'package:http/http.dart'
    show Response, StreamedResponse, BaseRequest, Request, MultipartRequest, ByteStream, Client;

class HttpException {
  final String message;
  final int statusCode;

  HttpException(this.message, this.statusCode);

  @override
  String toString() {
    return 'HttpException{message: $message, statusCode: $statusCode}';
  }
}

Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
  return await http.get(url, headers: _generateHeaders(headers));
}

enum HttpMethods { GET, POST, PUT, PATCH, DELETE, HEAD }

http.Response catchErrors(HttpMethods method, http.Response response, Uri url, [Object? body]) {
  if (APP_DEBUG) {
    print('${method.toString()}: $url');
    print('BODY: ${jsonEncode(body)}');
    print('RESPONSE: ${response.body}');
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(response.body, response.statusCode);
  }
  return response;
}

Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await http.post(url, headers: _generateHeaders(headers), body: jsonEncode(body), encoding: encoding);
  return catchErrors(HttpMethods.POST, response, url, body);
}

Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response = await http.put(url, headers: _generateHeaders(headers), body: jsonEncode(body), encoding: encoding);
  return catchErrors(HttpMethods.PUT, response, url, body);
}

Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final response =
      await http.patch(url, headers: _generateHeaders(headers), body: jsonEncode(body), encoding: encoding);
  return catchErrors(HttpMethods.PATCH, response, url, body);
}

Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
  final response = await http.delete(url, headers: _generateHeaders(headers));
  return catchErrors(HttpMethods.DELETE, response, url);
}

Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
  final response = await http.head(url, headers: _generateHeaders(headers));
  return catchErrors(HttpMethods.HEAD, response, url);
}

Map<String, String> _generateHeaders(Map<String, String>? headers) {
  String? token = TokenManager.getToken();

  headers ??= {};
  headers['Content-Type'] = 'application/json';

  if (token != null) {
    headers['Authorization'] = "Bearer $token";
  }

  return headers;
}

final List<_Uri> namedUris = [
  _Uri('users.index', '/users'),
  _Uri('users.show', '/users/:id', params: ['id']),
  _Uri('users.update', '/users/:id', params: ['id']),
  _Uri('users.delete', '/users/:id', params: ['id']),
  _Uri('sign-up', '/register'),
  _Uri('login', '/login'),
];

Uri generateUri(String name, {Map<String, dynamic>? params, Map<String, dynamic>? queryParameters}) {
  _Uri? uri = namedUris.firstWhereOrNull((element) => element.name == name);

  if (uri == null) {
    throw Exception('No uri found with name: $name');
  }

  String uriString = uri.uri;

  if (uri.params != null) {
    uri.params!.forEach((param) {
      if (params == null || !params.containsKey(param)) {
        throw Exception('Missing parameter: $param');
      }

      uriString = uriString.replaceAll(':$param', params[param].toString());
    });
  }

  return Uri.parse(TEST_URL + uriString).replace(queryParameters: queryParameters);
}

class _Uri {
  final String name;
  final String uri;
  final List<String>? params;

  _Uri(this.name, this.uri, {this.params});
}
