import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:eshop_multivendor/Model/message.dart';
import 'package:eshop_multivendor/Provider/SettingProvider.dart';
import 'package:eshop_multivendor/Provider/homePageProvider.dart';
import 'package:eshop_multivendor/Screen/Product%20Detail/productDetail.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/Constant.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:eshop_multivendor/Provider/Theme.dart';
import 'package:eshop_multivendor/Screen/Profile/MyProfile.dart';
import 'package:eshop_multivendor/Screen/ExploreSection/explore.dart';
import 'package:eshop_multivendor/Screen/PushNotification/PushNotificationService.dart';
import 'package:eshop_multivendor/cubits/personalConverstationsCubit.dart';
import 'package:eshop_multivendor/repository/NotificationRepository.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../Helper/String.dart';
import '../../Provider/UserProvider.dart';
import '../../widgets/security.dart';
import '../../widgets/systemChromeSettings.dart';
import '../SQLiteData/SqliteData.dart';
import '../../Helper/routes.dart';
import '../../widgets/desing.dart';
import '../Language/languageSettings.dart';
import '../../widgets/networkAvailablity.dart';
import '../../widgets/snackbar.dart';
import '../AllCategory/All_Category.dart';
import '../Cart/Cart.dart';
import '../Cart/Widget/clearTotalCart.dart';
import '../Notification/NotificationLIst.dart';
import '../homePage/homepageNew.dart';
import 'package:geolocator/geolocator.dart';
import '../AddAddress/Add_Address.dart';
import 'package:eshop_multivendor/Provider/addressProvider.dart';
import 'package:geocoding/geocoding.dart';

class Dashboard extends StatefulWidget {
  static GlobalKey<DashboardPageState> dashboardScreenKey =
  GlobalKey<DashboardPageState>();
  const Dashboard({Key? key}) : super(key: key);

  @override
  DashboardPageState createState() => DashboardPageState();
}

var db = DatabaseHelper();

