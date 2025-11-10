import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Main Dashboard Page
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

  // Thresholds
  double tempThreshold = 28.0;
  double humidityThreshold = 70.0;
  double co2Threshold = 2000.0;
  double dissolvedOxygenThreshold = 8.0;

  final String dataUrl = 'https://fizzbuzz-fermentation-data.s3.us-east-2.amazonaws.com/data/latest.json';

  @override
  void initState() {
    super.initState();
    _loadThresholds();
    fetchData();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tempThreshold = prefs.getDouble('tempThreshold') ?? 28.0;
      humidityThreshold = prefs.getDouble('humidityThreshold') ?? 70.0;
      co2Threshold = prefs.getDouble('co2Threshold') ?? 2000.0;
      dissolvedOxygenThreshold = prefs.getDouble('dissolvedOxygenThreshold') ?? 8.0;
    });
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

  bool _hasWarnings() {
    if (readings.isEmpty) return false;
    final latest = readings.first;
    return (latest['temperature'] ?? 0) > tempThreshold ||
        (latest['humidity'] ?? 0) > humidityThreshold ||
        (latest['co2'] ?? 0) > co2Threshold;
  }

  List<String> _getWarnings() {
    if (readings.isEmpty) return [];
    final latest = readings.first;
    List<String> warnings = [];
    if ((latest['temperature'] ?? 0) > tempThreshold) {
      warnings.add('⚠️ Temperature exceeds ${tempThreshold}°C');
    }
    if ((latest['humidity'] ?? 0) > humidityThreshold) {
      warnings.add('⚠️ Humidity exceeds ${humidityThreshold}%');
    }
    if ((latest['co2'] ?? 0) > co2Threshold) {
      warnings.add('⚠️ CO₂ exceeds ${co2Threshold} ppm');
    }
    return warnings;
  }

  Color getStatusColor() {
    return _hasWarnings() ? const Color(0xFFE63946) : const Color(0xFF66BB6A);
  }

  String getStatusText() {
    return _hasWarnings() ? 'Warning - Threshold Exceeded' : 'All Systems Optimal';
  }

  List<FlSpot> getChartData(String key) {
    final dataToShow = readings.length > 20 ? readings.sublist(0, 20) : readings;
    final spots = <FlSpot>[];
    
    for (int i = 0; i < dataToShow.length; i++) {
      final value = (dataToShow[i][key] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), value));
    }
    
    return spots.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final latestReading = readings.isNotEmpty ? readings.first : null;
    final temp = latestReading?['temperature'] ?? 0.0;
    final humidity = latestReading?['humidity'] ?? 0.0;
    final co2 = latestReading?['co2'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2D3561),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.science_outlined, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FizzBuzz Fermentation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Real-time Monitoring',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${readings.length} readings',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ThresholdSettingsPage(
                    tempThreshold: tempThreshold,
                    humidityThreshold: humidityThreshold,
                    co2Threshold: co2Threshold,
                    dissolvedOxygenThreshold: dissolvedOxygenThreshold,
                  ),
                ),
              );
              _loadThresholds();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D3561)))
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Color(0xFFE63946)),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3561),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : readings.isEmpty
                  ? const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(fontFamily: 'Inter'),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Banner
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    getStatusColor().withOpacity(0.85),
                                    getStatusColor(),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: getStatusColor().withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _hasWarnings()
                                            ? Icons.warning_rounded
                                            : Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'System Status',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Inter',
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Text(
                                              getStatusText(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Inter',
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_hasWarnings()) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: _getWarnings()
                                            .map((w) => Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                                  child: Text(
                                                    w,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontFamily: 'Inter',
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            
                            // Metrics Grid with Charts
                            const Text(
                              'Live Metrics',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3561),
                                fontFamily: 'Inter',
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                              children: [
                                _buildMetricCardWithChart(
                                  icon: Icons.thermostat_outlined,
                                  label: 'Temperature',
                                  value: '${temp.toStringAsFixed(1)}°C',
                                  color: const Color(0xFFFF6B6B),
                                  threshold: tempThreshold,
                                  currentValue: temp,
                                  chartData: getChartData('temperature'),
                                ),
                                _buildMetricCardWithChart(
                                  icon: Icons.water_drop_outlined,
                                  label: 'Humidity',
                                  value: '${humidity.toStringAsFixed(1)}%',
                                  color: const Color(0xFF4ECDC4),
                                  threshold: humidityThreshold,
                                  currentValue: humidity,
                                  chartData: getChartData('humidity'),
                                ),
                                _buildMetricCardWithChart(
                                  icon: Icons.air_outlined,
                                  label: 'CO₂ Level',
                                  value: '$co2 ppm',
                                  color: const Color(0xFF95E1D3),
                                  threshold: co2Threshold,
                                  currentValue: co2.toDouble(),
                                  chartData: getChartData('co2'),
                                ),
                                _buildMetricCard(
                                  icon: Icons.access_time_outlined,
                                  label: 'Last Update',
                                  value: _formatTime(latestReading?['timestamp'] ?? ''),
                                  color: const Color(0xFFA8DADC),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Recent History
                            const Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3561),
                                fontFamily: 'Inter',
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...readings.take(5).map((reading) => _buildHistoryCard(reading)),
                          ],
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchData,
        backgroundColor: const Color(0xFF2D3561),
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildMetricCardWithChart({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double threshold,
    required double currentValue,
    required List<FlSpot> chartData,
  }) {
    final bool exceeds = currentValue > threshold;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: exceeds ? Border.all(color: const Color(0xFFE63946), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (exceeds)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE63946).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ALERT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE63946),
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: exceeds ? const Color(0xFFE63946) : const Color(0xFF2D3561),
              fontFamily: 'Inter',
              letterSpacing: 0.3,
            ),
          ),
          Text(
            'Max: ${threshold.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: chartData.length > 1
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                          left: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 2,
                                color: color,
                                strokeWidth: 0,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Collecting data...',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3561),
                  fontFamily: 'Inter',
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> reading) {
    final temp = reading['temperature'] ?? 0;
    final hasAlert = temp > tempThreshold ||
        (reading['humidity'] ?? 0) > humidityThreshold ||
        (reading['co2'] ?? 0) > co2Threshold;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: hasAlert ? Border.all(color: const Color(0xFFE63946).withOpacity(0.3), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasAlert 
                  ? const Color(0xFFE63946).withOpacity(0.1)
                  : const Color(0xFF2D3561).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasAlert ? Icons.warning_rounded : Icons.sensors_outlined,
              color: hasAlert ? const Color(0xFFE63946) : const Color(0xFF2D3561),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reading['temperature']}°C  •  ${reading['humidity']}%  •  ${reading['co2']} ppm',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3561),
                    fontFamily: 'Inter',
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reading['sensor_id'] ?? 'esp32-001',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(reading['timestamp'] ?? ''),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Just now';
    }
  }
}

