import 'dart:math';

// Predictive Analytics using Linear Regression
class FermentationPredictor {
  static Map<String, dynamic> predictCompletion(List<Map<String, dynamic>> readings) {
    if (readings.length < 10) {
      return {
        'message': 'Collecting data for prediction...',
        'confidence': 'low',
        'daysRemaining': null,
      };
    }

    // Use last 20 readings for trend analysis
    final recentReadings = readings.length > 20 ? readings.sublist(0, 20) : readings;
    
    // Calculate average rate of change for dissolved oxygen (key fermentation indicator)
    final doValues = recentReadings.map((r) => (r['dissolved_oxygen'] ?? 0).toDouble()).toList().cast<double>();
    final avgDO = doValues.reduce((a, b) => a + b) / doValues.length;
    
    // Linear regression to predict when DO will reach ideal level (< 2.0 mg/L for completion)
    double slope = _calculateSlope(doValues);
    
    // Predict days remaining
    int? daysRemaining;
    String confidence = 'low';
    
    if (slope.abs() > 0.1) {
      // Active fermentation
      double daysToCompletion = (avgDO - 2.0) / slope.abs();
      daysRemaining = daysToCompletion.clamp(1, 30).round();
      
      if (slope.abs() > 0.3) {
        confidence = 'high';
      } else if (slope.abs() > 0.15) {
        confidence = 'medium';
      }
    } else {
      // Slow fermentation
      daysRemaining = 7;
      confidence = 'low';
    }
    
    return {
      'daysRemaining': daysRemaining,
      'confidence': confidence,
      'message': slope.abs() < 0.05 ? 'Fermentation appears stalled' : null,
      'accuracy': _calculateR2(doValues),
    };
  }
  
  // Predict potential issues using linear regression
  static Map<String, dynamic> predictIssues(List<Map<String, dynamic>> readings) {
    if (readings.length < 15) {
      return {
        'hasIssues': false,
        'predictions': [],
      };
    }
    
    final recentReadings = readings.length > 20 ? readings.sublist(0, 20) : readings;
    List<Map<String, dynamic>> predictions = [];
    
    // Temperature trend analysis
    final tempValues = recentReadings.map((r) => (r['temperature'] ?? 0).toDouble()).toList().cast<double>();
    double tempSlope = _calculateSlope(tempValues);
    final avgTemp = tempValues.reduce((a, b) => a + b) / tempValues.length;
    
    if (tempSlope > 0.5) {
      predictions.add({
        'type': 'warning',
        'metric': 'Temperature',
        'message': 'Temperature rising rapidly. May exceed safe limits in ${(28 - avgTemp) ~/ tempSlope} readings',
        'severity': 'high',
        'recommendation': 'Cool fermentation vessel immediately',
      });
    }
    
    // pH trend analysis
    final phValues = recentReadings.map((r) => (r['ph'] ?? 0).toDouble()).toList().cast<double>();
    double phSlope = _calculateSlope(phValues);
    final avgPH = phValues.reduce((a, b) => a + b) / phValues.length;
    
    if (phSlope > 0.05) {
      predictions.add({
        'type': 'warning',
        'metric': 'pH',
        'message': 'pH increasing. Risk of bacterial contamination in ${((4.5 - avgPH) / phSlope).round()} readings',
        'severity': 'medium',
        'recommendation': 'Monitor for off-flavors and consider sulfite addition',
      });
    } else if (phSlope < -0.05) {
      predictions.add({
        'type': 'info',
        'metric': 'pH',
        'message': 'pH decreasing normally. Fermentation progressing well',
        'severity': 'low',
        'recommendation': 'Continue current process',
      });
    }
    
    // Dissolved Oxygen trend analysis
    final doValues = recentReadings.map((r) => (r['dissolved_oxygen'] ?? 0).toDouble()).toList().cast<double>();
    double doSlope = _calculateSlope(doValues);
    final avgDO = doValues.reduce((a, b) => a + b) / doValues.length;
    
    if (doSlope > 0.2) {
      predictions.add({
        'type': 'warning',
        'metric': 'Dissolved Oxygen',
        'message': 'Oxygen levels rising. Risk of oxidation',
        'severity': 'high',
        'recommendation': 'Check for leaks in fermentation vessel',
      });
    } else if (avgDO < 2.0 && doSlope.abs() < 0.05) {
      predictions.add({
        'type': 'success',
        'metric': 'Dissolved Oxygen',
        'message': 'Fermentation nearing completion',
        'severity': 'low',
        'recommendation': 'Prepare for racking',
      });
    }
    
    return {
      'hasIssues': predictions.isNotEmpty,
      'predictions': predictions,
      'confidence': predictions.length > 2 ? 'high' : 'medium',
    };
  }
  
