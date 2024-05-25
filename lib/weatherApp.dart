import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weatherapp/additional_info_item.dart';
import 'package:weatherapp/hourly_forcast_item.dart';

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  TextEditingController searchController = TextEditingController();
  String? currentCity;
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String errorMessage = '';

  Future<Map<String, dynamic>> getWeatherForecast(String city) async {
    try {
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&APPID=b399c845c71639064e56ec7c57979786'));
      final data = jsonDecode(res.body);
      if (data['cod'] != '200') {
        throw data['message'];
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permissions are denied';
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      return placemarks.first.locality;
    } catch (e) {
      throw 'Error getting location: $e';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchInitialWeatherData();
  }

  void fetchInitialWeatherData() async {
    try {
      final city = await getCurrentLocation();
      if (city != null) {
        final data = await getWeatherForecast(city);
        setState(() {
          currentCity = city;
          weatherData = data;
          isLoading = false;
        });
      } else {
        throw 'Could not determine city from location';
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Weather App',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: fetchInitialWeatherData,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              : weatherData != null
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: TextField(
                            controller: searchController,
                            onSubmitted: (value) {
                              setState(() {
                                isLoading = true;
                                errorMessage = '';
                                getWeatherForecast(value).then((data) {
                                  setState(() {
                                    weatherData = data;
                                    isLoading = false;
                                  });
                                }).catchError((e) {
                                  setState(() {
                                    errorMessage = e.toString();
                                    isLoading = false;
                                  });
                                });
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                              labelStyle: TextStyle(color: Colors.white),
                              labelText: 'Enter Location',
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                            ),
                          ),
                        ),
                        if (weatherData != null) ...[
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: Card(
                                    elevation: 10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    color:
                                        const Color.fromARGB(31, 161, 131, 131),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 4, sigmaY: 4),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Text(
                                                '${(weatherData!['list'][0]['main']['temp'] - 273.15).toStringAsFixed(0)} °C',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 40),
                                              ),
                                              const SizedBox(
                                                height: 0,
                                              ),
                                              Icon(
                                                weatherData!['list'][0]['weather'][0]['main'] ==
                                                            'Clouds' ||
                                                        weatherData!['list'][0]['weather'][0]['main'] ==
                                                            'Rain'
                                                    ? Icons.cloud
                                                    : Icons.sunny,
                                                color: Colors.white,
                                                size: 70,
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                weatherData!['list'][0]['weather'][0]['main'],
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 24),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Hourly forecast
                                const Text(
                                  'Hourly Forecast',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 130,
                                  child: ListView.builder(
                                    itemCount: 5,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      final hour = DateFormat.j().format(
                                          DateTime.parse(weatherData!['list']
                                              [index + 1]['dt_txt']));
                                      final hourlyAtmos =
                                          weatherData!['list'][index + 1]['weather'][0]['main'];
                                      final hourlyTemp =
                                          (weatherData!['list'][index + 1]['main']['temp'] - 273.15)
                                              .toStringAsFixed(0);
                                      return HourlyForcastItem(
                                        hour: hour.toString(),
                                        icon: hourlyAtmos == 'Clouds' || hourlyAtmos == 'Rain'
                                            ? Icons.cloud
                                            : Icons.sunny,
                                        value: '$hourlyTemp °C',
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Additional info
                                const Text(
                                  'Additional Information',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    AdditionalInfoItem(
                                      icon: Icons.water_drop,
                                      label: 'Humidity',
                                      value: weatherData!['list'][0]['main']
                                              ['humidity']
                                          .toString(),
                                    ),
                                    AdditionalInfoItem(
                                      icon: Icons.air,
                                      label: 'Wind Speed',
                                      value: weatherData!['list'][0]['wind']
                                              ['speed']
                                          .toString(),
                                    ),
                                    AdditionalInfoItem(
                                      icon: Icons.beach_access,
                                      label: 'Pressure',
                                      value: weatherData!['list'][0]['main']
                                              ['pressure']
                                          .toString(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    )
                  : Container(),
    );
  }
}
