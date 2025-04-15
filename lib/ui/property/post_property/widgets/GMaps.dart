import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'package:just_apartment_live/ui/reelsplayer/reels_page.dart';

class LocationFormField extends StatefulWidget {
  final String apiKey;
  final Function(Map<String, dynamic>?)? onSaved;
  final String? initialValue;
  final String hintText;
  final Function(Map<String, dynamic>?)? onChanged;

  const LocationFormField({
    Key? key,
    required this.apiKey,
    this.onSaved,
    this.onChanged,
    this.initialValue,
    this.hintText = "Search for a location",
  }) : super(key: key);

  @override
  _LocationFormFieldState createState() => _LocationFormFieldState();
}

class _LocationFormFieldState extends State<LocationFormField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Map<String, dynamic>? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getCountyFromPlaceId(
      String placeId, String mainText) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=${widget.apiKey}';

    logger.e("URLK $url");
    final response = await http.get(Uri.parse(url));

    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      List addressComponents = data['results'][0]['address_components'];
      Map<String, dynamic> addressInfo = {
        "latitude": data['results'][0]['geometry']['location']['lat'],
        "longitude": data['results'][0]['geometry']['location']['lng'],
        "description": data['results'][0]['formatted_address'],
        "mainText": mainText ?? ""
      };

      for (var component in addressComponents) {
        if (component['types'].contains('administrative_area_level_1')) {
          addressInfo["county"] = component['long_name'];
        }
        if (component['types'].contains('sublocality_level_1')) {
          addressInfo["locality"] = component['long_name'];
        }
      }

      print("Parsed Location Data: $addressInfo");
      return addressInfo;
    } else {
      print("API Error: ${data['status']} - ${data['error_message']}");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Map<String, dynamic>>(
      initialValue: null,
      onSaved: (value) {
        if (widget.onSaved != null) {
          widget.onSaved!(_selectedLocation);
        }
      },
      builder: (FormFieldState<Map<String, dynamic>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _controller,
                googleAPIKey: widget.apiKey,
                focusNode: _focusNode,
                inputDecoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                countries: ['ke'], // Limit to Kenya
                isLatLngRequired: false,

                itemClick: (Prediction prediction) async {
                  if (prediction.placeId != null) {
                    final county = await getCountyFromPlaceId(
                        prediction.placeId!,
                        prediction.structuredFormatting!.mainText.toString());
                    if (county != null) {
                      state.didChange(county);
                      setState(() {
                        _selectedLocation = county;
                        _controller.text = prediction.description ?? '';
                      });

                      // Trigger onChanged
                      if (widget.onChanged != null) {
                        widget.onChanged!(county);
                      }
                    }
                  }
                },
                getPlaceDetailWithLatLng: (Prediction prediction) async {
                  if (prediction.placeId != null) {
                    final county = await getCountyFromPlaceId(
                        prediction.placeId!,
                        prediction.structuredFormatting!.mainText.toString());
                    if (county != null) {
                      state.didChange(county);
                      setState(() {
                        _selectedLocation = county;
                        _controller.text = prediction.description ?? '';
                      });

                      // Trigger onChanged
                      if (widget.onChanged != null) {
                        widget.onChanged!(county);
                      }
                    }
                  }
                },

                itemBuilder: (context, index, prediction) => ListTile(
                  title: Text(prediction.description ?? ''),
                ),
                debounceTime: 300,
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

class LocationFormField2 extends StatefulWidget {
  final String apiKey;
  final Function(Map<String, dynamic>?)? onSaved;
  final String? initialValue;
  final String hintText;
  final Function(Map<String, dynamic>?)? onChanged;

  const LocationFormField2({
    Key? key,
    required this.apiKey,
    this.onSaved,
    this.onChanged,
    this.initialValue,
    this.hintText = "Search for a location",
  }) : super(key: key);

  @override
  _LocationFormField2State createState() => _LocationFormField2State();
}

class _LocationFormField2State extends State<LocationFormField2> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Map<String, dynamic>? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getCountyFromPlaceId(
      String placeId, String mainText) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=${widget.apiKey}';

    logger.e("URLK $url");
    final response = await http.get(Uri.parse(url));

    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      List addressComponents = data['results'][0]['address_components'];
      Map<String, dynamic> addressInfo = {
        "latitude": data['results'][0]['geometry']['location']['lat'],
        "longitude": data['results'][0]['geometry']['location']['lng'],
        "description": data['results'][0]['formatted_address'],
        "mainText": mainText ?? ""
      };

      for (var component in addressComponents) {
        if (component['types'].contains('administrative_area_level_1')) {
          addressInfo["county"] = component['long_name'];
        }
        if (component['types'].contains('sublocality_level_1')) {
          addressInfo["locality"] = component['long_name'];
        }
      }

      print("Parsed Location Data: $addressInfo");
      return addressInfo;
    } else {
      print("API Error: ${data['status']} - ${data['error_message']}");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Map<String, dynamic>>(
      initialValue: null,
      onSaved: (value) {
        if (widget.onSaved != null) {
          widget.onSaved!(_selectedLocation);
        }
      },
      builder: (FormFieldState<Map<String, dynamic>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _controller,
                googleAPIKey: widget.apiKey,
                boxDecoration: BoxDecoration(),
                focusNode: _focusNode,
                inputDecoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1), // Remove the faint border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                        color: Colors.grey, width: 1), // Remove enabled border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                        color: Colors.blue, width: 2), // Highlight on focus
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        BorderSide(color: Colors.red, width: 1), // Error state
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                countries: ['ke'],
                isLatLngRequired: false,
                itemClick: (Prediction prediction) async {
                  if (prediction.placeId != null) {
                    final county = await getCountyFromPlaceId(
                        prediction.placeId!,
                        prediction.structuredFormatting!.mainText.toString());
                    if (county != null) {
                      state.didChange(county);
                      setState(() {
                        _selectedLocation = county;
                        _controller.text = prediction.description ?? '';
                      });

                      // Trigger onChanged
                      widget.onChanged?.call(county);
                    }
                  }
                },
                getPlaceDetailWithLatLng: (Prediction prediction) async {
                  if (prediction.placeId != null) {
                    final county = await getCountyFromPlaceId(
                        prediction.placeId!,
                        prediction.structuredFormatting!.mainText.toString());
                    if (county != null) {
                      state.didChange(county);
                      setState(() {
                        _selectedLocation = county;
                        _controller.text = prediction.description ?? '';
                      });

                      // Trigger onChanged
                      widget.onChanged?.call(county);
                    }
                  }
                },
                itemBuilder: (context, index, prediction) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(prediction.description ?? ''),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20), // Smooth rounded corners
                    ),
                  ),
                ),
                debounceTime: 300,
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }
}