  static double _calculateSlope(List<double> values) {
    if (values.length < 2) return 0.0;
    
    int n = values.length;
    List<double> x = List.generate(n, (i) => i.toDouble());
    
    double sumX = x.reduce((a, b) => a + b);
    double sumY = values.reduce((a, b) => a + b);
    double sumXY = 0.0;
    double sumX2 = 0.0;
    
    for (int i = 0; i < n; i++) {
      sumXY += x[i] * values[i];
      sumX2 += x[i] * x[i];
    }
    
    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }
  
  static double _calculateR2(List<double> values) {
    if (values.length < 2) return 0.0;
    
    double mean = values.reduce((a, b) => a + b) / values.length;
    double totalSS = 0.0;
    double residualSS = 0.0;
    
    List<double> predicted = [];
    double slope = _calculateSlope(values);
    double intercept = mean - slope * (values.length - 1) / 2;
    
    for (int i = 0; i < values.length; i++) {
      predicted.add(slope * i + intercept);
      totalSS += pow(values[i] - mean, 2);
      residualSS += pow(values[i] - predicted[i], 2);
    }
    
    if (totalSS == 0) return 0.0;
    return (1 - (residualSS / totalSS)).clamp(0.0, 1.0);
  }
}

// Anomaly Detection
class AnomalyDetector {
  static List<Map<String, dynamic>> detectAnomalies(List<Map<String, dynamic>> readings) {
    if (readings.length < 10) return [];
    
    List<Map<String, dynamic>> anomalies = [];
    
    // Calculate statistics for each metric
    final tempStats = _calculateStats(readings, 'temperature');
    final doStats = _calculateStats(readings, 'dissolved_oxygen');
    final phStats = _calculateStats(readings, 'ph');
    
    // Check recent readings for anomalies (Z-score > 2)
    for (int i = 0; i < min(5, readings.length); i++) {
      final reading = readings[i];
      
      if (tempStats['stdDev']! > 0) {
        double tempZ = ((reading['temperature'] ?? 0) - tempStats['mean']!) / tempStats['stdDev']!;
        
        if (tempZ.abs() > 2) {
          anomalies.add({
            'metric': 'Temperature',
            'value': reading['temperature'],
            'zscore': tempZ.toStringAsFixed(2),
            'timestamp': reading['timestamp'],
            'severity': tempZ.abs() > 3 ? 'critical' : 'warning',
          });
        }
      }
      
      if (doStats['stdDev']! > 0) {
        double doZ = ((reading['dissolved_oxygen'] ?? 0) - doStats['mean']!) / doStats['stdDev']!;
        
        if (doZ.abs() > 2) {
          anomalies.add({
            'metric': 'Dissolved Oxygen',
            'value': reading['dissolved_oxygen'],
            'zscore': doZ.toStringAsFixed(2),
            'timestamp': reading['timestamp'],
            'severity': doZ.abs() > 3 ? 'critical' : 'warning',
          });
        }
      }
      
      if (phStats['stdDev']! > 0) {
        double phZ = ((reading['ph'] ?? 0) - phStats['mean']!) / phStats['stdDev']!;
        
        if (phZ.abs() > 2) {
          anomalies.add({
            'metric': 'pH',
            'value': reading['ph'],
            'zscore': phZ.toStringAsFixed(2),
            'timestamp': reading['timestamp'],
            'severity': phZ.abs() > 3 ? 'critical' : 'warning',
          });
        }
      }
    }
    
    return anomalies;
  }
  
