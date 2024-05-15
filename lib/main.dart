import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart' as google_place;
import 'package:google_maps_webservice/places.dart'
    as google_maps_webservice; // Add this import

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maps Demo',
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _selectedLocation;
  List<google_place.SearchResult> _nearbyBusinesses = [];

  google_place.GooglePlace googlePlace =
      google_place.GooglePlace("Your API Key Here");

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
    });

    // Call Places API to get nearby places
    var response = await googlePlace.search.getNearBySearch(
        google_place.Location(
          lat: location.latitude,
          lng: location.longitude,
        ),
        20 // Radius of 50 meters
        );

    if (response != null && response.results != null) {
      setState(() {
        _nearbyBusinesses = response.results!;
      });

      // Sort the list of nearby businesses based on their distance from the tapped location
      _nearbyBusinesses.sort((a, b) {
        double distanceToA = _calculateDistance(
            _selectedLocation!.latitude,
            _selectedLocation!.longitude,
            a.geometry!.location!.lat,
            a.geometry!.location!.lng);
        double distanceToB = _calculateDistance(
            _selectedLocation!.latitude,
            _selectedLocation!.longitude,
            b.geometry!.location!.lat,
            b.geometry!.location!.lng);
        return distanceToA.compareTo(distanceToB);
      });

      // Show bottom sheet with nearby businesses
      _showNearbyBusinessesBottomSheet(context);
    }
  }

  Future<void> _searchPlaces() async {
    final p = await PlacesAutocomplete.show(
      context: context,
      logo: Text(""),
      mode: Mode.overlay,
      apiKey: "Your API Key Here",
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.errorMessage ?? 'Unknown error'),
          ),
        );
      },
    );

    if (p != null) {
      final places =
          google_maps_webservice.GoogleMapsPlaces(apiKey: "Your API Key Here");
      final details = await places.getDetailsByPlaceId(p.placeId!);
      final lat = details.result.geometry!.location.lat;
      final lng = details.result.geometry!.location.lng;

      setState(() {
        _selectedLocation = LatLng(lat, lng);
      });

      // Call _onMapTapped to fetch nearby businesses and update _nearbyBusinesses list
      _onMapTapped(LatLng(lat, lng));

      // Move camera to the selected location
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          16.0, // You can adjust the zoom level as needed
        ),
      );

      // Show bottom sheet with nearby businesses
      // _showNearbyBusinessesBottomSheet(context);
    }
  }

  double _calculateDistance(double? startLatitude, double? startLongitude,
      double? endLatitude, double? endLongitude) {
    if (startLatitude == null ||
        startLongitude == null ||
        endLatitude == null ||
        endLongitude == null) {
      return double.infinity;
    }
    const int radiusOfEarth = 6371000; // in meters
    double lat1 = startLatitude * (pi / 180);
    double lat2 = endLatitude * (pi / 180);
    double lon1 = startLongitude * (pi / 180);
    double lon2 = endLongitude * (pi / 180);
    double deltaLat = lat2 - lat1;
    double deltaLon = lon2 - lon1;
    double a = (pow(sin(deltaLat / 2), 2)) +
        (cos(lat1) * cos(lat2) * (pow(sin(deltaLon / 2), 2)));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radiusOfEarth * c;
  }

  void _showNearbyBusinessesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Color.fromARGB(255, 255, 255, 255),
          padding: EdgeInsets.all(16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 5.0, bottom: 5, left: 15, right: 0),
                    child: Text(
                      'Nearby Businesses',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                  Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 25,
                  )
                ],
              ),
              SizedBox(height: 10),
              for (var business in _nearbyBusinesses)
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2.0, vertical: 5),
                      child: ListTile(
                        title: Text(
                          business.name!,
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.white),
                        ),
                        subtitle: Text(
                          business.vicinity!,
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.normal,
                              fontSize: 15,
                              color: Colors.white),
                        ),
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onMapTapped,
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 17,
              ),
              markers: _selectedLocation == null
                  ? Set<Marker>()
                  : {
                      Marker(
                        markerId: MarkerId("selectedLocation"),
                        position: _selectedLocation!,
                      ),
                    },
            ),
          ),
        ],
      ),
    );
  }
}
