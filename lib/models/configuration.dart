//import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Configuration {
  static const appName = 'JUST APARTMENT';
  static const imagesPath = './images';
  static const appLogo = "$imagesPath/logo.png";

  static const API_URL = 'https://justhomes.co.ke/api/';
  static const WEB_URL = 'https://justhomes.co.ke/';

  // static const API_URL = 'http://10.0.2.2:8000/api/';
  // static const WEB_URL = 'http://10.0.2.2:8000/';

  // static validateEmail(String email) {
  //   return RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
  //       .hasMatch(email);
  // }

  static validateEmail(String email) async {
    // bool emailValid = RegExp(
    //         r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
    //     .hasMatch(email);
    // return emailValid;

    return "name";
  }

  // Future<String?> getCountryFromIP() async {
  //   final response = await http.get(Uri.parse('http://ip-api.com/json/'));
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);

  //     print("COUNTRY DETAILS" + data.toString());
  //     return data['countryCode'];
  //   }
  //   return null;
  // }

  // static getCountryApiLink() {
  //   List<String> countries = ['KE', 'UG', 'TZ', 'NG'];
  // }

  Future<String?> getCountryFromIP() async {
    final response = await http.get(Uri.parse('http://ip-api.com/json/'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // print("COUNTRY DETAILS: ${data.toString()}");
      return data['countryCode'];
    }
    return null;
  }

  // Check if country is allowed directly here
  // Future<Map<String, String>> getCountryApiLink() async {
  //   final response = await http.get(Uri.parse('http://ip-api.com/json/'));

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     String countryCode = data['countryCode'] ?? 'KE';

  //     Map<String, Map<String, String>> countryLinks = {
  //       'KE': {
  //         'api': 'https://justhomes.co.ke/api/',
  //         'web': 'https://justhomes.co.ke/',
  //       },
  //       'UG': {
  //         'api': 'https://justhomes.ug/api/',
  //         'web': 'https://justhomes.ug/',
  //       },
  //       'TZ': {
  //         'api': 'https://justhomes.tz/api/',
  //         'web': 'https://justhomes.tz/',
  //       },
  //       'NG': {
  //         'api': 'https://justhomes.ng/api/',
  //         'web': 'https://justhomes.ng/',
  //       },
  //     };

  //     final links = countryLinks[countryCode] ?? countryLinks['KE']!;

  //     return links;
  //   }

  //   // Default to KE if lookup fails
  //   return {
  //     'api': 'https://justhomes.co.ke/api/',
  //     'web': 'https://justhomes.co.ke',
  //   };
  // }

  Future<Map<String, String>> getCountryApiLink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if country code and last fetch date are stored
    String? storedCountryCode = prefs.getString('countryCode');
    String? lastFetchedDateStr = prefs.getString('lastFetchedDate');

    DateTime? lastFetchedDate;
    if (lastFetchedDateStr != null) {
      lastFetchedDate = DateTime.parse(lastFetchedDateStr);
    }

    // If the country code is stored and not older than 14 days, use it
    if (storedCountryCode != null &&
        lastFetchedDate != null &&
        DateTime.now().difference(lastFetchedDate).inDays < 14) {
      return _getCountryLinks(storedCountryCode);
    } else {
      // If not stored or older than 14 days, fetch from the IP API
      final response = await http.get(Uri.parse('http://ip-api.com/json/'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String countryCode = data['countryCode'] ?? 'KE';

        // Store the country code and the current date in SharedPreferences
        prefs.setString('countryCode', countryCode);
        prefs.setString('lastFetchedDate', DateTime.now().toIso8601String());

        return _getCountryLinks(countryCode);
      } else {
        throw Exception('Failed to fetch country info');
      }
    }
  }

  Map<String, String> _getCountryLinks(String countryCode) {
    Map<String, Map<String, String>> countryLinks = {
      'KE': {
        'api': 'https://justhomes.co.ke/api/',
        'web': 'https://justhomes.co.ke/',
      },
      'UG': {
        'api': 'https://justhomes.ug/api/',
        'web': 'https://justhomes.ug/',
      },
      'TZ': {
        'api': 'https://justhomes.tz/api/',
        'web': 'https://justhomes.tz/',
      },
      'NG': {
        'api': 'https://justhomes.ng/api/',
        'web': 'https://justhomes.ng/',
      },
    };

    // Return the links for the country, defaulting to KE if not found
    return countryLinks[countryCode] ?? countryLinks['KE']!;
  }
}