  static Map<String, double> _calculateStats(List<Map<String, dynamic>> readings, String key) {
    final values = readings.map((r) => (r[key] ?? 0).toDouble()).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    double variance = 0;
    for (var value in values) {
      variance += pow(value - mean, 2);
    }
    variance /= values.length;
    
    return {
      'mean': mean,
      'stdDev': sqrt(variance),
    };
  }
}

// Wine-Specific Recommendations
class SmartRecommendations {
  static List<Map<String, dynamic>> getRecommendations(
    Map<String, dynamic>? latest,
    List<Map<String, dynamic>> readings,
    Map<String, dynamic> prediction,
  ) {
    if (latest == null || readings.isEmpty) return [];
    
    List<Map<String, dynamic>> recommendations = [];
    final temp = (latest['temperature'] ?? 0).toDouble();
    final ph = (latest['ph'] ?? 0).toDouble();
    final dissolvedOxygen = (latest['dissolved_oxygen'] ?? 0).toDouble();
    
    // Determine fermentation type based on data patterns
    String fermentationType = _detectFermentationType(readings);
    
    // Get wine-specific specs
    Map<String, dynamic> specs = _getWineSpecs(fermentationType);
    
    // Temperature recommendations
    if (temp < specs['temp_min']) {
      recommendations.add({
        'title': 'Temperature Too Low',
        'message': 'Current: ${temp.toStringAsFixed(1)}°C. ${specs['name']} requires ${specs['temp_min']}-${specs['temp_max']}°C',
        'type': 'warning',
        'icon': 'thermostat',
        'action': 'Increase ambient temperature or use heating wrap',
        'priority': 2,
      });
    } else if (temp > specs['temp_max']) {
      recommendations.add({
        'title': 'Temperature Too High',
        'message': 'Current: ${temp.toStringAsFixed(1)}°C. Risk of off-flavors and stuck fermentation',
        'type': 'warning',
        'icon': 'ac_unit',
        'action': 'Cool vessel immediately to avoid yeast stress',
        'priority': 1,
      });
    } else {
      recommendations.add({
        'title': 'Temperature Optimal',
        'message': 'Perfect range for ${specs['name']} (${specs['temp_min']}-${specs['temp_max']}°C)',
        'type': 'success',
        'icon': 'check_circle',
        'action': 'Maintain current temperature',
        'priority': 3,
      });
    }
    
    // pH recommendations
    if (ph < specs['ph_min']) {
      recommendations.add({
        'title': 'pH Too Low - Microbial Risk',
        'message': 'Current pH: ${ph.toStringAsFixed(2)}. ${specs['name']} target: ${specs['ph_min']}-${specs['ph_max']}',
        'type': 'warning',
        'icon': 'science',
        'action': 'Consider calcium carbonate addition to raise pH',
        'priority': 1,
      });
    } else if (ph > specs['ph_max']) {
      recommendations.add({
        'title': 'pH Too High',
        'message': 'Current pH: ${ph.toStringAsFixed(2)}. Risk of bacterial growth',
        'type': 'warning',
        'icon': 'science',
        'action': 'Add tartaric acid or conduct malolactic fermentation',
        'priority': 2,
      });
    } else {
      recommendations.add({
        'title': 'pH Perfect for ${specs['name']}',
        'message': 'pH ${ph.toStringAsFixed(2)} is ideal for flavor development',
        'type': 'success',
        'icon': 'verified',
        'action': 'Continue monitoring',
        'priority': 3,
      });
    }
    
    // Dissolved Oxygen recommendations
    if (dissolvedOxygen > specs['do_max']) {
      recommendations.add({
        'title': 'High Oxygen - Oxidation Risk',
        'message': 'Current: ${dissolvedOxygen.toStringAsFixed(1)} mg/L. ${specs['name']} max: ${specs['do_max']} mg/L',
        'type': 'warning',
        'icon': 'opacity',
        'action': 'Check airlock seal and minimize headspace',
        'priority': 1,
      });
    } else if (dissolvedOxygen < 2.0) {
      recommendations.add({
        'title': 'Low Oxygen - Good Progress',
        'message': 'Fermentation active. Approaching completion phase',
        'type': 'success',
        'icon': 'trending_up',
        'action': 'Prepare for racking in ${prediction['daysRemaining'] ?? '5-7'} days',
        'priority': 3,
      });
    } else {
      recommendations.add({
        'title': 'Oxygen Level Normal',
        'message': 'Active fermentation with healthy yeast activity',
        'type': 'info',
        'icon': 'check_circle',
        'action': 'Monitor daily',
        'priority': 3,
      });
    }
    
    // Add predictive recommendations
    final issues = FermentationPredictor.predictIssues(readings);
    if (issues['hasIssues']) {
      for (var prediction in issues['predictions']) {
        recommendations.add({
          'title': '⚠️ Predicted: ${prediction['metric']} Issue',
          'message': prediction['message'],
          'type': prediction['type'],
          'icon': 'warning',
          'action': prediction['recommendation'],
          'priority': prediction['severity'] == 'high' ? 1 : 2,
        });
      }
    }
    
    // Sort by priority
    recommendations.sort((a, b) => a['priority'].compareTo(b['priority']));
    
    return recommendations;
  }
  
