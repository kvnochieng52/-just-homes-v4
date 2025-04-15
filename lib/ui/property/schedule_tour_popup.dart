import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleTourPopup extends StatefulWidget {
  final String propertyId;

  const ScheduleTourPopup({super.key, required this.propertyId});

  @override
  _ScheduleTourPopupState createState() => _ScheduleTourPopupState();
}

class _ScheduleTourPopupState extends State<ScheduleTourPopup> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedTime;
  List<String> _timeOptions = [];
  bool _isTimeFieldDisabled = true;
  bool _isLoading = false; // Loading state
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    setState(() {
      _fullNameController.text = user['name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _telephoneController.text = user['telephone'] ?? '';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
        _fetchTimeDetails(
            DateFormat('yyyy-MM-dd').format(picked), widget.propertyId);
      });
    }
  }

  Future<void> _fetchTimeDetails(String selectedDate, String propertyId) async {
    setState(() {
      _isTimeFieldDisabled = true;
      _timeOptions = [];
    });

    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    try {
      var data = {
        'user_id': user['id'],
        'propertyID': propertyId,
        'date': selectedDate,
      };

      var res = await CallApi().postData(data, 'calendar/check-date');
      var responseData = json.decode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          _timeOptions = List<String>.from(responseData['data']['slots'] ?? []);
          _isTimeFieldDisabled = false;
        });
      } else {
        setState(() {
          _isTimeFieldDisabled = false;
        });
      }
    } catch (e) {
      setState(() {
        _isTimeFieldDisabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 24.0),
                        SizedBox(width: 6),
                        Text(
                          'Schedule Tour',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Select Date',
                          hintText: _selectedDate == null
                              ? 'Choose Date'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                        onTap: () => _selectDate(context),
                        validator: (value) {
                          if (_selectedDate == null) {
                            return 'Please select a date';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Time',
                        ),
                        value: _selectedTime,
                        items: _isTimeFieldDisabled
                            ? []
                            : _timeOptions
                                .map((time) => DropdownMenuItem(
                                      value: time,
                                      child: Text(time),
                                    ))
                                .toList(),
                        onChanged: _isTimeFieldDisabled
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedTime = value;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a time';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telephone',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your telephone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _submitForm(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.purple),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');

      var data = {
        'user_id': user['id'],
        'propertyID': widget.propertyId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': _selectedTime,
        'name': _fullNameController.text,
        'email': _emailController.text,
        'telephone': _telephoneController.text
      };

      var res = await CallApi().postData(data, 'calendar/submit');
      var responseData = json.decode(res.body);

      print(responseData);

      setState(() {
        _isLoading = false;
      });

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tour scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule tour. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      Navigator.of(context).pop(); // Close the dialog
    }
  }
}
