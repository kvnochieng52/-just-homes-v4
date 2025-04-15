import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_apartment_live/ui/property/post_step2_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PropertySubmissionService {
  Future<Map<String, dynamic>> submitProperty({
    required int step,
    required String propertyTitle,
    required String town,
    required String subRegion,
    required double latitude,
    required double longitude,
    required String country,
    required String countryCode,
    required String address,
    required int userId,
    required List<String> images,
    required BuildContext context,
    required String link,
  }) async {
    print("Submitting property...");

    await clearSavedImages();

    final String url = "${link}api/property/post";
    String imagesString = images.join(',');

    final Map<String, dynamic> queryParams = {
      "step": step.toString(),
      "propertyTitle": propertyTitle,
      "town": town,
      "subRegion": subRegion,
      "latitude": latitude.toString(),
      "longitude": longitude.toString(),
      "country": country,
      "countryCode": countryCode,
      "address": address,
      "user_id": userId.toString(),
      "images": imagesString,
    };

    print("Request Params: $queryParams");
    final Uri uri = Uri.parse(url).replace(queryParameters: queryParams);
    print("Request URL: $uri");

    try {
      final response = await http.post(uri);

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('data') &&
            responseData['data'].containsKey('propertyID')) {
          String propertyID = responseData['data']['propertyID'].toString();

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostStep2Page(propertyID: propertyID),
              ),
            );
          }

          return {"success": true, "propertyID": propertyID};
        } else {
          return {
            "success": false,
            "message": "Invalid response structure",
            "error": responseData,
          };
        }
      } else {
        return {
          "success": false,
          "message": "Failed to submit property",
          "error": jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "An error occurred",
        "error": e.toString(),
      };
    }
  }

  Future<void> clearSavedImages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uploaded_images'); // Remove the stored image paths list
    print('Saved image paths cleared.');
  }
}
