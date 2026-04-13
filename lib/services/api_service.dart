import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../utils/constants.dart';

class ApiService {
  static const String weatherUrl =
      'https://api.open-meteo.com/v1/forecast?latitude=40.71&longitude=-74.01&current=temperature_2m,weather_code,wind_speed_10m&temperature_unit=fahrenheit';
  static const int timeoutSeconds = 15;

  Future<Weather> fetchCurrentWeather() async {
    try {
      final response = await http
          .get(Uri.parse(weatherUrl))
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Weather.fromJson(json);
      } else {
        throw Exception('Weather API failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Check your connection.');
      }
      throw Exception('Failed to fetch weather: $e');
    }
  }

  Future<List<ExchangeRate>> fetchExchangeRates() async {
    try {
      // Use the API key and URL from constants.dart
        final response = await http
          .get(Uri.parse(currencyApiUrl))
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map<String, dynamic> && json.containsKey('success') && json['success'] == false) {
          final errorMsg = json['error']?['info'] ?? 'Currency API error.';
          throw Exception(errorMsg);
        }
        final ratesRaw = json['rates'];
        if (ratesRaw == null || ratesRaw is! Map<String, dynamic>) {
          throw Exception('Exchange API response missing or invalid rates data.');
        }
        final rates = ratesRaw;
        return rates.entries
            .map((e) => ExchangeRate(
                  currency: e.key,
                  rate: (e.value as num).toDouble(),
                ))
            .take(10)
            .toList();
      } else {
        throw Exception('Exchange API failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch rates: $e');
    }
  }
}
