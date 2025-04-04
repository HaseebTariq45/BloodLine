import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../models/blood_bank_model.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/location_service.dart';
import '../models/donation_model.dart';
import 'package:intl/intl.dart';

class BloodBanksScreen extends StatefulWidget {
  const BloodBanksScreen({super.key});

  @override
  State<BloodBanksScreen> createState() => _BloodBanksScreenState();
}

class _BloodBanksScreenState extends State<BloodBanksScreen> {
  GoogleMapController? _mapController;
  bool _showListView = false;
  bool _isLoading = true;
  bool _isLocationEnabled = false;
  final Map<MarkerId, Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};
  double _maxDistance = 5000; // 5 km default
  Position? _currentPosition;
  List<BloodBankModel> _nearbyBloodBanks = [];

  // Default camera position (will be updated with user's location)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194), // Sample location (San Francisco)
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.checkLocationStatus();

    if (appProvider.isLocationEnabled) {
      setState(() {
        _isLocationEnabled = true;
      });
      await _getCurrentLocation();
    } else {
      setState(() {
        _isLocationEnabled = false;
        _isLoading = false;
      });
      _showLocationPermissionDialog();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationService = LocationService();

      // Get current position
      Position? position = await locationService.getCurrentPosition();

      if (position == null) {
        setState(() {
          _isLocationEnabled = false;
          _isLoading = false;
        });
        _showLocationServiceDialog();
        return;
      }

      setState(() {
        _currentPosition = position;
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14,
        );
        _isLoading = false;
      });

      // Move camera to current position
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        );
      }

      // Add marker for current location
      _addMarker(
        LatLng(position.latitude, position.longitude),
        "current_location",
        "Your Location",
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      // Search for nearby blood banks
      await _searchNearbyBloodBanks();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error getting location: $e');
    }
  }

  Future<void> _searchNearbyBloodBanks() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would fetch from Google Places API
      // For now, we'll simulate with dummy data but with real coordinates
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final dummyBanks = appProvider.bloodBanks;

      // Create a list of blood banks with current location-based positions
      List<BloodBankModel> nearbyBanks = [];

      for (int i = 0; i < dummyBanks.length; i++) {
        // Generate positions around the user's current location
        double lat =
            _currentPosition!.latitude + (i * 0.005) * (i % 2 == 0 ? 1 : -1);
        double lng =
            _currentPosition!.longitude + (i * 0.005) * (i % 3 == 0 ? 1 : -1);

        // Calculate actual distance
        double distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );

        // Create new blood bank with updated coordinates and distance
        BloodBankModel bank = BloodBankModel(
          id: dummyBanks[i].id,
          name: dummyBanks[i].name,
          address: dummyBanks[i].address,
          phone: dummyBanks[i].phone,
          latitude: lat,
          longitude: lng,
          openingHours: dummyBanks[i].openingHours,
          isOpen: dummyBanks[i].isOpen,
          rating: dummyBanks[i].rating,
          distance: distanceInMeters.toInt(),
          availableBloodTypes: dummyBanks[i].availableBloodTypes,
        );

        nearbyBanks.add(bank);
      }

      // Sort by distance
      nearbyBanks.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _nearbyBloodBanks = nearbyBanks;
        _isLoading = false;
      });

      // Add markers for blood banks
      for (var bank in nearbyBanks.where((b) => b.distance <= _maxDistance)) {
        _addMarker(
          LatLng(bank.latitude, bank.longitude),
          bank.id,
          bank.name,
          BitmapDescriptor.defaultMarkerWithHue(
            bank.isOpen ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
          ),
          bank: bank,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error searching for blood banks: $e');
    }
  }

  void _addMarker(
    LatLng position,
    String markerId,
    String title,
    BitmapDescriptor icon, {
    BloodBankModel? bank,
  }) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: bank?.address ?? 'Your current location',
        onTap: bank != null ? () => _showBloodBankInfo(bank) : null,
      ),
      icon: icon,
      onTap: bank != null ? () => _showBloodBankInfo(bank) : null,
    );

    setState(() {
      _markers[MarkerId(markerId)] = marker;
    });
  }

  void _getPolyline(BloodBankModel bank) async {
    if (_currentPosition == null) return;

    PolylineId id = PolylineId(bank.id);

    // Clear existing polylines
    setState(() {
      _polylines.clear();
    });

    // In a real app, you would get directions from Google Directions API
    // For demo purposes, we'll create a simple straight line
    List<LatLng> polylineCoordinates = [
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(bank.latitude, bank.longitude),
    ];

    Polyline polyline = Polyline(
      polylineId: id,
      color: AppConstants.primaryColor,
      points: polylineCoordinates,
      width: 3,
    );

    setState(() {
      _polylines[id] = polyline;
    });
  }

  void _filterByDistance(double value) {
    setState(() {
      _maxDistance = value;
      _markers.removeWhere(
        (id, marker) =>
            id.value != "current_location" &&
            _nearbyBloodBanks.any(
              (bank) => bank.id == id.value && bank.distance > _maxDistance,
            ),
      );

      // Add back any blood banks that are now within range
      for (var bank in _nearbyBloodBanks.where(
        (b) => b.distance <= _maxDistance,
      )) {
        if (!_markers.containsKey(MarkerId(bank.id))) {
          _addMarker(
            LatLng(bank.latitude, bank.longitude),
            bank.id,
            bank.name,
            BitmapDescriptor.defaultMarkerWithHue(
              bank.isOpen ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
            ),
            bank: bank,
          );
        }
      }
    });
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'This feature requires location permission to find blood banks near you. '
            'Please enable location permission in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OPEN SETTINGS'),
              onPressed: () {
                Navigator.of(context).pop();
                LocationService().openApplicationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'This feature requires location services to be enabled. '
            'Please enable location services in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showBloodBankInfo(BloodBankModel bank) {
    // Draw route to this blood bank
    _getPolyline(bank);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusL),
        ),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bank.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            bank.isOpen
                                ? AppConstants.successColor.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bank.isOpen ? 'Open' : 'Closed',
                        style: TextStyle(
                          color:
                              bank.isOpen
                                  ? AppConstants.successColor
                                  : Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppConstants.lightTextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        bank.address,
                        style: const TextStyle(
                          color: AppConstants.lightTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bank.formattedDistance,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppConstants.lightTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bank.openingHours,
                      style: const TextStyle(
                        color: AppConstants.lightTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      size: 16,
                      color: AppConstants.lightTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bank.phone,
                      style: const TextStyle(
                        color: AppConstants.lightTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      bank.rating.toString(),
                      style: const TextStyle(
                        color: AppConstants.darkTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Available Blood Types',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      bank.availableBloodTypes.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value} units',
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _scheduleDonation(bank),
                    icon: const Icon(Icons.favorite),
                    label: const Text('Schedule Donation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Implement call action
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calling blood bank...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Blood Bank'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Implement directions action
                      Navigator.pop(context);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngBounds(
                          _getBounds([
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            LatLng(bank.latitude, bank.longitude),
                          ]),
                          100, // Padding in pixels
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Method to schedule a blood donation
  void _scheduleDonation(BloodBankModel bank) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (!appProvider.isLoggedIn) {
      Navigator.of(context).pop(); // Close the blood bank info sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to schedule a donation'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pushNamed('/login');
      return;
    }

    // Show date picker to select donation date
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppConstants.darkTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) {
      // User cancelled the date picker
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create donation model
      final donation = DonationModel.create(
        donorId: appProvider.currentUser.id,
        donorName: appProvider.currentUser.name,
        bloodType: appProvider.currentUser.bloodType,
        centerName: bank.name,
        address: bank.address,
      ).copyWith(date: selectedDate);

      // Add donation via AppProvider
      final success = await appProvider.addDonation(donation);

      // Close loading indicator
      Navigator.of(context).pop();

      // Close blood bank sheet
      Navigator.of(context).pop();

      if (success) {
        // Show success dialog with animation
        _showDonationScheduledDialog(donation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule donation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Show success dialog for scheduled donation
  void _showDonationScheduledDialog(DonationModel donation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Donation Scheduled!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You have scheduled a blood donation at ${donation.centerName} on ${DateFormat('EEEE, MMMM d, yyyy').format(donation.date)}.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppConstants.lightTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/donation_history');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('View My Donations'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      northeast: LatLng(maxLat, maxLng),
      southwest: LatLng(minLat, minLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBloodBanks =
        _nearbyBloodBanks
            .where((bank) => bank.distance <= _maxDistance)
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Nearby Blood Banks'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : !_isLocationEnabled
              ? _buildLocationDisabledView()
              : Column(
                children: [
                  // Filter section
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Distance Filter',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${(_maxDistance / 1000).toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            valueIndicatorShape:
                                const PaddleSliderValueIndicatorShape(),
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          child: Slider(
                            value: _maxDistance,
                            min: 1000, // 1 km
                            max: 10000, // 10 km
                            divisions: 9,
                            label:
                                '${(_maxDistance / 1000).toStringAsFixed(1)} km',
                            activeColor: AppConstants.primaryColor,
                            inactiveColor: AppConstants.primaryColor
                                .withOpacity(0.2),
                            onChanged: (value) {
                              _filterByDistance(value);
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const Text('1 km'), const Text('10 km')],
                        ),
                        const SizedBox(height: 8),
                        // Toggle Map/List view
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showListView = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        !_showListView
                                            ? AppConstants.primaryColor
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusM,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.map,
                                        color:
                                            !_showListView
                                                ? Colors.white
                                                : AppConstants.lightTextColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Map',
                                        style: TextStyle(
                                          color:
                                              !_showListView
                                                  ? Colors.white
                                                  : AppConstants.lightTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showListView = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _showListView
                                            ? AppConstants.primaryColor
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusM,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.list,
                                        color:
                                            _showListView
                                                ? Colors.white
                                                : AppConstants.lightTextColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'List',
                                        style: TextStyle(
                                          color:
                                              _showListView
                                                  ? Colors.white
                                                  : AppConstants.lightTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Map or List View
                  Expanded(
                    child:
                        _showListView
                            ? _buildListView(filteredBloodBanks)
                            : _buildMapView(),
                  ),
                ],
              ),
      floatingActionButton:
          !_isLoading && _isLocationEnabled && !_showListView
              ? FloatingActionButton(
                onPressed: () {
                  if (_currentPosition != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                      ),
                    );
                  }
                },
                backgroundColor: AppConstants.primaryColor,
                child: const Icon(Icons.my_location),
              )
              : null,
    );
  }

  Widget _buildLocationDisabledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Location Services Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To find blood banks near you, we need access to your location.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final appProvider = Provider.of<AppProvider>(
                  context,
                  listen: false,
                );
                setState(() {
                  _isLoading = true;
                });

                bool success = await appProvider.enableLocation();
                if (success) {
                  _getCurrentLocation();
                } else {
                  setState(() {
                    _isLoading = false;
                  });
                  _showLocationPermissionDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  const Text('Enable Location'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      markers: Set<Marker>.of(_markers.values),
      polylines: Set<Polyline>.of(_polylines.values),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      zoomControlsEnabled: false,
    );
  }

  Widget _buildListView(List<BloodBankModel> bloodBanks) {
    if (bloodBanks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No blood banks found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing the distance filter',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: bloodBanks.length,
      itemBuilder: (context, index) {
        final bank = bloodBanks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: InkWell(
            onTap: () => _showBloodBankInfo(bank),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bank.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bank.address,
                              style: const TextStyle(
                                color: AppConstants.lightTextColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoItem(
                        icon: Icons.access_time,
                        text: bank.isOpen ? 'Open Now' : 'Closed',
                        color:
                            bank.isOpen
                                ? AppConstants.successColor
                                : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        icon: Icons.location_on,
                        text: bank.formattedDistance,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoItem(
                        icon: Icons.star,
                        text: bank.rating.toString(),
                        color: Colors.amber,
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _showBloodBankInfo(bank),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusM,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
