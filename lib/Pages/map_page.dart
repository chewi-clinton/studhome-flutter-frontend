import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MapPage({super.key, required this.latitude, required this.longitude});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  bool _isPermissionGranted = false;
  final Set<Marker> _markers = {};

  late final CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();

    _initialPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: 15,
    );
    _requestLocationPermission();
    _addMarker();
  }

  Future<void> _requestLocationPermission() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted == PermissionStatus.granted) {
        setState(() {
          _isPermissionGranted = true;
        });
      }
    } else {
      setState(() {
        _isPermissionGranted = true;
      });
    }
  }

  void _addMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('house_location'),
          position: LatLng(widget.latitude, widget.longitude),
          infoWindow: const InfoWindow(title: 'House Location'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: dotenv.load(fileName: ".env"),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
          if (googleApiKey == null || googleApiKey.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text('Error: Google Maps API key is missing'),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text("House Location")),
            body: _isPermissionGranted
                ? GoogleMap(
                    initialCameraPosition: _initialPosition,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapType: MapType.normal,
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