class DashboardPageState extends State<Dashboard>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  bool onlyOneTimePress = true;
  bool _isLocationUpdated = false;
  bool _iconVisible = true;
  String _location = '';
  TextEditingController? nameC,
      mobileC,
      addressC,
      landmarkC,
      stateC,
      countryC,
      altMobC,
      cityC,
      areaC,
      zip;

  // Function to get location and update the address fields
  Future<void> _getLocationAndUpdateAddress(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location permissions are permanently denied")),
          );
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (onlyOneTimePress) {
        setState(() {
          onlyOneTimePress = false;
        });

        // Get placemark info
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '${place.name}, ${place.subLocality}, ${place.locality}';

          // Update TextEditingControllers and other state for UI
          setState(() {
            _iconVisible = false;
            _location = address;
          });

          // If using Provider to update the address elsewhere in the app
          var addressProvider = context.read<AddressProvider>();
          addressProvider.state = place.administrativeArea ?? '';
          addressProvider.country = place.country ?? '';
          addressProvider.city = place.locality ?? '';
          addressProvider.zipcode = place.postalCode ?? '';
        }

        // Reset the button state after updating address
        setState(() {
          onlyOneTimePress = true;
        });
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location")),
      );
    }

  }
  void _resetToIcon() {
    setState(() {
      _iconVisible = true; // Show the icon again
      _location = ''; // Clear the location text
    });
  }


  int selBottom = 0;
  late TabController _tabController;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  late StreamSubscription streamSubscription;

  late AnimationController navigationContainerAnimationController =
  AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  changeTabPosition(int index) {
    Future.delayed(Duration.zero, () {
      _tabController.animateTo(index);
    });
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      SystemChromeSettings.setSystemChromes(
          isDarkTheme: Provider.of<ThemeNotifier>(context, listen: false)
              .getThemeMode() ==
              ThemeMode.dark);
    });
    WidgetsBinding.instance.addObserver(this);
    NotificationRepository.clearChatNotifications();
    // initDynamicLinks();
    initAppLinks();
    _tabController = TabController(
      length: 4,
      vsync: this,
    );

    _tabController.addListener(
          () {
        Future.delayed(const Duration(microseconds: 10)).then(
              (value) {
            setState(
                  () {
                selBottom = _tabController.index;
              },
            );
          },
        );
        //show bottombar on tab change by user interaction
        if (_tabController.index != 0 ||
            _tabController.index != 2 ||
            _tabController.index != 3 &&
                !context.read<HomePageProvider>().getBars) {
          context.read<HomePageProvider>().animationController.reverse();
          context.read<HomePageProvider>().showAppAndBottomBars(true);
        }
        if (_tabController.index == 3) {
          cartTotalClear(context);
        }
      },
    );

    Future.delayed(
      Duration.zero,
          () async {
        if ((context.read<SettingProvider>().userId ?? '').isNotEmpty) {
          if (kDebugMode) {
            print('Init the push notificaiton service');
          }
          PushNotificationService(context: context).initialise();
        }
        SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
        context
            .read<UserProvider>()
            .setUserId(await settingsProvider.getPrefrence(ID) ?? '');

        context.read<HomePageProvider>()
          ..setAnimationController(navigationContainerAnimationController)
          ..setBottomBarOffsetToAnimateController(
              navigationContainerAnimationController)
          ..setAppBarOffsetToAnimateController(
              navigationContainerAnimationController);
      },
    );
    super.initState();
  }

  Future<void> initAppLinks() async {
    _appLinks = AppLinks();
    // Listen for incoming deep links
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        handleDeepLink(uri);
      }
    });
  }

  Future<void> handleDeepLink(Uri uri) async {
    if (uri.path.contains('/products/details/')) {
      String slug = uri.pathSegments.last;
      if (slug.isNotEmpty) {
        final product = await getProductDetailsFromSlug(slug);
        if (product != null) {
          Routes.goToProductDetailsPage(context, product: product);
        }
      }
    } else {
      if (kDebugMode) {
        print('Received deep link: $uri');
      }
    }
  }

  Future<Product?> getProductDetailsFromSlug(String slug) async {
    try {
      final getData = await apiBaseHelper.postAPICall(getProductApi, {
        'slug': slug,
        USER_ID: context.read<UserProvider>().userId,
      });
      bool error = getData['error'];
      if (!error) {
        var data = getData['data'];

        List<Product> tempList =
        (data as List).map((data) => Product.fromJson(data)).toList();

        if (tempList.isEmpty) {
          setSnackbar(
              getTranslated(context, 'NO_PRODUCTS_WITH_YOUR_LINK_FOUND'),
              context);
          return null;
        }
        return tempList[0] as Product?;
      } else {
        throw Exception();
      }
    } catch (_) {}
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      NotificationRepository.getChatNotifications().then((messages) {
        for (var encodedMessage in messages) {
          final message =
          Message.fromJson(Map.from(jsonDecode(encodedMessage) ?? {}));

          if (converstationScreenStateKey.currentState?.mounted ?? false) {
            final state = converstationScreenStateKey.currentState!;
            if (state.widget.isGroup) {
              //To manage the group
            } else {
              //
              if (state.widget.personalChatHistory?.getOtherUserId() !=
                  message.fromId) {
                context
                    .read<PersonalConverstationsCubit>()
                    .updateUnreadMessageCounter(userId: message.fromId!);
              } else {
                state.addMessage(message: message);
              }
            }
          } else {
            if (message.type == 'person') {
              context
                  .read<PersonalConverstationsCubit>()
                  .updateUnreadMessageCounter(
                userId: message.fromId!,
              );
            } else {
              // Update group message
            }
          }
        }
        //Clear the message notifications
        NotificationRepository.clearChatNotifications();
      });
    }
  }

  setSnackBarFunctionForCartMessage() {
    Future.delayed(const Duration(seconds: 5)).then(
          (value) {
        if (homePageSingleSellerMessage) {
          homePageSingleSellerMessage = false;
          showOverlay(
              getTranslated(context,
                  'One of the product is out of stock, We are not able To Add In Cart'),
              context);
        }
      },
    );
  }

  // Future<void> initDynamicLinks() async {
  //   FirebaseDynamicLinks.instance.onLink.listen((event) async {
  //     final Uri deepLink = event.link;
  //     if (deepLink.queryParameters.isNotEmpty) {
  //       deeplinkGetData(deepLink.queryParameters);
  //     }
  //   }, onError: (e) {});
  //   final PendingDynamicLinkData? initialLink =
  //       await FirebaseDynamicLinks.instance.getInitialLink();
  //   try {
  //     if (initialLink != null) {
  //       if (initialLink.link.queryParameters.isNotEmpty) {
  //         deeplinkGetData(initialLink.link.queryParameters);
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('deeplink=other>No deepLink found');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selBottom == 0,
      onPopInvoked: (didPop) {
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        extendBody: true,
        backgroundColor: Theme.of(context).colorScheme.lightWhite,
        appBar: selBottom == 0
            ? _getAppBar()
            : AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Theme.of(context).colorScheme.white),
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.white,
        )
        //  : const PreferredSize(
        //   preferredSize: Size.zero,
        //   child: SizedBox(),
        // )
        ,
        body: SafeArea(
            child: Consumer<UserProvider>(builder: (context, data, child) {
              return TabBarView(
                controller: _tabController,
                children: const [
                  HomePage(),
                  AllCategory(),
                  Explore(),
                  Cart(
                    fromBottom: true,
                  ),
                   // MyProfile(),
                ],
              );
            })),
        // floatingActionButton: FloatingActionButton(
        //   backgroundColor: Colors.pink,
        //   child: const Icon(Icons.add),
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       CupertinoPageRoute(
        //         builder: (context) => const AnimationScreen(),
        //       ),
        //     );
        //   },
        // ),
        bottomNavigationBar: _getBottomBar(),
      ),
    );
  }

  _getAppBar() {
    /* String? title;
    if (_selBottom == 1) {
      title = getTranslated(context, 'CATEGORY');
    } else if (_selBottom == 2) {
      title = getTranslated(context, 'EXPLORE');
    } else if (_selBottom == 3) {
      title = getTranslated(context, 'MYBAG');
    } else if (_selBottom == 4) {
      title = getTranslated(context, 'PROFILE');
    } */
    final appBar = AppBar(

      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Theme.of(context).colorScheme.white),
      elevation: 0,
      toolbarHeight: 48,
      shape: const RoundedRectangleBorder(
        // borderRadius: BorderRadius.vertical(
        //   bottom:
        //   Radius.circular(20), // Radius for bottom left and right corners
        // ),
      ),
      centerTitle: false,
      automaticallyImplyLeading: false,
        // backgroundColor:Color(0xFF97E7F5),
      backgroundColor:Colors.white,
      title: /* _selBottom == 0
          ? */
      Container(

        margin: EdgeInsets.only(top: 0.0),
        padding: EdgeInsets.only(left: 0.0),  // Padding on the left set to 0
        child: SvgPicture.asset(
          DesignConfiguration.setSvgPath('titleicon'),
          height: 23,
        ),
      ),

      actions: <Widget>[
      // Adjust these values as needed
           Container(
            alignment: Alignment.bottomRight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_location,
                    color: Colors.black,
                    size: 19.0,
                  ),
                  onPressed: () {
                    _getLocationAndUpdateAddress(context);
                  },
                ),
                GestureDetector(
                  onTap: _resetToIcon,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 19.0, left: 0.0),
                        child: Text(
                          _location.isNotEmpty ? _location : '',
                          style: TextStyle(fontSize: 11.0, color: Colors.black,fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),




        Padding(
          padding: const EdgeInsets.only(top: 3.0,left: 1.0), // Adjust as needed
          child: IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black,
            ),
            onPressed: () {
              _showPopupMenu(context);
            },
          ),
        ),
      ],





      /* : Text(
              title!,
              style: const TextStyle(
                color: colors.primary,
                fontFamily: 'ubuntu',
                fontWeight: FontWeight.normal,
              ),
            ), */
      // actions: <Widget>[
      //   appbarActionIcon(() {
      //     Routes.navigateToFavoriteScreen(context);
      //   }, 'fav_black'),
      //   appbarActionIcon(() {
      //     context.read<UserProvider>().userId != ''
      //         ? Navigator.push(
      //       context,
      //       CupertinoPageRoute(
      //         builder: (context) => const NotificationList(),
      //       ),
      //     ).then(
      //           (value) {
      //         if (value != null && value) {
      //           _tabController.animateTo(1);
      //         }
      //       },
      //     )
      //         : Routes.navigateToLoginScreen(
      //       context,
      //       classType: const Dashboard(),
      //       isPop: true,
      //     );
      //   }, 'notification_black'),
      // ],
    );

    return PreferredSize(
      preferredSize: appBar.preferredSize,
      child: SlideTransition(
        position: context.watch<HomePageProvider>().animationAppBarBarOffset,
        child: SizedBox(
          height: context.watch<HomePageProvider>().getBars ? 100 : 0,
          child: appBar,
        ),
      ),
    );
  }

  appbarActionIcon(Function callback, String iconname) {
    return Align(
      child: GestureDetector(
        onTap: () {
          callback();
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.gray),
            borderRadius: BorderRadius.circular(circularBorderRadius10),
            color: Theme.of(context).colorScheme.blue,
          ),
          margin: const EdgeInsetsDirectional.only(end: 10),
          width: Platform.isAndroid ? 37 : 30,
          height: Platform.isAndroid ? 37 : 30,
          padding: const EdgeInsets.all(7),
          child: SvgPicture.asset(
            DesignConfiguration.setSvgPath(iconname),
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.black, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  getTabItem(String enabledImage, String disabledImage, int selectedIndex,
      String name) {
    return Wrap(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: SizedBox(
                height: 25,
                child: selBottom == selectedIndex
                    ? Lottie.asset(
                  DesignConfiguration.setLottiePath(enabledImage),
                  repeat: false,
                  height: 25,
                )
                    : SvgPicture.asset(
                  DesignConfiguration.setSvgPath(disabledImage),
                  colorFilter: const ColorFilter.mode(
                      Colors.grey, BlendMode.srcIn),
                  height: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                getTranslated(context, name),
                style: TextStyle(
                  color: selBottom == selectedIndex
                      ? Theme.of(context).colorScheme.fontColor
                      : Theme.of(context).colorScheme.lightBlack,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  fontSize: textFontSize11,
                  fontFamily: 'ubuntu',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _getBottomBar() {
    Brightness currentBrightness = MediaQuery.of(context).platformBrightness;

    return AnimatedContainer(
      duration: Duration(
        milliseconds: context.watch<HomePageProvider>().getBars ? 500 : 500,
      ),
      padding: EdgeInsets.only(
          bottom:
          Platform.isIOS ? MediaQuery.of(context).viewPadding.bottom : 0),
      height: context.watch<HomePageProvider>().getBars
          ? kBottomNavigationBarHeight +
          (Platform.isIOS
              ? MediaQuery.of(context).viewPadding.bottom > 8
              ? 8
              : MediaQuery.of(context).viewPadding.bottom
              : 0)
          : 0,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.black26,
            blurRadius: selBottom == 2 ? 0 : 4,
          )
        ],
      ),
      child: Selector<ThemeNotifier, ThemeMode>(
        selector: (_, themeProvider) => themeProvider.getThemeMode(),
        builder: (context, data, child) {
          return TabBar(
            isScrollable: false,
            controller: _tabController, indicatorPadding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            tabs: [
              Tab(
                child: getTabItem(
                  (data == ThemeMode.system &&
                      currentBrightness == Brightness.dark) ||
                      data == ThemeMode.dark
                      ? 'dark_active_home'
                      : 'light_active_home',
                  'home',
                  0,
                  'HOME_LBL',
                ),
              ),
              Tab(
                child: getTabItem(
                    (data == ThemeMode.system &&
                        currentBrightness == Brightness.dark) ||
                        data == ThemeMode.dark
                        ? 'dark_active_category'
                        : 'light_active_category',
                    'category',
                    1,
                    'CATEGORY'),
              ),
              Tab(
                child: getTabItem(
                  (data == ThemeMode.system &&
                      currentBrightness == Brightness.dark) ||
                      data == ThemeMode.dark
                      ? 'dark_active_explorer'
                      : 'light_active_explorer',
                  'brands',
                  2,
                  'EXPLORE',
                ),
              ),
              Tab(
                child: Selector<UserProvider, String>(
                  builder: (context, userData, child) {
                    return Stack(
                      children: [
                        getTabItem(
                          (data == ThemeMode.system &&
                              currentBrightness == Brightness.dark) ||
                              data == ThemeMode.dark
                              ? 'dark_active_cart'
                              : 'light_active_cart',
                          'cart',
                          3,
                          'CART',
                        ),
                        (userData.isNotEmpty && userData != '0')
                            ? Positioned.directional(
                          end: 0,
                          textDirection: Directionality.of(context),
                          top: 0,
                          child: Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.primary),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Text(
                                    userData,
                                    style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .white),
                                  ),
                                ),
                              )),
                        )
                            : const SizedBox.shrink()
                      ],
                    );
                  },
                  selector: (_, homeProvider) => homeProvider.curCartCount,
                ),
              ),
              // Tab(
              //   child: getTabItem(
              //     (data == ThemeMode.system &&
              //         currentBrightness == Brightness.dark) ||
              //         data == ThemeMode.dark
              //         ? 'dark_active_profile'
              //         : 'light_active_profile',
              //     'profile',
              //     4,
              //     'PROFILE',
              //   ),
              // ),
            ],
            indicatorColor: Colors.transparent,
            labelColor: colors.primary,
            // isScrollable: false,
            labelStyle: const TextStyle(fontSize: textFontSize12),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }
}

void _showPopupMenu(BuildContext context) {
  showMenu<String>(
    context: context,
    position: const RelativeRect.fromLTRB(100, 38, 0, 100), // Popup position
    items: [
      const PopupMenuItem<String>(
        value: 'profile',
          child: Row(
            children: [
              SizedBox(
                width: 24,  // Set desired width
                height: 24, // Set desired height
                child: Icon(Icons.person, size: 24, color: Colors.grey), // Set icon color to black
              ),


              // You can change this to any other icon
              SizedBox(width: 3), // Adds some space between the icon and text
              Text('Profile',style: TextStyle(fontWeight: FontWeight.w100, color: Color(0xff222222)),),
            ],
          ),
      ),
    ],
    elevation: 6.0,
  ).then((value) {
    if (value == 'profile') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyProfile()),
      );
     }
   },
  );
}
