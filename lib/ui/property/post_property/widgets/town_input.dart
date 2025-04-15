import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class TownInput extends StatelessWidget {
  final List<Map<String, dynamic>> townsList;
  final String userTown;
  final bool isLoadingSubRegions;
  final bool isDarkMode;
  final Function(Map<String, dynamic>?) onTownChanged;
  final VoidCallback fetchSubRegions;
  final bool initDataFetched;

  const TownInput({
    super.key,
    required this.townsList,
    required this.userTown,
    required this.isLoadingSubRegions,
    required this.isDarkMode,
    required this.onTownChanged,
    required this.fetchSubRegions,
    required this.initDataFetched,
  });

  @override
  Widget build(BuildContext context) {
    return initDataFetched
        ? Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: DropdownSearch<Map<String, dynamic>>(
            popupProps: PopupProps.modalBottomSheet(
              showSelectedItems: true,
              showSearchBox: true,
              modalBottomSheetProps: ModalBottomSheetProps(
                backgroundColor: isDarkMode
                    ? Colors.grey[850]
                    : Colors.white, // Popup background color
              ),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white70
                        : Colors.black54, // Search hint text color
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Search text color
                ),
              ),
              itemBuilder: (context, item, isSelected) {
                return ListTile(
                  title: Text(
                    item['value'],
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black, // Dropdown item text color
                    ),
                  ),
                  selected: isSelected,
                  tileColor: isDarkMode
                      ? Colors.grey[850]
                      : Colors.white, // Dropdown item background color
                );
              },
            ),
            items: townsList,
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: "Select Town",
                hintText: "Select Town",
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white70
                      : Colors.black54, // Label text color
                ),
                hintStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white54
                      : Colors.black38, // Hint text color
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.grey[850]
                    : Colors.white, // Dropdown background color
              ),
            ),
            selectedItem: userTown.isNotEmpty
                ? townsList.firstWhere(
                  (town) => town["id"].toString() == userTown,
              orElse: () => townsList.first,
            )
                : null,
            dropdownBuilder: (context, selectedItem) {
              final displayText = selectedItem != null
                  ? selectedItem["value"]
                  : "Select Town"; // Default text when no item is selected
              return Text(
                displayText,
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Main dropdown text color
                ),
              );
            },
            onChanged: (Map<String, dynamic>? selectedTown) {
              onTownChanged(selectedTown);
              fetchSubRegions();
            },
            validator: (value) {
              if (value == null) {
                return 'Please Select town';
              }
              return null;
            },
            compareFn: (item, selectedItem) =>
            item["id"] == selectedItem["id"],
          ),
        ),
        if (isLoadingSubRegions)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Loading Sub Region...Please Wait',
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white70 // Text color in dark mode
                    : Colors.grey, // Text color in light mode
                fontSize: 12,
              ),
            ),
          ),
      ],
    )
        : const SizedBox.shrink();
  }
}