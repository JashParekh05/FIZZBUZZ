import 'dart:math';

class FermentationPredictor {
  /// Predicts fermentation completion based on CO₂ trends
  static Map<String, dynamic> predictCompletion(List<Map<String, dynamic>> readings) {
    if (readings.length < 10) {
      return {
        'daysRemaining': null,
        'confidence': 'low',
        'message': 'Collecting data for prediction...',
        'status': 'initializing',
      };
    }

    // Extract CO₂ values (reverse order - oldest to newest for trend analysis)
    List<double> co2Values = [];
    List<double> timeIndices = [];
    
    final dataPoints = min(readings.length, 50);
    for (int i = dataPoints - 1; i >= 0; i--) {
      final reading = readings[i];
      co2Values.add((reading['co2'] ?? 0).toDouble());
      timeIndices.add((dataPoints - 1 - i).toDouble());
    }

    // Linear regression
    final regression = _linearRegression(timeIndices, co2Values);
    final slope = regression['slope'] ?? 0.0;
    final currentCO2 = readings.first['co2']?.toDouble() ?? 0;
    
    // Target CO₂ for completion (wine: ~500 ppm, beer: ~800 ppm)
    const targetCO2 = 600.0;
    
    if (slope >= 0) {
      return {
        'daysRemaining': null,
        'confidence': 'low',
        'message': 'Fermentation not progressing',
        'status': 'stalled',
        'trend': 'stable',
      };
    }

    // Estimate completion (assuming 10-second intervals between readings)
    final readingsToTarget = (currentCO2 - targetCO2) / slope.abs();
    final hoursRemaining = (readingsToTarget * 10 / 3600); // 10 sec per reading
    final daysRemaining = max(1, (hoursRemaining / 24).round());
    final rSquared = regression['rSquared'] ?? 0.0;
    String confidence = rSquared > 0.8 ? 'high' : rSquared > 0.5 ? 'medium' : 'low';

    return {
      'daysRemaining': min(daysRemaining, 30),
      'confidence': confidence,
      'message': 'Predicted completion in $daysRemaining ${daysRemaining == 1 ? "day" : "days"}',
      'status': 'active',
      'trend': 'declining',
      'rSquared': rSquared,
    };
  }

  static Map<String, double> _linearRegression(List<double> x, List<double> y) {
    if (x.isEmpty || y.isEmpty) {
      return {'slope': 0.0, 'intercept': 0.0, 'rSquared': 0.0};
    }

    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((xi) => xi * xi).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Calculate R²
    final yMean = sumY / n;
    final ssTotal = y.map((yi) => (yi - yMean) * (yi - yMean)).reduce((a, b) => a + b);
    final ssResidual = List.generate(n, (i) => y[i] - (slope * x[i] + intercept))
        .map((residual) => residual * residual)
        .reduce((a, b) => a + b);
    
    final rSquared = ssTotal > 0 ? max(0.0, 1 - (ssResidual / ssTotal)) : 0.0;

    return {
      'slope': slope,
      'intercept': intercept,
      'rSquared': rSquared,
    };
  }
}

class AnomalyDetector {
  /// Detects anomalies using statistical analysis
  static List<Map<String, String>> detectAnomalies(List<Map<String, dynamic>> readings) {
    if (readings.length < 20) return [];

    List<Map<String, String>> anomalies = [];

    // Temperature analysis
    final temps = readings.take(50).map((r) => (r['temperature'] ?? 0).toDouble()).toList().cast<double>();
    final tempAnomaly = _detectOutliers(temps, 'Temperature', '°C');
    if (tempAnomaly != null) anomalies.add(tempAnomaly);

    // CO₂ analysis
    final co2s = readings.take(50).map((r) => (r['co2'] ?? 0).toDouble()).toList().cast<double>();
    final co2Anomaly = _detectOutliers(co2s, 'CO₂', 'ppm');
    if (co2Anomaly != null) anomalies.add(co2Anomaly);

    // Humidity analysis
    final humidities = readings.take(50).map((r) => (r['humidity'] ?? 0).toDouble()).toList().cast<double>();
    final humidityAnomaly = _detectOutliers(humidities, 'Humidity', '%');
    if (humidityAnomaly != null) anomalies.add(humidityAnomaly);

    return anomalies;
  }

