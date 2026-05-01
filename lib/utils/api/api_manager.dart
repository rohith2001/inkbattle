import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:inkbattle_frontend/config/environment.dart';
import 'package:inkbattle_frontend/utils/preferences/local_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:inkbattle_frontend/services/native_log_service.dart';

import 'api_exceptions.dart';
import 'error_model.dart';

const String jsonContentType = 'application/json';
String? token = "";

class ApiManager {
  Future _getToken() async {
    token = await LocalStorageUtils.fetchToken();
    NativeLogService.log(
      'ApiManager -> token: $token',
      tag: 'ApiManager',
      level: 'debug',
    );
  }

  var httpClient = http.Client();
  final Dio _client = Dio();

  Future<dynamic> get(
    String? url, {
    String? contentType,
    bool isTokenMandatory = false,
  }) async {
    await _getToken();
    try {
      // Check if token is required but not available
      if (isTokenMandatory && (token == null || token!.isEmpty)) {
        throw UnauthorisedException(
          'Authentication required. Please sign in again.',
          {'error': 'missing_token'},
        );
      }
      
      Map<String, String> headers = {
        'Content-Type': contentType ?? jsonContentType,
        'Accept': jsonContentType,
        'X-App-Secret': Environment.appSecret,
      };
      if (isTokenMandatory && token != null && token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      log("\x1B[32m${"URL -> $url"}\x1B[0m");
      final response = await http.get(
        Uri.parse(url ?? ""),
        headers: headers,
      );
      var responseJson = _returnResponse(response);
      return responseJson;
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
  }

  Future<dynamic> post(
    String? url,
    var parameters, {
    String contentType = jsonContentType,
    bool isTokenMandatory = false,
    Map<String, String>? headersParams,
  }) async {
    await _getToken();
    try {
      // Check if token is required but not available
      if (isTokenMandatory && (token == null || token!.isEmpty)) {
        throw UnauthorisedException(
          'Authentication required. Please sign in again.',
          {'error': 'missing_token'},
        );
      }
      
      Map<String, String> headers = {
        'Content-Type': contentType,
        'Accept': jsonContentType,
        'X-App-Secret': Environment.appSecret,
      };
      if (headersParams != null) {
        headers.addAll(headersParams);
      }
      if (isTokenMandatory && token != null && token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.post(
        Uri.parse(url ?? ""),
        headers: headers,
        body: jsonEncode(parameters),
      );

      log("\x1B[35m${"Payload -> $parameters"}\x1B[0m");
      log('\x1B[32m${"URL -> ${response.request?.url}"}\x1B[0m');
      // log("\x1B[35m${'Response body -> ${response.body}'}\x1B[0m");
      log("URL -> ${response.request?.url}");

      var responseJson = _returnResponse(response);
      return responseJson;
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
  }

  Future<dynamic> put(
    String? url,
    var parameters, {
    String contentType = jsonContentType,
    bool isTokenMandatory = false,
  }) async {
    await _getToken();
    try {
      // Check if token is required but not available
      if (isTokenMandatory && (token == null || token!.isEmpty)) {
        throw UnauthorisedException(
          'Authentication required. Please sign in again.',
          {'error': 'missing_token'},
        );
      }
      
      Map<String, String> headers = {
        'Content-Type': contentType,
        'Accept': jsonContentType,
        'X-App-Secret': Environment.appSecret,
      };

      if (isTokenMandatory && token != null && token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.put(
        Uri.parse(url ?? ""),
        headers: headers,
        body: jsonEncode(parameters),
      );
      log("\x1B[35m${"Payload -> $parameters"}\x1B[0m");
      log('\x1B[32m${"URL -> ${response.request?.url}"}\x1B[0m');
      // log("\x1B[35m${'Response body -> ${response.body}'}\x1B[0m");
      log("URL -> ${response.request?.url}");

      var responseJson = _returnResponse(response);
      return responseJson;
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
  }

  Future<dynamic> delete(
    String? url, {
    String contentType = jsonContentType,
    bool isTokenMandatory = true,
  }) async {
    await _getToken();
    try {
      Map<String, String> headers = {
        'Content-Type': contentType,
        'Accept': jsonContentType,
        'X-App-Secret': Environment.appSecret,
      };

      if (isTokenMandatory && token != null && token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.delete(
        Uri.parse(url ?? ""),
        headers: headers,
      );

      log('\x1B[32m${"URL -> ${response.request?.url}"}\x1B[0m');
      log("\x1B[31m${'Response body -> ${response.body}'}\x1B[0m");

      var responseJson = _returnResponse(response);
      return responseJson;
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }
  }

  Future dioPutFile(
      {required String? url,
      XFile? uploadFile,
      required int fileLength,
      dynamic data,
      String? contentType}) async {
    Options options = Options(
        contentType: contentType ?? lookupMimeType(uploadFile?.path ?? ""),
        headers: {
          'Accept': "*/*",
          'Content-Length': fileLength,
          'Connection': 'keep-alive',
        });

    final response = await _client.put(url ?? "",
        data: data ?? uploadFile?.openRead(),
        options: options, onSendProgress: (val1, val2) {
      log("${val1 / val2 * 100}");
    });
    log("Res ${response.statusCode}");
    if (response.statusCode == 200) {
      log("file upload successfully");
    }
  }

  dynamic _returnResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final trimmedBody = response.body.trimLeft();
    final bool looksLikeHtml =
        contentType.toLowerCase().contains('text/html') ||
        trimmedBody.toLowerCase().startsWith('<!doctype html') ||
        trimmedBody.toLowerCase().startsWith('<html') ||
        trimmedBody.startsWith('<');
    if (looksLikeHtml) {
      final location = response.headers['location'] ?? '';
      final preview = trimmedBody.length > 200
          ? trimmedBody.substring(0, 200)
          : trimmedBody;
      final locationSuffix = location.isNotEmpty ? ' Location: $location' : '';
      throw FetchDataException(
        'Unexpected HTML response (${response.statusCode}) from ${response.request?.url}.$locationSuffix Body preview: $preview',
      );
    }
    switch (response.statusCode) {
      case 200:
        var responseJson = json.decode(response.body);
        log("Response Json ${response.statusCode} -> ${responseJson.toString()}");

        // Check for explicit success indicators
        // Handle responses with 'success' boolean (e.g., room creation)
        if (responseJson['success'] == true) {
          return responseJson;
        }
        // Handle responses with 'status' string
        if (responseJson['status'] == "Success") {
          return responseJson;
        }
        // Handle responses with 'url' (e.g., file uploads)
        if (responseJson['url'] != null && responseJson['url'] != '') {
          return responseJson;
        }
        // If no explicit success indicator, check for error indicators
        if (responseJson['success'] == false || responseJson['status'] == "Error") {
          throw BadRequestException(
            '${responseJson['message'] ?? 'Request failed'}',
            responseJson,
          );
        }
        // Default: return the response if no error indicators found
        return responseJson;
      case 201:
        var responseJson = json.decode(response.body);
        log("Response Json ${response.statusCode} -> ${responseJson.toString()}");

        // Check for explicit failure indicators
        if (responseJson['success'] == false || responseJson['status'] == false) {
          throw BadRequestException(
            '${responseJson['message'] ?? 'Request failed'}',
            responseJson,
          );
        }
        return responseJson;
      case 400:
        ErrorModel errorModel = ErrorModel.fromJson(json.decode(response.body));
        log("\x1B[31m${"ErrorModel ${response.statusCode} -> ${errorModel.message}"}\x1B[0m");
        throw BadRequestException(
          '${errorModel.message}',
          errorModel.toJson(),
        );
      case 401:
        ErrorModel errorModel = ErrorModel.fromJson(json.decode(response.body));
        log("\x1B[31m${"ErrorModel ${response.statusCode} -> ${errorModel.message}"}\x1B[0m");

        throw UnauthorisedException(
          'Err:${response.statusCode} ${errorModel.message}',
          errorModel.toJson(),
        );

      case 403:
      case 404:
        ErrorModel errorModel = ErrorModel.fromJson(json.decode(response.body));
        log("\x1B[31m${"ErrorModel ${response.statusCode} -> ${errorModel.message}"}\x1B[0m");
        throw UnauthorisedException(
          '${errorModel.message}',
          errorModel.toJson(),
        );
      case 500:
        ErrorModel errorModel = ErrorModel.fromJson(json.decode(response.body));
        log("\x1B[31m${"ErrorModel ${response.statusCode} -> ${errorModel.message}"}\x1B[0m");
        var decodedJson = json.decode(response.body);
        String error = decodedJson["message"];
        throw FetchDataException(
          ' $error',
          errorModel.toJson(),
        );
      default:
        ErrorModel errorModel = ErrorModel.fromJson(json.decode(response.body));
        log("\x1B[31m${"ErrorModel ${response.statusCode} -> ${errorModel.message}"}\x1B[0m");
        throw FetchDataException(
          '${errorModel.message}',
          errorModel.toJson(),
        );
    }
  }
}
