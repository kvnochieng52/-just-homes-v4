import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_apartment_live/api/api.dart';
import 'package:just_apartment_live/ui/property/post_property/widgets/GMaps.dart';
import 'package:just_apartment_live/ui/property/price_input_formatter.dart';
import 'package:just_apartment_live/ui/property/search_results_page.dart';
import 'package:just_apartment_live/widgets/header_main_widget.dart';
import 'package:just_apartment_live/widgets/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _parkingSpacesController = TextEditingController();
  final _sqmController = TextEditingController();
  final _locationController = TextEditingController();

  List<String> _propertTypesByNameList = [];

  List<String> _propertConditionsList = [];

  List<String> _furnishedList = [];

  List<Map<String, dynamic>> _leaseTypesList = [];
  var _leaseType = '';

  // ignore: unused_field
  bool _initDataFetched = false;

  List _selectedPropertyTypesArray = [];
  List _selectedPropertyConditionArray = [];
  List _selectedFurnishedArray = [];
  List _selectedBedroomsArray = [];
  String _selectedAuction = '0';
  String _selectedOffPlan = '0';
  var islogdin = 0;

  @override
  void initState() {
    super.initState();
    _getInitData();
  }

  _getInitData() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var user = json.decode(localStorage.getString('user') ?? '{}');

    if (user['id'] != null) {
      setState(() {
        islogdin = 1;
      });
    }

    var data = {
      'user_id': user['id'],
    };

    var res = await CallApi().postData(data, 'property/get-init-data-part-one');

    if (res.statusCode == 200) {
      var body = json.decode(res.body);

      if (body['success']) {
        final List<dynamic> leaseData = body['data']['leaseTypesList'];
        List<Map<String, dynamic>> leaseArray = [];
        for (var laData in leaseData) {
          leaseArray.add({
            'id': laData['id'],
            'value': laData['value'],
          });
        }

        setState(() {
          _leaseTypesList = leaseArray;
          _initDataFetched = true;
          _propertTypesByNameList =
              body['data']['PropertyTypesByNameList'].cast<String>();
          _propertConditionsList =
              body['data']['propertyConditionByNameList'].cast<String>();
          _furnishedList = body['data']['furnishedByNameList'].cast<String>();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Adapted background color
      key: _scaffoldKey,
      appBar: buildHeader(context),
      // drawer: islogdin == 1 ? drawer(context) : null,
      body: CustomScrollView(slivers: <Widget>[
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Center(
                    child: Text(
                      "Search Properties",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  // child: TextFormField(
                  //   controller: _locationController,
                  //   decoration: InputDecoration(
                  //     labelText: 'Location',
                  //     hintText: 'Enter The Location',
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(5.0),
                  //       borderSide: BorderSide(
                  //         color: Theme.of(context)
                  //             .colorScheme
                  //             .onSurface, // Border color
                  //       ),
                  //     ),
                  //     enabledBorder: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(5.0),
                  //       borderSide: BorderSide(
                  //         color: Theme.of(context)
                  //             .colorScheme
                  //             .onSurface, // Enabled border color
                  //         width: 1.0,
                  //       ),
                  //     ),
                  //     focusedBorder: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(5.0),
                  //       borderSide: const BorderSide(
                  //         color: Colors.blue, // Focused border color
                  //         width: 1.5,
                  //       ),
                  //     ),
                  //     filled: true,
                  //     fillColor: Theme.of(context)
                  //         .scaffoldBackgroundColor, // Fill color
                  //     labelStyle: TextStyle(
                  //       color: Theme.of(context)
                  //           .textTheme
                  //           .bodyMedium!
                  //           .color, // Label color
                  //     ),
                  //     hintStyle: TextStyle(
                  //       color: Theme.of(context).hintColor, // Hint text color
                  //     ),
                  //   ),
                  //   validator: (value) {
                  //     if (value!.isEmpty) {
                  //       return 'Enter property Address';
                  //     }
                  //     return null;
                  //   },
                  //   onSaved: (value) {
                  //     _locationController.text = value!;
                  //   },
                  // ),
                  child: LocationFormField(
                    apiKey: 'AIzaSyCVvR6ZMW_H-c2O6Tjpcu1_ko8QkmkCfPQ',
                    hintText: "Enter your location",
                    onSaved: (value) {
                      if (value != null) {
                        print("Selected county: ${value['county']}");
                        print("Selected locality: ${value['locality']}");
                        print("Selected LAT: ${value['latitude']}");
                        print("Selected LON: ${value['longitude']}");

                        //     _locationController.text = value!;

                        _locationController.text =
                            value['locality'] ?? "Nairobi";
                        // _userRegion = value['county'] ?? "Nairobi";
                        // _lat = value['latitude'];
                        // _lon = value['longitude'];
                      }
                    },
                  ),
                ),
                FormField<List<String>>(
                  builder: (FormFieldState<List<String>> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DropdownSearch<String>.multiSelection(
                          items: _propertTypesByNameList,
                          popupProps: const PopupPropsMultiSelection.menu(
                            showSelectedItems: true,
                          ),
                          onChanged: (List<String> selectedItems) {
                            setState(() {
                              _selectedPropertyTypesArray = selectedItems;
                            });
                            state.didChange(selectedItems);
                          },
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Property Type",
                              hintText: "Select Property Type",
                              errorText:
                                  state.hasError ? state.errorText : null,
                            ),
                          ),
                        ),
                        // if (state.hasError)
                        //   Padding(
                        //     padding: const EdgeInsets.only(top: 5.0),
                        //     child: Text(
                        //       state.errorText!,
                        //       style: TextStyle(
                        //         color: Theme.of(context).colorScheme.error,
                        //         fontSize: 12,
                        //       ),
                        //     ),
                        //   ),
                      ],
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Select Property Type';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: DropdownSearch<String>.multiSelection(
                    items: _propertConditionsList,
                    popupProps: const PopupPropsMultiSelection.menu(
                      showSelectedItems: true,
                    ),
                    onChanged: (List<String> selectedItems) {
                      setState(() {
                        _selectedPropertyConditionArray = selectedItems;
                      });
                    },
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Property Condition",
                        hintText: "Select Property Condition",
                      ),
                    ),
                    // selectedItems: [],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: DropdownSearch<String>.multiSelection(
                    items: _furnishedList,
                    popupProps: const PopupPropsMultiSelection.menu(
                      showSelectedItems: true,
                    ),
                    onChanged: (List<String> selectedItems) {
                      setState(() {
                        _selectedFurnishedArray = selectedItems;
                      });
                    },
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Furnished",
                        hintText: "Select Furnish",
                      ),
                    ),
                    // selectedItems: [],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: DropdownSearch<Map<String, dynamic>>(
                    popupProps: PopupProps.menu(
                      showSelectedItems: true,
                      showSearchBox: false, // Disable search box if not needed
                      itemBuilder: (context, item, isSelected) {
                        return ListTile(
                          title: Text(item["value"]),
                        );
                      },
                    ),
                    items: _leaseTypesList,
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Lease Type",
                        hintText: "Select Lease Type",
                      ),
                    ),
                    selectedItem: _leaseTypesList.isNotEmpty
                        ? _leaseTypesList.firstWhere(
                            (item) => item["id"].toString() == _leaseType,
                            orElse: () => _leaseTypesList
                                .first, // Provide a fallback item
                          )
                        : null,
                    dropdownBuilder: (context, selectedItem) {
                      // Safeguard against null selectedItem
                      final displayText = selectedItem != null
                          ? selectedItem["value"]
                          : "Select Lease Type";
                      // Get the current theme's text color based on brightness
                      final textColor =
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black; // Adjust text color for dark mode
                      return Text(
                        displayText,
                        style: TextStyle(color: textColor),
                      );
                    },
                    onChanged: (Map<String, dynamic>? newItem) {
                      setState(() {
                        _leaseType = newItem?["id"].toString() ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please Select Lease Type';
                      }
                      return null;
                    },
                    compareFn: (item, selectedItem) =>
                        item["id"] == selectedItem["id"],
                  ),
                ),
                if (_leaseType == '2')
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Properties on Auction?',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('No'),
                                value: '0',
                                groupValue: _selectedAuction,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedAuction = value!;
                                  });
                                },
                                contentPadding:
                                    EdgeInsets.zero, // Remove padding
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Yes'),
                                value: '1',
                                groupValue: _selectedAuction,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedAuction = value!;
                                  });
                                },
                                contentPadding:
                                    EdgeInsets.zero, // Remove padding
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'Offplan Properties?',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('No'),
                                value: '0',
                                groupValue: _selectedOffPlan,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedOffPlan = value!;
                                  });
                                },
                                contentPadding:
                                    EdgeInsets.zero, // Remove padding
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Yes'),
                                value: '1',
                                groupValue: _selectedOffPlan,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedOffPlan = value!;
                                  });
                                },
                                contentPadding:
                                    EdgeInsets.zero, // Remove padding
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 10.0),
                  child: DropdownSearch<String>.multiSelection(
                    items: const [
                      "1",
                      "2",
                      "3",
                      "4",
                      "5",
                      "6",
                      "7",
                      "8",
                      "9",
                      "10",
                      "11",
                      "12"
                    ],
                    popupProps: const PopupPropsMultiSelection.menu(
                      showSelectedItems: true,
                    ),
                    onChanged: (List<String> selectedItems) {
                      setState(() {
                        _selectedBedroomsArray = selectedItems;
                      });
                    },
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Bedrooms",
                        hintText: "Select Bedroom",
                      ),
                    ),
                    // selectedItems: [],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10.0,
                  ),
                  child: Container(
                    decoration: ThemeHelper().inputBoxDecorationShaddow(),
                    child: TextFormField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface, // Dynamic text color
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context)
                            .scaffoldBackgroundColor, // Background color of the input
                        labelText: 'Min Price',
                        labelStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7), // Dynamic label color
                        ),
                        hintText: 'Enter Min Price',
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5), // Dynamic hint color
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5), // Border color
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5), // Enabled border color
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary, // Focused border color
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please Enter Min Price to continue';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _minPriceController.text = value!;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        PriceInputFormatter(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10.0,
                  ),
                  child: Container(
                    decoration: ThemeHelper().inputBoxDecorationShaddow(),
                    child: TextFormField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface, // Dynamic text color
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context)
                            .scaffoldBackgroundColor, // Background color of the input
                        labelText: 'Max Price',
                        labelStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7), // Dynamic label color
                        ),
                        hintText: 'Enter Max Price',
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5), // Dynamic hint color
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5), // Border color
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5), // Enabled border color
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary, // Focused border color
                          ),
                        ),
                      ),
                      onSaved: (value) {
                        _maxPriceController.text = value!;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        PriceInputFormatter(),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10.0,
                          left: 0,
                          right: 5,
                        ),
                        child: Container(
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                          child: TextFormField(
                            controller: _parkingSpacesController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface, // Dynamic text color
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                  .scaffoldBackgroundColor, // Background color of the input
                              labelText: 'Parking Spaces (Optional)',
                              labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7), // Dynamic label color
                              ),
                              hintText: 'Enter Parking Spaces',
                              hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5), // Dynamic hint color
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5), // Border color
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5), // Enabled border color
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary, // Focused border color
                                ),
                              ),
                            ),
                            onSaved: (value) {
                              _parkingSpacesController.text = value!;
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10.0,
                          left: 5,
                          right: 0,
                        ),
                        child: Container(
                          decoration: ThemeHelper().inputBoxDecorationShaddow(),
                          child: TextFormField(
                            controller: _sqmController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface, // Dynamic text color
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                  .scaffoldBackgroundColor, // Background color of the input
                              labelText: 'Square metres (sqm) (optional)',
                              labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7), // Dynamic label color
                              ),
                              hintText: 'Specify the Property Measurements.',
                              hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5), // Dynamic hint color
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5), // Border color
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5), // Enabled border color
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary, // Focused border color
                                ),
                              ),
                            ),
                            onSaved: (value) {
                              _sqmController.text = value!;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Container(
                    decoration: ThemeHelper().buttonBoxDecoration(context),
                    child: ElevatedButton(
                      style: ThemeHelper().buttonStyle(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
                        child: Text(
                          'Search Property'.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      onPressed: () => _searchProperty(context),
                    ),
                  ),
                )
              ],
            ),
          ),
        )),
      ]),
    );
  }

  _searchProperty(BuildContext context) async {
    //print(_selectedPropertyTypesArray);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    var data = {
      'propertyType': _selectedPropertyTypesArray,
      'location': _locationController.text,
      'propertyCondition': _selectedPropertyConditionArray,
      'furnished': _selectedFurnishedArray,
      'leaseType': _leaseType,
      'bedroom': _selectedBedroomsArray,
      'minPrice': _minPriceController.text.replaceAll(RegExp(r'[^\d]'), ''),
      'maxPrice': _maxPriceController.text.replaceAll(RegExp(r'[^\d]'), ''),
      'parking': _parkingSpacesController.text,
      'measurement': _sqmController.text,
      'auction': _selectedAuction,
      'offplan': _selectedOffPlan,
    };

    // print(data);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          searchParameters: data,
        ),
      ),
    );
  }
}
