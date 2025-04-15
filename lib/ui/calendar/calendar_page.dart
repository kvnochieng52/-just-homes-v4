import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/widgets/custom_navigation_bar.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this package to your pubspec.yaml for URL launching
import 'package:intl/intl.dart';

class CalendarWithEvents extends StatefulWidget {
  const CalendarWithEvents({super.key});

  @override
  _CalendarWithEventsState createState() => _CalendarWithEventsState();
}

class _CalendarWithEventsState extends State<CalendarWithEvents> {
  late final ValueNotifier<List<Event>> _selectedEvents;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  late int _selectedFooterIndex = 0;
  bool _isCalendarVisible = true; // Add this state variable

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  static const List<int> _years = [
    2020,
    2021,
    2022,
    2023,
    2024,
    2025,
    2026,
    2027,
    2028,
    2029,
    2030
  ];

  final Map<DateTime, List<Event>> _events = {
    DateTime(2024, 9, 19): [
      Event('', '10:00 AM', '12:00 PM', '', '', 'Property 1', '1'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
    _getCalendarDetails();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _toggleCalendarVisibility() {
    setState(() {
      _isCalendarVisible = !_isCalendarVisible;
    });
  }

  Future<void> _getCalendarDetails() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    var data = {
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'calendar/get-events');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);
      if (body['success']) {
        var eventsData = body['data']['events'];

        // Create a temporary map to store the events
        Map<DateTime, List<Event>> newEvents = {};

        if (eventsData != null && eventsData.isNotEmpty) {
          eventsData.forEach((date, eventsList) {
            DateTime parsedDate = DateTime.parse(date);

            // Check if eventsList is a List and not null or empty
            if (eventsList is List && eventsList.isNotEmpty) {
              // Convert each event in the eventsList to an Event object
              List<Event> dayEvents = (eventsList).map<Event>((eventData) {
                // Ensure eventData has the necessary fields before creating an Event
                return Event(
                  eventData['name']?.toString() ?? '',
                  eventData['start_time']?.toString() ?? '',
                  eventData['end_time']?.toString() ?? '',
                  eventData['telephone']?.toString() ?? '',
                  eventData['email']?.toString() ?? '',
                  eventData['property_name']?.toString() ?? '',
                  eventData['calendar_id']?.toString() ??
                      '', // Ensure calendar_id is included
                );
              }).toList();

              // Add the events to the corresponding date in the newEvents map
              newEvents[parsedDate] = dayEvents;
            } else {
              // Handle the case where eventsList is null or empty
              print('No events found for date: $date');
            }
          });
        } else {
          print('No events data found.');
        }

        // Update the _events map with the new events
        setState(() {
          _events.clear();
          _events.addAll(newEvents);

          // Also update _selectedEvents in case the selected day has new events
          _selectedEvents.value = _getEventsForDay(_selectedDay);
        });
      }
    } else {
      // Handle the error (e.g., show a message)
      print('Error fetching calendar events: ${res.statusCode}');
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onMonthChanged(String? selectedMonth) {
    if (selectedMonth != null) {
      setState(() {
        int monthIndex = _months.indexOf(selectedMonth) + 1;
        _focusedDay = DateTime(_focusedDay.year, monthIndex, _focusedDay.day);
      });
    }
  }

  void _onYearChanged(int? selectedYear) {
    if (selectedYear != null) {
      setState(() {
        _focusedDay =
            DateTime(selectedYear, _focusedDay.month, _focusedDay.day);
      });
    }
  }

  void _showEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Center(
                  child: Text(
                    'Appointment Details',
                    style: TextStyle(
                        fontSize: 18.0), // Adjust the font size as needed
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 16.0),
                    const SizedBox(width: 4.0),
                    Text(
                      event.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 16.0),
                    const SizedBox(width: 4.0),
                    Text('${event.from} - ${event.to}'),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 16.0),
                    const SizedBox(width: 4.0),
                    Text(event.telephone),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email, size: 16.0),
                    const SizedBox(width: 4.0),
                    Text(event.email),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home, size: 16.0),
                    const SizedBox(width: 4.0),
                    Expanded(
                      // Ensures text wraps within the available space
                      child: Text(
                        event.propertyName,
                        overflow: TextOverflow
                            .visible, // Allows text to wrap and remain visible
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Column(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _callNumber(event.telephone);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.phone, size: 18.0),
                  label: const Text('Call', style: TextStyle(fontSize: 14.0)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48), // Full width
                  ),
                ),
                const SizedBox(height: 8.0),
                OutlinedButton.icon(
                  onPressed: () {
                    _sendEmail(event.email);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.email, size: 18.0),
                  label: const Text('Email', style: TextStyle(fontSize: 14.0)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48), // Full width
                  ),
                ),
                const SizedBox(height: 8.0),
                OutlinedButton(
                  onPressed: () async {
                    await _cancelAppointment(context,
                        event.calendarId); // Pass the event's calendarId
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48), // Full width
                  ),
                  child: const Text('Cancel Appointment',
                      style: TextStyle(fontSize: 14.0)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _callNumber(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle error (e.g., show a message)
      print('Could not launch $launchUri');
    }
  }

  void _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle error (e.g., show a message)
      print('Could not launch $launchUri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildHeader(context),
      //drawer: drawer(context),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedFooterIndex,
        onItemSelected: (index) {
          if (mounted) {
            setState(() {
              _selectedFooterIndex = index;
            });
          }
        },
      ),
      body: Column(
        children: [
          if (_isCalendarVisible)
            TableCalendar(
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedEvents.value = _getEventsForDay(selectedDay);
                  });
                }
              },
              onFormatChanged: (format) {
                // Do nothing, as we won't allow format changes
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: _buildEventsMarker(events.length),
                    );
                  }
                  return null;
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false, // Hide format buttons
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[300],
                ),
              ),
            ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Aligns children to far left and right
                children: [
                  // Toggle calendar button and text on the left
                  GestureDetector(
                    onTap:
                        _toggleCalendarVisibility, // Toggle visibility when text or icon is tapped
                    child: Row(
                      children: [
                        Icon(
                          _isCalendarVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isCalendarVisible
                              ? 'Hide Calendar'
                              : 'Show Calendar',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),

                  // Month and Year selectors on the right
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _months[_focusedDay.month - 1],
                        items: _months
                            .map<DropdownMenuItem<String>>((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                        onChanged: _onMonthChanged,
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _focusedDay.year,
                        items: _years.map<DropdownMenuItem<int>>((int year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: _onYearChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                // Check if there are no events for the selected date
                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      'No meetings on ${DateFormat.yMMMMd().format(_selectedDay)}', // Display the date
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView(
                  children: events
                      .map((event) => GestureDetector(
                            onTap: () => _showEventDialog(event),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4.0, horizontal: 8.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      event.name[0],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${event.from} - ${event.to}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8.0),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.phone,
                                              color: Colors.white,
                                              size: 14.0,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Expanded(
                                              child: Text(
                                                event.telephone,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4.0),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.email,
                                              color: Colors.white,
                                              size: 14.0,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Expanded(
                                              child: Text(
                                                event.email,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11.0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(
      BuildContext context, String calendarId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content:
              const Text('Are you sure you want to cancel this appointment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // User clicks No
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(true), // User clicks Yes
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    // If the user did not confirm, return early
    if (confirmed != true) return;

    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var user = json.decode(localStorage.getString('user') ?? '{}');

      var data = {
        'user_id': user['id'],
        'calendar_id': calendarId,
      };

      var res = await CallApi().postData(data, 'calendar/cancel-event');

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (body['success']) {
          // Show confirmation dialog for successful cancellation
          showDialog<void>(
            context: context,
            barrierDismissible:
                false, // Prevents closing the dialog by tapping outside
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Cancellation Successful'),
                content: const Text('Appointment successfully canceled.'),
                actions: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.purple, // Purple background
                      foregroundColor: Colors.white, // Text color
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      // Redirect to the same page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CalendarWithEvents(), // Your page widget
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh), // Reload icon
                        SizedBox(width: 8), // Space between icon and text
                        Text('Reload Calendar'),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          // Handle failure case
          print('Failed to cancel appointment');
        }
      } else {
        // Handle error in API response
        print('Error canceling appointment');
      }
    } catch (e) {
      // Handle exception
      print('Exception occurred while canceling appointment: $e');
    }
  }

  Widget _buildEventsMarker(int count) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}

class Event {
  final String name;
  final String from;
  final String to;
  final String telephone;
  final String email;
  final String propertyName;
  final String calendarId;

  Event(this.name, this.from, this.to, this.telephone, this.email,
      this.propertyName, this.calendarId);
}
