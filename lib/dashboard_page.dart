import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ml_insights.dart';
import 'ai_insights_page.dart';

//lock in twin

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
  double dissolvedOxygenThreshold = 8.0;  // mg/L
  double phThreshold = 4.5;  // pH (upper bound - wine typically 3.0-4.0)
  double phMaxThreshold = 3.8;  // pH (lower bound - minimum acceptable)

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
      dissolvedOxygenThreshold = prefs.getDouble('dissolvedOxygenThreshold') ?? 8.0;
      phThreshold = prefs.getDouble('phThreshold') ?? 4.5;
      phMaxThreshold = prefs.getDouble('phMaxThreshold') ?? 3.8;
    });
  }

  Future<void> fetchData() async {
    try {
      // CACHE-BUSTING: Add timestamp to URL to prevent browser caching
      final url = '$dataUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );
      
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
        (latest['dissolved_oxygen'] ?? 0) > dissolvedOxygenThreshold ||
        (latest['ph'] ?? 0) < phMaxThreshold ||  // pH too low
        (latest['ph'] ?? 0) > phThreshold;  // pH too high
  }

  List<String> _getWarnings() {
    if (readings.isEmpty) return [];
    final latest = readings.first;
    List<String> warnings = [];
    
    if ((latest['temperature'] ?? 0) > tempThreshold) {
      warnings.add('⚠️ Temperature exceeds $tempThreshold°C');
    }
    if ((latest['dissolved_oxygen'] ?? 0) > dissolvedOxygenThreshold) {
      warnings.add('⚠️ Dissolved Oxygen exceeds ${dissolvedOxygenThreshold.toStringAsFixed(1)} mg/L');
    }
    
    final ph = (latest['ph'] ?? 0).toDouble();
    if (ph < phMaxThreshold) {
      warnings.add('⚠️ pH too low (${ph.toStringAsFixed(2)}) - Risk of microbial spoilage');
    } else if (ph > phThreshold) {
      warnings.add('⚠️ pH too high (${ph.toStringAsFixed(2)}) - Target: 3.0-4.0');
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
    final dissolvedOxygen = latestReading?['dissolved_oxygen'] ?? 0.0;
    final ph = latestReading?['ph'] ?? 0.0;

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
                    dissolvedOxygenThreshold: dissolvedOxygenThreshold,
                    phThreshold: phThreshold,
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
                            
                            // AI Insights Card
                            _buildAIInsightsCard(),
                            
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculate how many cards can fit per row based on screen width
                                const double minCardWidth = 160;
                                const double spacing = 10;
                                final int crossAxisCount = ((constraints.maxWidth + spacing) / (minCardWidth + spacing)).floor().clamp(1, 4);
                                final double cardWidth = ((constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount).clamp(minCardWidth, double.infinity);
                                
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildMetricCardWithChart(
                                        icon: Icons.thermostat_outlined,
                                        label: 'Temperature',
                                        value: '${temp.toStringAsFixed(1)}°C',
                                        color: const Color(0xFFFF6B6B),
                                        threshold: tempThreshold,
                                        currentValue: temp,
                                        chartData: getChartData('temperature'),
                                        metricKey: 'temperature',
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildMetricCardWithChart(
                                        icon: Icons.opacity_outlined,
                                        label: 'Dissolved O₂',
                                        value: '${dissolvedOxygen.toStringAsFixed(2)} mg/L',
                                        color: const Color(0xFF4ECDC4),
                                        threshold: dissolvedOxygenThreshold,
                                        currentValue: dissolvedOxygen,
                                        chartData: getChartData('dissolved_oxygen'),
                                        metricKey: 'dissolved_oxygen',
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildMetricCardWithChart(
                                        icon: Icons.science_outlined,
                                        label: 'pH Level',
                                        value: ph.toStringAsFixed(2),
                                        color: const Color(0xFF95E1D3),
                                        threshold: phThreshold,
                                        currentValue: ph,
                                        chartData: getChartData('ph'),
                                        metricKey: 'ph',
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildMetricCard(
                                        icon: Icons.access_time_outlined,
                                        label: 'Last Update',
                                        value: _formatTime(latestReading?['timestamp'] ?? ''),
                                        color: const Color(0xFFA8DADC),
                                      ),
                                    ),
                                  ],
                                );
                              },
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
    required String metricKey,
  }) {
    final bool exceeds = currentValue > threshold;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MetricDetailPage(
              icon: icon,
              label: label,
              value: value,
              color: color,
              threshold: threshold,
              currentValue: currentValue,
              chartData: chartData,
              metricKey: metricKey,
              readings: readings,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: exceeds ? Border.all(color: const Color(0xFFE63946), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                if (exceeds)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ALERT',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE63946),
                        fontFamily: 'Inter',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: exceeds ? const Color(0xFFE63946) : const Color(0xFF2D3561),
                    fontFamily: 'Inter',
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Max: ${threshold.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.grey[500],
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 10,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 3),
                Text(
                  'Tap to view chart',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.grey[400],
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
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
    final ph = (reading['ph'] ?? 0).toDouble();
    final hasAlert = temp > tempThreshold ||
        (reading['dissolved_oxygen'] ?? 0) > dissolvedOxygenThreshold ||
        ph < phMaxThreshold ||
        ph > phThreshold;
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
                  '${reading['temperature']}°C  •  ${(reading['dissolved_oxygen'] ?? 0).toStringAsFixed(1)} mg/L  •  pH ${(reading['ph'] ?? 0).toStringAsFixed(2)}',
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

  Widget _buildAIInsightsCard() {
    final prediction = FermentationPredictor.predictCompletion(readings);
    final anomalies = AnomalyDetector.detectAnomalies(readings);
    final recommendations = SmartRecommendations.getRecommendations(
      readings.isNotEmpty ? readings.first : null,
      readings,
      prediction,
    );
    final hasAnomalies = anomalies.isNotEmpty;
    final daysRemaining = prediction['daysRemaining'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'Machine Learning Insights',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Inter',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Prediction
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Color(0xFF667EEA),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completion Prediction',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        daysRemaining != null 
                          ? 'Estimated: $daysRemaining ${daysRemaining == 1 ? "day" : "days"} remaining'
                          : prediction['message'] ?? 'Analyzing...',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(prediction['confidence']),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (prediction['confidence']?.toString().toUpperCase() ?? 'LOW'),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Top Recommendation
          if (recommendations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRecommendationIcon(recommendations.first['icon']),
                      color: _getRecommendationColor(recommendations.first['type']),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendations.first['title'],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recommendations.first['message'],
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Anomaly Alert
          if (hasAnomalies) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${anomalies.length} anomal${anomalies.length == 1 ? "y" : "ies"} detected',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // View Details Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIInsightsPage(
                      readings: readings,
                      prediction: prediction,
                      anomalies: anomalies,
                      recommendations: recommendations,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Detailed Analysis',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(String? confidence) {
    switch (confidence) {
      case 'high':
        return Colors.green.withOpacity(0.8);
      case 'medium':
        return Colors.orange.withOpacity(0.8);
      default:
        return Colors.red.withOpacity(0.8);
    }
  }

  IconData _getRecommendationIcon(String? icon) {
    switch (icon) {
      case 'thermostat':
        return Icons.thermostat_outlined;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'trending_up':
        return Icons.trending_up;
      case 'check_circle':
        return Icons.check_circle_outlined;
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'verified':
        return Icons.verified_outlined;
      case 'science':
        return Icons.science_outlined;
      case 'opacity':
        return Icons.opacity_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getRecommendationColor(String? type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return const Color(0xFF667EEA);
    }
  }
}

// Threshold Settings Page
class ThresholdSettingsPage extends StatefulWidget {
  final double tempThreshold;
  final double dissolvedOxygenThreshold;
  final double phThreshold;

  const ThresholdSettingsPage({
    super.key,
    required this.tempThreshold,
    required this.dissolvedOxygenThreshold,
    required this.phThreshold,
  });

  @override
  State<ThresholdSettingsPage> createState() => _ThresholdSettingsPageState();
}

class _ThresholdSettingsPageState extends State<ThresholdSettingsPage> {
  late TextEditingController tempController;
  late TextEditingController dissolvedOxygenController;
  late TextEditingController phController;

  @override
  void initState() {
    super.initState();
    tempController = TextEditingController(text: widget.tempThreshold.toString());
    dissolvedOxygenController = TextEditingController(text: widget.dissolvedOxygenThreshold.toString());
    phController = TextEditingController(text: widget.phThreshold.toString());
  }

  @override
  void dispose() {
    tempController.dispose();
    dissolvedOxygenController.dispose();
    phController.dispose();
    super.dispose();
  }

  Future<void> _saveThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tempThreshold', double.parse(tempController.text));
    await prefs.setDouble('dissolvedOxygenThreshold', double.parse(dissolvedOxygenController.text));
    await prefs.setDouble('phThreshold', double.parse(phController.text));
    
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
              icon: Icons.opacity_outlined,
              label: 'Dissolved Oxygen',
              unit: 'mg/L',
              controller: dissolvedOxygenController,
              color: const Color(0xFF4ECDC4),
            ),
            const SizedBox(height: 20),
            _buildThresholdInput(
              icon: Icons.science_outlined,
              label: 'pH Level (Max)',
              unit: 'pH',
              controller: phController,
              color: const Color(0xFF95E1D3),
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

// Metric Detail Page
class MetricDetailPage extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double threshold;
  final double currentValue;
  final List<FlSpot> chartData;
  final String metricKey;
  final List<Map<String, dynamic>> readings;

  const MetricDetailPage({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.threshold,
    required this.currentValue,
    required this.chartData,
    required this.metricKey,
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    final bool exceeds = currentValue > threshold;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: color,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Value Card
            Container(
              padding: const EdgeInsets.all(24),
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
                children: [
                  Text(
                    'Current Value',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: exceeds ? const Color(0xFFE63946) : const Color(0xFF2D3561),
                      fontFamily: 'Inter',
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: exceeds 
                        ? const Color(0xFFE63946).withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      exceeds ? '⚠️ Exceeds Threshold' : '✓ Within Range',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: exceeds ? const Color(0xFFE63946) : Colors.green[700],
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Chart Card
            Container(
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
                  Text(
                    'Trend Over Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D3561),
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
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
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: 5,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${value.toInt()}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: _getInterval(chartData),
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                          fontFamily: 'Inter',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
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
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 3,
                                        color: color,
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: color.withOpacity(0.15),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      return LineTooltipItem(
                                        spot.y.toStringAsFixed(1),
                                        TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          fontFamily: 'Inter',
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              'Collecting data...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Threshold Info
            Container(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Threshold',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${threshold.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3561),
                            fontFamily: 'Inter',
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getInterval(List<FlSpot> data) {
    if (data.isEmpty) return 1;
    final values = data.map((spot) => spot.y).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range < 5) return 1;
    if (range < 10) return 2;
    if (range < 50) return 10;
    if (range < 100) return 20;
    return 50;
  }
}
