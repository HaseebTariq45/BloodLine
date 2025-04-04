class DataUsageModel {
  final int totalBytes;
  final int wifiBytes;
  final int mobileBytes;
  final DateTime lastReset;

  const DataUsageModel({
    required this.totalBytes,
    required this.wifiBytes,
    required this.mobileBytes,
    required this.lastReset,
  });

  // Create an empty model with zero usage
  factory DataUsageModel.empty() {
    return DataUsageModel(
      totalBytes: 0,
      wifiBytes: 0,
      mobileBytes: 0,
      lastReset: DateTime.now(),
    );
  }

  // Create a dummy model for UI preview
  factory DataUsageModel.dummy() {
    return DataUsageModel(
      totalBytes: 125000000, // 125 MB
      wifiBytes: 95000000,   // 95 MB
      mobileBytes: 30000000, // 30 MB
      lastReset: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  // Helper methods to convert bytes to readable formats
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }

  // Create a copy with updated values
  DataUsageModel copyWith({
    int? totalBytes,
    int? wifiBytes,
    int? mobileBytes,
    DateTime? lastReset,
  }) {
    return DataUsageModel(
      totalBytes: totalBytes ?? this.totalBytes,
      wifiBytes: wifiBytes ?? this.wifiBytes,
      mobileBytes: mobileBytes ?? this.mobileBytes,
      lastReset: lastReset ?? this.lastReset,
    );
  }
} 