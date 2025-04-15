import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class SubRegionInput extends StatelessWidget {
  final bool isSubRegionEnabled;
  final List<Map<String, dynamic>> subRegionsList;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final FormFieldValidator<Map<String, dynamic>?>? validator;
  final String selectedSubRegion;

  const SubRegionInput({
    super.key,
    required this.isSubRegionEnabled,
    required this.subRegionsList,
    required this.onChanged,
    required this.validator,
    required this.selectedSubRegion,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return isSubRegionEnabled
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  items: subRegionsList,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Select Sub-Region",
                      hintText: "Select Sub-Region",
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
                  selectedItem: subRegionsList.isNotEmpty
                      ? subRegionsList.firstWhere(
                          (subRegion) =>
                              subRegion["id"].toString() == selectedSubRegion,
                          orElse: () => subRegionsList.first,
                        )
                      : null,
                  dropdownBuilder: (context, selectedItem) {
                    final displayText = selectedItem != null
                        ? selectedItem["value"]
                        : "Select Sub-Region"; // Default text when no item is selected
                    return Text(
                      displayText,
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white
                            : Colors.black, // Main dropdown text color
                      ),
                    );
                  },
                  onChanged: onChanged,
                  validator: validator,
                  compareFn: (item, selectedItem) =>
                      item["id"] == selectedItem["id"],
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }
}
