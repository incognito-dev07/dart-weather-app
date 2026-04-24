import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = Platform.environment['OPENWEATHER_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    print('ERROR: OPENWEATHER_API_KEY not set');
    return;
  }

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Weather server running on port $port');

  await for (HttpRequest request in server) {
    if (request.method == 'GET' && request.uri.path == '/weather') {
      final city = request.uri.queryParameters['city'] ?? '';
      await handleWeatherRequest(request, city, apiKey);
    } else {
      await serveStaticFile(request);
    }
  }
}

Future<void> serveStaticFile(HttpRequest request) async {
  final path = request.uri.path;
  final fileMap = {
    '/': 'index.html',
    '/index.html': 'index.html',
    '/style.css': 'style.css',
    '/script.js': 'script.js',
    '/manifest.json': 'manifest.json',
  };

  final fileName = fileMap[path];
  if (fileName == null) {
    request.response
      ..statusCode = 404
      ..headers.contentType = ContentType.html
      ..write('Not found');
    request.response.close();
    return;
  }

  final file = File(fileName);
  if (await file.exists()) {
    final bytes = await file.readAsBytes();
    final decoded = utf8.decode(bytes);
    final contentType = fileName.endsWith('.html')
        ? ContentType.html
        : fileName.endsWith('.css')
            ? ContentType('text', 'css')
            : fileName.endsWith('.js')
                ? ContentType('application', 'javascript')
                : ContentType('application', 'json');
    request.response
      ..headers.contentType = contentType
      ..headers.set('Content-Type', '${contentType.mimeType}; charset=utf-8')
      ..write(decoded);
  } else {
    request.response.statusCode = 404;
  }
  request.response.close();
}

Future<void> handleWeatherRequest(
    HttpRequest request, String city, String apiKey) async {
  if (city.isEmpty) {
    sendJson(request.response, 400, {'error': 'City name is required'});
    return;
  }

  try {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');
    final response = await http.get(url);

    if (response.statusCode == 404) {
      sendJson(request.response, 404, {'error': 'City not found'});
      return;
    }

    if (response.statusCode != 200) {
      sendJson(request.response, 500,
          {'error': 'Weather service unavailable'});
      return;
    }

    final data = jsonDecode(response.body);
    final weatherData = {
      'city': data['name'],
      'country': data['sys']['country'],
      'temperature': data['main']['temp'].toDouble(),
      'feelsLike': data['main']['feels_like'].toDouble(),
      'description': data['weather'][0]['description'],
      'weatherCode': data['weather'][0]['id'],
      'humidity': data['main']['humidity'],
      'windSpeed': data['wind']['speed'].toDouble(),
      'pressure': data['main']['pressure'],
      'visibility': (data['visibility'] / 1000).toStringAsFixed(1),
      'cloudiness': data['clouds']['all'],
      'sunrise': formatTime(data['sys']['sunrise']),
      'sunset': formatTime(data['sys']['sunset']),
    };

    sendJson(request.response, 200, weatherData);
  } catch (e) {
    sendJson(
        request.response, 500, {'error': 'Failed to fetch weather data'});
  }
}

String formatTime(int timestamp) {
  final date =
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

void sendJson(
    HttpResponse response, int statusCode, Map<String, dynamic> data) {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..headers.set('Content-Type', 'application/json; charset=utf-8')
    ..headers.set('Access-Control-Allow-Origin', '*')
    ..write(jsonEncode(data));
  response.close();
}