// Threshold Settings Page
class ThresholdSettingsPage extends StatefulWidget {
  final double tempThreshold;
  final double humidityThreshold;
  final double co2Threshold;
  final double dissolvedOxygenThreshold;

  const ThresholdSettingsPage({
    super.key,
    required this.tempThreshold,
    required this.humidityThreshold,
    required this.co2Threshold,
    required this.dissolvedOxygenThreshold,
  });

  @override
  State<ThresholdSettingsPage> createState() => _ThresholdSettingsPageState();
}

class _ThresholdSettingsPageState extends State<ThresholdSettingsPage> {
  late TextEditingController tempController;
  late TextEditingController humidityController;
  late TextEditingController co2Controller;
  late TextEditingController dissolvedOxygenController;

  @override
  void initState() {
    super.initState();
    tempController = TextEditingController(text: widget.tempThreshold.toString());
    humidityController = TextEditingController(text: widget.humidityThreshold.toString());
    co2Controller = TextEditingController(text: widget.co2Threshold.toString());
    dissolvedOxygenController = TextEditingController(text: widget.dissolvedOxygenThreshold.toString());
  }

  @override
  void dispose() {
    tempController.dispose();
    humidityController.dispose();
    co2Controller.dispose();
    dissolvedOxygenController.dispose();
    super.dispose();
  }

  Future<void> _saveThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tempThreshold', double.parse(tempController.text));
    await prefs.setDouble('humidityThreshold', double.parse(humidityController.text));
    await prefs.setDouble('co2Threshold', double.parse(co2Controller.text));
    await prefs.setDouble('dissolvedOxygenThreshold', double.parse(dissolvedOxygenController.text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thresholds saved successfully!', style: TextStyle(fontFamily: 'Inter')),
          backgroundColor: const Color(0xFF66BB6A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2D3561),
        title: const Text(
          'Alert Thresholds',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Maximum Values',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3561),
                fontFamily: 'Inter',
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will receive alerts when readings exceed these thresholds',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            _buildThresholdInput(
              icon: Icons.thermostat_outlined,
              label: 'Temperature',
              unit: '°C',
              controller: tempController,
              color: const Color(0xFFFF6B6B),
            ),
            const SizedBox(height: 20),
            _buildThresholdInput(
              icon: Icons.water_drop_outlined,
              label: 'Humidity',
              unit: '%',
              controller: humidityController,
              color: const Color(0xFF4ECDC4),
            ),
            const SizedBox(height: 20),
            _buildThresholdInput(
              icon: Icons.air_outlined,
              label: 'Carbon Dioxide (CO₂)',
              unit: 'ppm',
              controller: co2Controller,
              color: const Color(0xFF95E1D3),
            ),
            const SizedBox(height: 20),
            _buildThresholdInput(
              icon: Icons.opacity_outlined,
              label: 'Dissolved Oxygen',
              unit: 'mg/L',
              controller: dissolvedOxygenController,
              color: const Color(0xFFA8DADC),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveThresholds,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3561),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Thresholds',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdInput({
    required IconData icon,
    required String label,
    required String unit,
    required TextEditingController controller,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3561),
                  fontFamily: 'Inter',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: Color(0xFF2D3561),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
