import 'package:flutter/material.dart';
import 'ml_insights.dart';

class AIInsightsPage extends StatelessWidget {
  final List<Map<String, dynamic>> readings;
  final Map<String, dynamic> prediction;
  final List<Map<String, dynamic>> anomalies;
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
    // Get predictive issues
    final predictiveIssues = FermentationPredictor.predictIssues(readings);
    
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
            letterSpacing: 0.3,
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
            // Fermentation Type Detection
            _buildFermentationTypeCard(),
            
            const SizedBox(height: 20),
            
            // Prediction Card
            _buildPredictionCard(),
            
            const SizedBox(height: 20),
            
            // Predictive Issues
            if (predictiveIssues['hasIssues']) ...[
              _buildPredictiveIssuesCard(predictiveIssues),
              const SizedBox(height: 20),
            ],
            
            // Anomalies
            if (anomalies.isNotEmpty) ...[
              _buildAnomaliesCard(),
              const SizedBox(height: 20),
            ],
            
            // Recommendations
            _buildRecommendationsCard(),
            
            const SizedBox(height: 20),
            
            // Model Info
            _buildModelInfoCard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFermentationTypeCard() {
    // Detect fermentation type
    final avgTemp = readings.map((r) => (r['temperature'] ?? 0).toDouble()).reduce((a, b) => a + b) / readings.length;
    final avgPH = readings.map((r) => (r['ph'] ?? 0).toDouble()).reduce((a, b) => a + b) / readings.length;
    
    String type = 'Red Wine';
    Color typeColor = const Color(0xFF722F37);
    IconData typeIcon = Icons.wine_bar;
    
    if (avgTemp >= 15 && avgTemp <= 20 && avgPH >= 3.0 && avgPH < 3.5) {
      type = 'White Wine';
      typeColor = const Color(0xFFF4E4C1);
      typeIcon = Icons.wine_bar_outlined;
    } else if (avgTemp >= 25 && avgPH >= 4.5) {
      type = 'Spirits';
      typeColor = const Color(0xFFD4A574);
      typeIcon = Icons.local_bar;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor.withOpacity(0.7), typeColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: typeColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detected Fermentation Type',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Avg Temp: ${avgTemp.toStringAsFixed(1)}°C • pH: ${avgPH.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
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
  
  Widget _buildPredictionCard() {
    final daysRemaining = prediction['daysRemaining'];
    final confidence = prediction['confidence'];
    final accuracy = prediction['accuracy'] != null ? (prediction['accuracy'] * 100).toStringAsFixed(0) : '0';
    
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
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Predictive Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3561),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(confidence),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (confidence ?? 'low').toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Completion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysRemaining != null ? '$daysRemaining days' : 'Calculating...',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF667EEA),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.model_training,
                      color: Color(0xFF667EEA),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$accuracy% R²',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667EEA),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPredictiveIssuesCard(Map<String, dynamic> issues) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Predicted Issues',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3561),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            (issues['predictions'] as List).length,
            (index) {
              final issue = issues['predictions'][index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getIssueColor(issue['severity']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getIssueColor(issue['severity']).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getIssueIcon(issue['severity']),
                          color: _getIssueColor(issue['severity']),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issue['metric'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getIssueColor(issue['severity']),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getIssueColor(issue['severity']),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            issue['severity'].toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issue['message'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2D3561),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Color(0xFF667EEA),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              issue['recommendation'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF667EEA),
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnomaliesCard() {
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Statistical Anomalies (${anomalies.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3561),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...anomalies.map((anomaly) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: anomaly['severity'] == 'critical'
                    ? Colors.red.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  anomaly['severity'] == 'critical'
                      ? Icons.error
                      : Icons.warning,
                  color: anomaly['severity'] == 'critical'
                      ? Colors.red
                      : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anomaly['metric'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3561),
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Value: ${anomaly['value']} (Z-score: ${anomaly['zscore']})',
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
          )).toList(),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationsCard() {
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
                  color: const Color(0xFF66BB6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.recommend,
                  color: Color(0xFF66BB6A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Wine-Specific Recommendations (${recommendations.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3561),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _getRecommendationColor(rec['type']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getRecommendationColor(rec['type']).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconData(rec['icon']),
                      color: _getRecommendationColor(rec['type']),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getRecommendationColor(rec['type']),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rec['message'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2D3561),
                    fontFamily: 'Inter',
                  ),
                ),
                if (rec['action'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          size: 16,
                          color: Color(0xFF667EEA),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rec['action'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF667EEA),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  Widget _buildModelInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'AI Model Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Algorithm', 'Linear Regression'),
          _buildInfoRow('Data Points', '${readings.length} readings'),
          _buildInfoRow('Metrics', 'Temperature, pH, Dissolved O₂'),
          _buildInfoRow('Update Frequency', 'Real-time (10s intervals)'),
          _buildInfoRow('Confidence Method', 'R² Score + Trend Analysis'),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getConfidenceColor(String? confidence) {
    switch (confidence) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
  
  Color _getIssueColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
  
  IconData _getIssueIcon(String severity) {
    switch (severity) {
      case 'high':
        return Icons.error;
      case 'medium':
        return Icons.warning;
      default:
        return Icons.info;
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
  
  IconData _getIconData(String? icon) {
    switch (icon) {
      case 'thermostat':
        return Icons.thermostat_outlined;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'science':
        return Icons.science_outlined;
      case 'opacity':
        return Icons.opacity_outlined;
      case 'check_circle':
        return Icons.check_circle_outlined;
      case 'verified':
        return Icons.verified_outlined;
      case 'trending_up':
        return Icons.trending_up;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }
}
