import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> readings = [];
  bool isLoading = true;
  String? errorMessage;
  Timer? _timer;

  final String dataUrl = 'https://fizzbuzz-fermentation-data.s3.us-east-2.amazonaws.com/data/latest.json';

  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(dataUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          readings = data.cast<Map<String, dynamic>>();
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load data';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FizzBuzz Monitor'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : readings.isEmpty
                  ? const Center(child: Text('No data'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: readings.length,
                      itemBuilder: (context, index) {
                        final reading = readings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text('Temperature: ${reading['temperature']}°C'),
                            subtitle: Text(
                              'Humidity: ${reading['humidity']}% | Gas: ${reading['gas_level']} ppm',
                            ),
                            trailing: Text(reading['timestamp'] ?? ''),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
