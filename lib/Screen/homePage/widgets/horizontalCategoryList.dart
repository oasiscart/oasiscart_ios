import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Screen/Language/languageSettings.dart';
import 'package:eshop_multivendor/Screen/ProductList&SectionView/ProductList.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../Helper/Constant.dart';
import '../../../Provider/homePageProvider.dart';
import '../../../Provider/CategoryProvider.dart';
import '../../../widgets/desing.dart';
import '../../SubCategory/SubCategory.dart';

class HorizontalCategoryList extends StatelessWidget {
  const HorizontalCategoryList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HomePageProvider>(
      builder: (context, categoryData, child) {
        return categoryData.catLoading
            ? SizedBox(
          width: double.infinity,
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.simmerBase,
            highlightColor: Theme.of(context).colorScheme.simmerHigh,
            child: catLoading(context),
          ),
        )
            : categoryData.catList.isEmpty
            ? Center(
          child: Text(
            getTranslated(context, 'CAT_IS_NOT_AVAILABLE_LBL'),
          ),
        )
            : Container(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.only(bottom: 0.0),
          height: 75, // Adjusted height for better fit
          color: Colors.white,
          child: ListView.builder(
            itemCount: categoryData.catList.length < 10
                ? categoryData.catList.length
                : 10,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const SizedBox();
              } else {
                return Padding(
                  padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 10), // Adjusted padding

                  child: GestureDetector(
                    onTap: () async {
                      if (categoryData.catList[index].subList == null ||
                          categoryData.catList[index].subList!.isEmpty) {
                        await Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => ProductList(
                              name: categoryData.catList[index].name,
                              id: categoryData.catList[index].id,
                              tag: false,
                              fromSeller: false,

                            ),
                          ),
                        );
                      } else {
                        await

                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => ProductList(
                                name: context
                                    .read<HomePageProvider>()
                                    .catList[index].name,
                                id: context
                                    .read<HomePageProvider>()
                                    .catList[index]
                                    .id,
                                tag: false,
                                fromSeller: false,
                               
                            ),
                          ),
                        );
                        // context
                            // .read<CategoryProvider>()
                        //     .setSubList(
                        //     context.read<HomePageProvider>().catList[index].subList
                        // );
                        // Navigator.push(
                        //   context,
                        //   CupertinoPageRoute(
                        //     builder: (context) => ProductList(
                        //         name: context
                        //             .read<HomePageProvider>()
                        //             .catList[index].name,
                        //         id: context
                        //             .read<HomePageProvider>()
                        //             .catList[index]
                        //             .id,
                        //         tag: false,
                        //         fromSeller: false,
                        //         selectedSubcategory: index
                        //     ),
                        //   ),
                        // );


                        // Navigator.push(
                        //   context,
                        //   CupertinoPageRoute(
                        //     builder: (context) => ProductList(
                        //         name: context
                        //             .read<HomePageProvider>()
                        //             .catList[index].name,
                        //         id: context
                        //             .read<HomePageProvider>()
                        //             .catList[index]
                        //             .id,
                        //         tag: false,
                        //         fromSeller: false,
                        //         selectedSubcategory: index
                        //     ),
                        //   ),
                        // );





                        // Navigator.push(
                        //   context,
                        //   CupertinoPageRoute(
                        //     builder: (context) => ProductList(
                        //       name:categoryData.catList[index].name,
                        //       id: categoryData.catList[index].id,
                        //       selectedSubcategory: index,
                        //       tag: false,
                        //       fromSeller: false,
                        //     ),
                        //   ),
                        // );
                      }
                    },

                    child: Container(
                      padding: EdgeInsets.only(bottom: 0.0),
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ClipRRect(
                              child: Container(
                                padding: EdgeInsets.only(bottom: 3.0),
                                color: Colors.white,
                                child: DesignConfiguration.getCacheNotworkImage(
                                  boxFit: BoxFit.cover,
                                  context: context,
                                  heightvalue: 50.0,
                                  widthvalue: 50.0,
                                  placeHolderSize: 50,
                                  imageurlString: categoryData.catList[index].image!,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: SizedBox(
                                width: 72,
                                child: Text(
                                  categoryData.catList[index].name!,
                                  maxLines: 5,
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontFamily: 'ubuntu',
                                    color: Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: textFontSize10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
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
            },
          ),
        );
      },
    );
  }

  static Widget catLoading(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(10, (_) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.white,
                    shape: BoxShape.circle,
                  ),
                  width: 50.0,
                  height: 50.0, // Adjusted the height to match the image size
                );
              }),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          width: double.infinity,
          height: 18.0,
          color: Theme.of(context).colorScheme.white,
        ),
      ],
    );
  }
}
