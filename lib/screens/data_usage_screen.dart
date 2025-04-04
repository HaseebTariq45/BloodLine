import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/data_usage_model.dart';
import '../utils/theme_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../services/service_locator.dart';

class DataUsageScreen extends StatefulWidget {
  const DataUsageScreen({super.key});

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDataUsage();
    });
  }

  Future<void> _refreshDataUsage() async {
    await serviceLocator.networkTracker.refreshDataUsage();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final dataUsage = appProvider.dataUsage;
    final isDarkMode = context.isDarkMode;

    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;

    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
    final double totalUsageFontSize = isSmallScreen ? 30.0 : 36.0;
    final double bodyTextFontSize = isSmallScreen ? 12.0 : 14.0;
    final double dateFontSize = isSmallScreen ? 12.0 : 14.0;
    final double valueTextFontSize = isSmallScreen ? 14.0 : 16.0;
    final double percentTextFontSize = isSmallScreen ? 10.0 : 12.0;

    // Calculate padding based on screen size
    final double horizontalPadding = screenWidth * 0.04;
    final double verticalPadding = isSmallScreen ? 12.0 : 16.0;
    final double cardPadding = isSmallScreen ? 16.0 : 20.0;
    final double iconSize = isSmallScreen ? 20.0 : 24.0;
    final double progressBarHeight = isSmallScreen ? 8.0 : 10.0;
    final double spacingBetweenCards = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Data Usage',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing data usage statistics...'),
                  duration: Duration(milliseconds: 500),
                ),
              );
              await _refreshDataUsage();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalUsageCard(
                    context,
                    dataUsage,
                    titleFontSize,
                    totalUsageFontSize,
                    dateFontSize,
                    cardPadding,
                  ),
                  SizedBox(height: spacingBetweenCards),
                  _buildUsageBreakdown(
                    context,
                    dataUsage,
                    titleFontSize,
                    valueTextFontSize,
                    percentTextFontSize,
                    iconSize,
                    progressBarHeight,
                    cardPadding,
                  ),
                  SizedBox(height: spacingBetweenCards),
                  _buildResetButton(context, appProvider, subtitleFontSize),
                  SizedBox(height: spacingBetweenCards),
                  _buildDataUsageInfo(
                    context,
                    titleFontSize,
                    subtitleFontSize,
                    bodyTextFontSize,
                    cardPadding,
                    iconSize,
                  ),
                  SizedBox(height: verticalPadding),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTotalUsageCard(
    BuildContext context,
    DataUsageModel dataUsage,
    double titleFontSize,
    double totalUsageFontSize,
    double dateFontSize,
    double padding,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color:
                context.isDarkMode
                    ? Colors.black12
                    : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Data Used',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: padding * 0.8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              DataUsageModel.formatBytes(dataUsage.totalBytes),
              style: TextStyle(
                fontSize: totalUsageFontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          SizedBox(height: padding * 0.4),
          Text(
            'Since ${dataUsage.lastReset.day}/${dataUsage.lastReset.month}/${dataUsage.lastReset.year}',
            style: TextStyle(
              fontSize: dateFontSize,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBreakdown(
    BuildContext context,
    DataUsageModel dataUsage,
    double titleFontSize,
    double valueTextFontSize,
    double percentTextFontSize,
    double iconSize,
    double progressBarHeight,
    double padding,
  ) {
    final totalBytes = dataUsage.totalBytes.toDouble();
    final wifiBytes = dataUsage.wifiBytes.toDouble();
    final mobileBytes = dataUsage.mobileBytes.toDouble();

    // Ensure we don't divide by zero
    final wifiPercentage =
        totalBytes > 0 ? (wifiBytes / totalBytes * 100) : 0.0;
    final mobilePercentage =
        totalBytes > 0 ? (mobileBytes / totalBytes * 100) : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color:
                context.isDarkMode
                    ? Colors.black12
                    : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Breakdown',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: padding),

          // WiFi usage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.wifi, color: Colors.blue, size: iconSize),
                  SizedBox(width: padding * 0.6),
                  Text(
                    'WiFi',
                    style: TextStyle(
                      fontSize: valueTextFontSize,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              Text(
                DataUsageModel.formatBytes(dataUsage.wifiBytes),
                style: TextStyle(
                  fontSize: valueTextFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: padding * 0.4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: wifiPercentage / 100,
              minHeight: progressBarHeight,
              backgroundColor: Colors.blue.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(height: padding * 0.2),
          Text(
            '${wifiPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: percentTextFontSize,
              color: context.secondaryTextColor,
            ),
          ),

          SizedBox(height: padding * 0.8),

          // Mobile data usage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.signal_cellular_alt,
                    color: Colors.orange,
                    size: iconSize,
                  ),
                  SizedBox(width: padding * 0.6),
                  Text(
                    'Mobile Data',
                    style: TextStyle(
                      fontSize: valueTextFontSize,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              Text(
                DataUsageModel.formatBytes(dataUsage.mobileBytes),
                style: TextStyle(
                  fontSize: valueTextFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: padding * 0.4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: mobilePercentage / 100,
              minHeight: progressBarHeight,
              backgroundColor: Colors.orange.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          SizedBox(height: padding * 0.2),
          Text(
            '${mobilePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: percentTextFontSize,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    AppProvider appProvider,
    double fontSize,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showResetConfirmationDialog(context, appProvider);
        },
        icon: const Icon(Icons.refresh),
        label: Text(
          'Reset Data Usage Statistics',
          style: TextStyle(fontSize: fontSize),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDataUsageInfo(
    BuildContext context,
    double titleFontSize,
    double subtitleFontSize,
    double bodyTextFontSize,
    double padding,
    double iconSize,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color:
              context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Data Usage Tracking',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: padding * 0.6),
          Text(
            'This screen shows the approximate amount of data used by the app since the last reset. Data is tracked for both WiFi and mobile connections.',
            style: TextStyle(
              fontSize: bodyTextFontSize,
              color: context.secondaryTextColor,
            ),
          ),
          SizedBox(height: padding * 0.8),
          Text(
            'Note:',
            style: TextStyle(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: padding * 0.4),
          Text(
            '• Data usage is tracked only while the app is running\n• Values are approximate and may differ from actual network usage\n• Data is tracked locally and not shared with anyone',
            style: TextStyle(
              fontSize: bodyTextFontSize,
              color: context.secondaryTextColor,
            ),
          ),
          if (_isPlatformWithLimitedConnectivityDetection()) ...[
            SizedBox(height: padding * 0.8),
            Container(
              padding: EdgeInsets.all(padding * 0.6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: iconSize),
                  SizedBox(width: padding * 0.6),
                  Expanded(
                    child: Text(
                      'On ${_getPlatformName()}, connectivity detection is limited. All traffic is categorized as WiFi.',
                      style: TextStyle(
                        fontSize: bodyTextFontSize,
                        color: context.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(
    BuildContext context,
    AppProvider appProvider,
  ) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 360;
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double bodyTextFontSize = isSmallScreen ? 12.0 : 14.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          title: Text(
            'Reset Data Usage',
            style: TextStyle(fontSize: titleFontSize, color: context.textColor),
          ),
          content: Text(
            'Are you sure you want to reset all data usage statistics? This action cannot be undone.',
            style: TextStyle(
              fontSize: bodyTextFontSize,
              color: context.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appProvider.resetDataUsage();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data usage statistics have been reset'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  bool _isPlatformWithLimitedConnectivityDetection() {
    // Desktop platforms (except macOS) and web have limited connectivity detection
    if (kIsWeb) return true;

    try {
      return Platform.isWindows || Platform.isLinux;
    } catch (e) {
      // If Platform is not available, assume limited detection
      return true;
    }
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web';

    try {
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isFuchsia) return 'Fuchsia';
      return 'this platform';
    } catch (e) {
      return 'this platform';
    }
  }
}
