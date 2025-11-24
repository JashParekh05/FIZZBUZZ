import 'package:flutter/material.dart';
import 'dart:math';

class AIInsightsPage extends StatelessWidget {
  final List<Map<String, dynamic>> readings;
  final Map<String, dynamic> prediction;
  final List<Map<String, String>> anomalies;
  final List<Map<String, dynamic>> recommendations;

  const AIInsightsPage({
    super.key,
    required this.readings,
    required this.prediction,
    required this.anomalies,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF667EEA),
        title: const Text(
          'AI Insights & Predictions',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
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
            // Prediction Card
            _buildPredictionCard(),
            const SizedBox(height: 24),
            
            // Recommendations Section
            const Text(
              'Smart Recommendations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3561),
                fontFamily: 'Inter',
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => _buildRecommendationCard(rec)),
            
            // Anomalies Section
            if (anomalies.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Detected Anomalies',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3561),
                  fontFamily: 'Inter',
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              ...anomalies.map((anomaly) => _buildAnomalyCard(anomaly)),
            ],
            
            const SizedBox(height: 24),
            
            // Model Info
            _buildModelInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    final daysRemaining = prediction['daysRemaining'];
    final confidence = prediction['confidence'] ?? 'low';
    final rSquared = prediction['rSquared'];
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_graph,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Fermentation Completion',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (daysRemaining != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$daysRemaining',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    height: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 8),
                  child: Text(
                    'DAYS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Analyzing...',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getConfidenceColor(confidence),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${confidence.toUpperCase()} CONFIDENCE',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Inter',
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  prediction['message'] ?? 'Collecting data...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (rSquared != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Model Accuracy: ${(rSquared * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    Color cardColor;
    Color iconColor;
    Color borderColor;
    
    switch (rec['type']) {
      case 'warning':
        cardColor = Colors.orange[50]!;
        iconColor = Colors.orange;
        borderColor = Colors.orange.withOpacity(0.3);
        break;
      case 'success':
        cardColor = Colors.green[50]!;
        iconColor = Colors.green;
        borderColor = Colors.green.withOpacity(0.3);
        break;
      default:
        cardColor = Colors.blue[50]!;
        iconColor = Colors.blue;
        borderColor = Colors.blue.withOpacity(0.3);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getIconData(rec['icon']), color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rec['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rec['priority'].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    fontFamily: 'Inter',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rec['message'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontFamily: 'Inter',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rec['action'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(Map<String, String> anomaly) {
    final isCritical = anomaly['severity'] == 'critical';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isCritical ? Colors.red : Colors.orange).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCritical ? Colors.red : Colors.orange).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
              color: isCritical ? Colors.red : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anomaly['metric'] ?? 'Anomaly',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isCritical ? Colors.red[800] : Colors.orange[800],
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  anomaly['message'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About Our AI Models',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3561),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Our machine learning algorithms analyze ${readings.length} data points across multiple parameters including temperature trends, CO₂ production rates, and historical fermentation patterns.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'Inter',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildModelStat('Linear Regression', 'Completion prediction'),
          const SizedBox(height: 8),
          _buildModelStat('Statistical Analysis', 'Anomaly detection'),
          const SizedBox(height: 8),
          _buildModelStat('Rule-Based AI', 'Smart recommendations'),
        ],
      ),
    );
  }

  Widget _buildModelStat(String model, String purpose) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF66BB6A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3561),
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  purpose,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence) {
      case 'high':
        return Colors.green.withOpacity(0.9);
      case 'medium':
        return Colors.orange.withOpacity(0.9);
      default:
        return Colors.red.withOpacity(0.9);
    }
  }

  IconData _getIconData(String? icon) {
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
      default:
        return Icons.info_outline;
    }
  }
}

