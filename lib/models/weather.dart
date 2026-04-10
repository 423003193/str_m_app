class Weather {
  final double temperature;
  final String condition;
  final double windSpeed;
  final String location;

  Weather({
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.location,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    return Weather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      condition: _getWeatherCondition(current['weather_code'] as int),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      location: 'New York, USA',
    );
  }

  static String _getWeatherCondition(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 59) return 'Drizzle';
    if (code <= 69) return 'Rainy';
    if (code <= 79) return 'Snowy';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}

class ExchangeRate {
  final String currency;
  final double rate;

  ExchangeRate({required this.currency, required this.rate});
}