  static String _detectFermentationType(List<Map<String, dynamic>> readings) {
    // Analyze temperature and pH patterns to determine wine type
    final tempValues = readings.map((r) => (r['temperature'] ?? 0).toDouble()).toList();
    final phValues = readings.map((r) => (r['ph'] ?? 0).toDouble()).toList();
    final avgTemp = tempValues.reduce((a, b) => a + b) / tempValues.length;
    final avgPH = phValues.reduce((a, b) => a + b) / phValues.length;
    
    if (avgTemp >= 15 && avgTemp <= 20 && avgPH >= 3.0 && avgPH < 3.5) {
      return 'white_wine';
    } else if (avgTemp >= 20 && avgTemp <= 28 && avgPH >= 3.3 && avgPH <= 4.0) {
      return 'red_wine';
    } else if (avgTemp >= 25 && avgPH >= 4.5) {
      return 'spirits';
    } else {
      // Default to red wine specs
      return 'red_wine';
    }
  }
  
  static Map<String, dynamic> _getWineSpecs(String type) {
    switch (type) {
      case 'white_wine':
        return {
          'name': 'White Wine',
          'temp_min': 15.0,
          'temp_max': 20.0,
          'ph_min': 3.0,
          'ph_max': 3.4,
          'do_max': 4.0,
          'description': 'Cool fermentation preserves delicate aromatics',
        };
      
      case 'red_wine':
        return {
          'name': 'Red Wine',
          'temp_min': 20.0,
          'temp_max': 28.0,
          'ph_min': 3.3,
          'ph_max': 4.0,
          'do_max': 6.0,
          'description': 'Warmer temps extract color and tannins',
        };
      
      case 'spirits':
        return {
          'name': 'Spirits',
          'temp_min': 25.0,
          'temp_max': 35.0,
          'ph_min': 4.0,
          'ph_max': 5.5,
          'do_max': 8.0,
          'description': 'High-temperature fermentation for alcohol production',
        };
      
      default:
        return {
          'name': 'Red Wine',
          'temp_min': 20.0,
          'temp_max': 28.0,
          'ph_min': 3.3,
          'ph_max': 4.0,
          'do_max': 6.0,
          'description': 'Standard fermentation parameters',
        };
    }
  }
}
