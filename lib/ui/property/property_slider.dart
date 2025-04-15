import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_apartment_live/models/configuration.dart';

class PropertySlider extends StatefulWidget {
  final List<String> propertyImagesList;

  PropertySlider({required this.propertyImagesList});

  @override
  _PropertySliderState createState() => _PropertySliderState();
}

class _PropertySliderState extends State<PropertySlider> {
  int currentImageIndex = 0;
  late PageController _pageController;
  // String _webUrlFuture = '';

  var defaultImage = 'https://justhomes.co.ke/images/back6.jpg';
  bool hasGotApiLink = false;

  var _webUrlFuture = '';

  Future<void> _fetchWebUrl() async {
    try {
      final apiLink = await Configuration().getCountryApiLink();
      _webUrlFuture = apiLink['web'].toString();
      hasGotApiLink = true;
    } catch (e) {
      print('Error fetching country API link: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentImageIndex);
    // _webUrlFuture = Configuration().getCountryApiLink();
    _fetchWebUrl();
    // print('WEB LLLLLINK: ' + _webUrlFuture['api'].toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carousel with PageView inside a Stack
        Stack(
          children: [
            Container(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.propertyImagesList.length,
                itemBuilder: (BuildContext context, int index) {
                  final imageUrl =
                      // Configuration.WEB_URL + widget.propertyImagesList[index];
                      hasGotApiLink
                          ? _webUrlFuture + widget.propertyImagesList[index]
                          : defaultImage;
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // placeholder: (context, url) =>
                      //     Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
                onPageChanged: (index) {
                  setState(() {
                    currentImageIndex = index;
                  });
                },
              ),
            ),

            // Indicator (overlapping on top of the carousel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    widget.propertyImagesList.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        entry.key,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 9.0,
                      height: 9.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentImageIndex == entry.key
                              ? Colors.white
                              : Colors.grey.shade500),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
