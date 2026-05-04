import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:routefixer/widgets/segment_details_sheet.dart';

import '../services/road_segment_service.dart';
import '../models/road_segment.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // -------------------------
  // CONSTANTS
  // -------------------------
  static const LatLng _kKozhikode = LatLng(11.2588, 75.7804);
  static const double _defaultZoom = 13;
  static const double _userZoom = 16;

  // -------------------------
  // MAP STATE
  // -------------------------
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  bool _permissionGranted = false;
  bool _mapReady = false;
  bool _animationDone = false;

  double _currentZoom = _defaultZoom;
  LatLng _mapCenter = _kKozhikode;

  // -------------------------
  // SEGMENT STATE
  // -------------------------
  final RoadSegmentService _service = RoadSegmentService();
  final Set<Polyline> _polylines = {};

  Timer? _debounce;

  bool _isBottomSheetOpen = false;
  int? _selectedSegmentId;

  // -------------------------
  // INIT
  // -------------------------
  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // -------------------------
  // LOCATION INIT
  // -------------------------
  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();

      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever) {
        debugPrint("Location permanently denied");
        return;
      }

      _permissionGranted = true;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = LatLng(pos.latitude, pos.longitude);

      debugPrint("User location: ${pos.latitude}, ${pos.longitude}");

      if (_mapReady && !_animationDone) {
        _animationDone = true;
        _animateTo(_currentPosition!);
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // -------------------------
  // CAMERA ANIMATION
  // -------------------------
  Future<void> _animateTo(LatLng target) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: _userZoom),
      ),
    );
  }

  // -------------------------
  // FETCH SEGMENTS
  // -------------------------
  void _fetchSegments() {
    if (_isBottomSheetOpen) return;

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        debugPrint("Fetching segments at zoom $_currentZoom");

        final segments = await _service.fetchSegments(
          latitude: _mapCenter.latitude,
          longitude: _mapCenter.longitude,
          zoom: _currentZoom.round(),
        );

        debugPrint("Segments received: ${segments.length}");

        _drawPolylines(segments);
      } catch (e) {
        debugPrint("API error: $e");
      }
    });
  }

  // -------------------------
  // DRAW POLYLINES
  // -------------------------
  void _drawPolylines(List<RoadSegment> segments) {
    final polylines = segments.map((segment) {
      final isSelected = segment.id == _selectedSegmentId;

      return Polyline(
        polylineId: PolylineId('segment_${segment.id}'),
        points: segment.points,

        // Reduced width: e.g., 8 for normal, 12 for selected
        width: isSelected ? 12 : 8,

        color: isSelected ? Colors.blue : _severityColor(segment.severity),
        geodesic: true,
        consumeTapEvents: true,

        // --- ROUNDED EDGES SETTINGS ---
        jointType: JointType.round, // Rounds the elbow/joint of the line
        startCap: Cap.roundCap, // Rounds the start of the segment
        endCap: Cap.roundCap, // Rounds the end of the segment

        // ------------------------------
        onTap: () async {
          // ... (keep your existing onTap logic)
          if (_isBottomSheetOpen) return;
          setState(() {
            _selectedSegmentId = segment.id;
          });
          _isBottomSheetOpen = true;

          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => SegmentDetailsSheet(segmentId: segment.id),
          );

          _isBottomSheetOpen = false;
          if (mounted) {
            setState(() {
              _selectedSegmentId = null;
            });
          }
        },
      );
    }).toSet();

    if (!mounted) return;

    setState(() {
      _polylines
        ..clear()
        ..addAll(polylines);
    });
  }

  // -------------------------
  // SEVERITY COLOR
  // -------------------------
  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;

      case 'medium':
        return Colors.orange;

      case 'low':
        return Colors.yellow;

      default:
        return Colors.grey;
    }
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final initialTarget = _currentPosition ?? _kKozhikode;

    final initialZoom = _currentPosition == null ? _defaultZoom : _userZoom;

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialTarget,
          zoom: initialZoom,
        ),

        myLocationEnabled: _permissionGranted,

        myLocationButtonEnabled: false,

        zoomControlsEnabled: false,

        polylines: _polylines,

        onMapCreated: (controller) {
          debugPrint("Map created");

          _mapController = controller;

          _mapReady = true;

          if (_currentPosition != null && !_animationDone) {
            _animationDone = true;
            _animateTo(_currentPosition!);
          }
        },

        onCameraMove: (position) {
          _currentZoom = position.zoom;
          _mapCenter = position.target;
        },

        onCameraIdle: _fetchSegments,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blue),
        onPressed: () {
          if (_currentPosition != null) {
            _animateTo(_currentPosition!);
          }
        },
      ),
    );
  }
}