  static Map<String, String>? _detectOutliers(List<double> values, String metric, String unit) {
    if (values.isEmpty) return null;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);
    final latest = values.first;
    final zScore = stdDev > 0 ? (latest - mean).abs() / stdDev : 0;

    // Z-score > 2 means outside 95% confidence interval
    if (zScore > 2.0) {
      return {
        'metric': metric,
        'message': '$metric showing unusual pattern (${zScore.toStringAsFixed(1)}σ from mean)',
        'severity': zScore > 3 ? 'critical' : 'warning',
      };
    }

    return null;
  }
}

class SmartRecommendations {
  /// Generates AI-powered recommendations
  static List<Map<String, dynamic>> getRecommendations(
    Map<String, dynamic>? latest,
    List<Map<String, dynamic>> readings,
    Map<String, dynamic> prediction,
  ) {
    if (latest == null) return [];

    List<Map<String, dynamic>> recommendations = [];

    final temp = (latest['temperature'] ?? 0).toDouble();
    final dissolvedOxygen = (latest['dissolved_oxygen'] ?? 0).toDouble();
    final ph = (latest['ph'] ?? 0).toDouble();

    // Temperature recommendations
    if (temp > 25) {
      recommendations.add({
        'type': 'warning',
        'icon': 'thermostat',
        'title': 'Temperature Alert',
        'message': 'Temperature elevated at ${temp.toStringAsFixed(1)}°C. Optimal fermentation range is 18-22°C.',
        'priority': 'high',
        'action': 'Activate cooling system or move to cooler location',
      });
    } else if (temp < 18) {
      recommendations.add({
        'type': 'info',
        'icon': 'ac_unit',
        'title': 'Temperature Low',
        'message': 'Temperature at ${temp.toStringAsFixed(1)}°C may slow fermentation.',
        'priority': 'medium',
        'action': 'Consider gentle warming to optimal range (18-22°C)',
      });
    }

    // pH recommendations
    if (ph < 3.0) {
      recommendations.add({
        'type': 'warning',
        'icon': 'science',
        'title': 'pH Too Low',
        'message': 'pH at ${ph.toStringAsFixed(2)} increases risk of microbial spoilage and harsh flavors.',
        'priority': 'high',
        'action': 'Consider malolactic fermentation or potassium bicarbonate addition',
      });
    } else if (ph > 4.0) {
      recommendations.add({
        'type': 'warning',
        'icon': 'science',
        'title': 'pH Too High',
        'message': 'pH at ${ph.toStringAsFixed(2)} may allow harmful bacteria growth.',
        'priority': 'high',
        'action': 'Add tartaric acid or conduct acidification',
      });
    } else if (ph >= 3.2 && ph <= 3.6) {
      recommendations.add({
        'type': 'success',
        'icon': 'verified',
        'title': 'Optimal pH',
        'message': 'pH at ${ph.toStringAsFixed(2)} is ideal for fermentation and stability.',
        'priority': 'info',
        'action': 'No action needed. Continue monitoring.',
      });
    }

    // Dissolved Oxygen recommendations
    if (dissolvedOxygen > 6.0) {
      recommendations.add({
        'type': 'warning',
        'icon': 'opacity',
        'title': 'High Dissolved Oxygen',
        'message': 'DO at ${dissolvedOxygen.toStringAsFixed(2)} mg/L may cause oxidation.',
        'priority': 'medium',
        'action': 'Ensure airlocks are sealed. Consider SO₂ addition.',
      });
    } else if (dissolvedOxygen < 2.0) {
      recommendations.add({
        'type': 'success',
        'icon': 'check_circle',
        'title': 'Good Oxygen Control',
        'message': 'DO at ${dissolvedOxygen.toStringAsFixed(2)} mg/L minimizes oxidation risk.',
        'priority': 'info',
        'action': 'Continue current management practices.',
      });
    }

    // If everything optimal
    if (recommendations.isEmpty) {
      recommendations.add({
        'type': 'success',
        'icon': 'verified',
        'title': 'Optimal Conditions',
        'message': 'All parameters within ideal ranges for fermentation',
        'priority': 'info',
        'action': 'No action needed. Continue monitoring.',
      });
    }

    return recommendations;
  }
}

