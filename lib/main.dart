import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PrevisaoTempoApp());
}

class PrevisaoTempoApp extends StatelessWidget {
  const PrevisaoTempoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Previsão do Tempo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
    );
  }
}

// ==================== MODELOS DE DADOS ====================

class CityLocation {
  final String name;
  final String? admin1;
  final String? country;
  final double latitude;
  final double longitude;

  CityLocation({
    required this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    return CityLocation(
      name: json['name'] ?? '',
      admin1: json['admin1'],
      country: json['country'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  String get subtitle {
    final parts = [
      if (admin1 != null && admin1!.isNotEmpty) admin1!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(' - ');
  }
}

class CurrentWeather {
  final String time;
  final double temperature2m;
  final int relativeHumidity2m;
  final double precipitation;
  final double rain;
  final double windSpeed10m;

  CurrentWeather({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.precipitation,
    required this.rain,
    required this.windSpeed10m,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: json['time'] ?? '',
      temperature2m: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity2m: (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      rain: (json['rain'] as num?)?.toDouble() ?? 0.0,
      windSpeed10m: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HourlyItem {
  final String time;
  final double temperature2m;
  final int precipitationProbability;
  final double precipitation;
  final double rain;

  HourlyItem({
    required this.time,
    required this.temperature2m,
    required this.precipitationProbability,
    required this.precipitation,
    required this.rain,
  });
}

class DailyItem {
  final String date;
  final double temperature2mMax;
  final double temperature2mMin;
  final double precipitationSum;
  final int precipitationProbabilityMax;

  DailyItem({
    required this.date,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationSum,
    required this.precipitationProbabilityMax,
  });
}

class WeatherForecast {
  final CurrentWeather current;
  final List<HourlyItem> hourly;
  final List<DailyItem> daily;

  WeatherForecast({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final current = CurrentWeather.fromJson(json['current']);

    final hourlyMap = json['hourly'] as Map<String, dynamic>;
    final hTimes = List<String>.from(hourlyMap['time'] ?? []);
    final hTemps = List<dynamic>.from(hourlyMap['temperature_2m'] ?? []);
    final hProbs =
        List<dynamic>.from(hourlyMap['precipitation_probability'] ?? []);
    final hPrecips = List<dynamic>.from(hourlyMap['precipitation'] ?? []);
    final hRains = List<dynamic>.from(hourlyMap['rain'] ?? []);

    final allHourly = List.generate(hTimes.length, (i) {
      return HourlyItem(
        time: hTimes[i],
        temperature2m: (hTemps[i] as num?)?.toDouble() ?? 0.0,
        precipitationProbability: (hProbs[i] as num?)?.toInt() ?? 0,
        precipitation: (hPrecips[i] as num?)?.toDouble() ?? 0.0,
        rain: (hRains[i] as num?)?.toDouble() ?? 0.0,
      );
    });

    // Filtra a partir da hora atual para exibir as próximas 24 horas
    int startIndex = 0;
    if (current.time.length >= 13) {
      final currentHourPrefix = current.time.substring(0, 13);
      final foundIndex =
          allHourly.indexWhere((item) => item.time.startsWith(currentHourPrefix));
      if (foundIndex != -1) startIndex = foundIndex;
    }
    final next24Hours = allHourly.skip(startIndex).take(24).toList();

    final dailyMap = json['daily'] as Map<String, dynamic>;
    final dDates = List<String>.from(dailyMap['time'] ?? []);
    final dMax = List<dynamic>.from(dailyMap['temperature_2m_max'] ?? []);
    final dMin = List<dynamic>.from(dailyMap['temperature_2m_min'] ?? []);
    final dPrecipSum =
        List<dynamic>.from(dailyMap['precipitation_sum'] ?? []);
    final dProbMax =
        List<dynamic>.from(dailyMap['precipitation_probability_max'] ?? []);

    final dailyList = List.generate(dDates.length, (i) {
      return DailyItem(
        date: dDates[i],
        temperature2mMax: (dMax[i] as num?)?.toDouble() ?? 0.0,
        temperature2mMin: (dMin[i] as num?)?.toDouble() ?? 0.0,
        precipitationSum: (dPrecipSum[i] as num?)?.toDouble() ?? 0.0,
        precipitationProbabilityMax: (dProbMax[i] as num?)?.toInt() ?? 0,
      );
    });

    return WeatherForecast(
      current: current,
      hourly: next24Hours,
      daily: dailyList,
    );
  }
}

// ==================== SERVIÇO DE API ====================

class OpenMeteoService {
  Future<List<CityLocation>> searchCities(String cityName) async {
    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {
        'name': cityName,
        'count': '10',
        'language': 'pt',
        'format': 'json',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar cidades (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((item) => CityLocation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WeatherForecast> getForecast(double latitude, double longitude) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,precipitation,rain,wind_speed_10m',
        'hourly':
            'temperature_2m,precipitation_probability,precipitation,rain',
        'daily':
            'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
        'timezone': 'America/Sao_Paulo',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar previsão (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherForecast.fromJson(data);
  }
}

// ==================== INTERFACE (UI) ====================

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final OpenMeteoService _service = OpenMeteoService();
  final TextEditingController _searchController = TextEditingController();

  List<CityLocation> _cityResults = [];
  CityLocation? _selectedCity;
  WeatherForecast? _forecast;
  bool _isSearchingCities = false;
  bool _isLoadingWeather = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Carrega São Sebastião do Paraíso como cidade inicial de exemplo
    _selectCity(
      CityLocation(
        name: 'São Sebastião do Paraíso',
        admin1: 'Minas Gerais',
        country: 'Brasil',
        latitude: -20.917101,
        longitude: -46.991779,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearchingCities = true;
      _errorMessage = null;
      _cityResults = [];
    });

    try {
      final cities = await _service.searchCities(query);
      setState(() {
        _cityResults = cities;
        if (cities.isEmpty) {
          _errorMessage = 'Nenhuma cidade encontrada para "$query".';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isSearchingCities = false);
    }
  }

  Future<void> _selectCity(CityLocation city) async {
    setState(() {
      _selectedCity = city;
      _cityResults = [];
      _isLoadingWeather = true;
      _errorMessage = null;
    });

    try {
      final forecast =
          await _service.getForecast(city.latitude, city.longitude);
      setState(() => _forecast = forecast);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoadingWeather = false);
    }
  }

  String _formatHour(String isoDateTime) {
    final parts = isoDateTime.split('T');
    return parts.length == 2 ? parts[1] : isoDateTime;
  }

  String _formatDate(String isoDate) {
    final parts = isoDate.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}' : isoDate;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão do Tempo'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Campo de busca da cidade
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _handleSearch(),
                    decoration: InputDecoration(
                      hintText: 'Digite o nome da cidade...',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSearchingCities ? null : _handleSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isSearchingCities || _isLoadingWeather)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),

            if (_errorMessage != null)
              Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!)),
                    ],
                  ),
                ),
              ),

            // Lista de cidades retornadas pela Geocoding API
            if (_cityResults.isNotEmpty)
              Expanded(
                child: Card(
                  child: ListView.separated(
                    itemCount: _cityResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final city = _cityResults[index];
                      return ListTile(
                        leading: const Icon(Icons.place),
                        title: Text(city.name),
                        subtitle: Text(
                          '${city.subtitle} (${city.latitude.toStringAsFixed(2)}, ${city.longitude.toStringAsFixed(2)})',
                        ),
                        onTap: () => _selectCity(city),
                      );
                    },
                  ),
                ),
              ),

            // Exibição da previsão do tempo
            if (_cityResults.isEmpty &&
                !_isLoadingWeather &&
                _forecast != null &&
                _selectedCity != null)
              Expanded(
                child: ListView(
                  children: [
                    _buildCurrentCard(_selectedCity!, _forecast!.current),
                    const SizedBox(height: 16),
                    Text(
                      'Previsão por Hora (Próximas 24h)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildHourlySection(_forecast!.hourly),
                    const SizedBox(height: 16),
                    Text(
                      'Previsão Diária (7 dias)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ..._forecast!.daily.map(_buildDailyTile),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCard(CityLocation city, CurrentWeather current) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              city.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (city.subtitle.isNotEmpty)
              Text(
                city.subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${current.temperature2m.toStringAsFixed(1)}°C',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
                const Icon(Icons.wb_sunny_outlined, size: 52),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _infoChip(
                  Icons.water_drop,
                  'Umidade: ${current.relativeHumidity2m}%',
                ),
                _infoChip(
                  Icons.air,
                  'Vento: ${current.windSpeed10m.toStringAsFixed(1)} km/h',
                ),
                _infoChip(
                  Icons.umbrella,
                  'Precipitação: ${current.precipitation.toStringAsFixed(1)} mm',
                ),
                _infoChip(
                  Icons.grain,
                  'Chuva: ${current.rain.toStringAsFixed(1)} mm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildHourlySection(List<HourlyItem> hourly) {
    return SizedBox(
      height: 135,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        itemBuilder: (context, index) {
          final item = hourly[index];
          return Card(
            margin: const EdgeInsets.only(right: 8),
            child: Container(
              width: 95,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    _formatHour(item.time),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item.temperature2m.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.water_drop, size: 14, color: Colors.blue),
                      const SizedBox(width: 2),
                      Text('${item.precipitationProbability}%'),
                    ],
                  ),
                  Text(
                    '${item.rain.toStringAsFixed(1)} mm',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyTile(DailyItem day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(
          _formatDate(day.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Chuva: ${day.precipitationSum.toStringAsFixed(1)} mm (${day.precipitationProbabilityMax}%)',
        ),
        trailing: Text(
          '${day.temperature2mMin.toStringAsFixed(0)}° / ${day.temperature2mMax.toStringAsFixed(0)}°C',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}