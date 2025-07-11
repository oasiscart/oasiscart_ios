import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Helper/Constant.dart';
import '../../../Helper/String.dart';
import '../../../Provider/CartProvider.dart';
import '../../Language/languageSettings.dart';
import '../../../Provider/paymentProvider.dart';
import '../../../Provider/UserProvider.dart';
import '../../../widgets/ButtonDesing.dart';
import '../../Payment/Widget/PaymentRadio.dart';

class SelectPayment extends StatefulWidget {
  final Function updateCheckout;
  const SelectPayment({Key? key, required this.updateCheckout}) : super(key: key);

  @override
  State<SelectPayment> createState() => _SelectPaymentState();
}

class _SelectPaymentState extends State<SelectPayment> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePaymentMethods();
    });
  }

  Future<void> _initializePaymentMethods() async {
    final paymentProvider = context.read<PaymentProvider>();

    try {
      // Initialize payment methods
      paymentProvider.payModel.clear();
      await paymentProvider.getdateTime(context, () {});

      // Initialize payment method flags with default values if null
      paymentProvider.cod = paymentProvider.cod ?? false;
      paymentProvider.stripe = paymentProvider.stripe ?? false;
      paymentProvider.paypal = paymentProvider.paypal ?? false;
      paymentProvider.razorpay = paymentProvider.razorpay ?? false;
      paymentProvider.paystack = paymentProvider.paystack ?? false;
      paymentProvider.flutterwave = paymentProvider.flutterwave ?? false;
      paymentProvider.paytm = paymentProvider.paytm ?? false;
      paymentProvider.bankTransfer = paymentProvider.bankTransfer ?? false;
      paymentProvider.midtrans = paymentProvider.midtrans ?? false;
      paymentProvider.myfatoorah = paymentProvider.myfatoorah ?? false;
      paymentProvider.instamojo = paymentProvider.instamojo ?? false;
      paymentProvider.phonepe = paymentProvider.phonepe ?? false;

      // Build payment method list only with enabled methods
      final List<String?> methods = [
        if (paymentProvider.cod) getTranslated(context, 'COD_LBL'),
        if (paymentProvider.stripe) getTranslated(context, 'STRIPE_LBL'),
        if (paymentProvider.paypal) getTranslated(context, 'PAYPAL_LBL'),
        if (paymentProvider.razorpay) getTranslated(context, 'RAZORPAY_LBL'),
        if (paymentProvider.paystack) getTranslated(context, 'PAYSTACK_LBL'),
        if (paymentProvider.flutterwave) getTranslated(context, 'FLUTTERWAVE_LBL'),
        if (paymentProvider.paytm) getTranslated(context, 'PAYTM_LBL'),
        if (paymentProvider.bankTransfer) getTranslated(context, 'BANKTRAN'),
        if (paymentProvider.midtrans) getTranslated(context, 'MidTrans'),
        if (paymentProvider.myfatoorah) getTranslated(context, 'My Fatoorah'),
        if (paymentProvider.instamojo) getTranslated(context, 'instamojo_lbl'),
        if (paymentProvider.phonepe) getTranslated(context, 'PHONEPE_LBL'),
      ];

      paymentProvider.paymentMethodList = methods.whereType<String>().toList();

      // Initialize payment models only if we have methods
      if (paymentProvider.paymentMethodList.isNotEmpty) {
        paymentProvider.payModel = paymentProvider.paymentMethodList.map((method) {
          return RadioModel(
            isSelected: false,
            name: method,
            img: '',
          );
        }).toList();
      }

      // setState(() {
      //   _isInitialized = true;
      // });
    } catch (e) {
      print("Error initializing payment methods: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (!_isInitialized) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    final cartProvider = context.read<CartProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final userProvider = context.read<UserProvider>();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.payment),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    getTranslated(context, 'SELECT_PAYMENT'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ubuntu',
                    ),
                  ),
                ),
              ],
            ),
            if (cartProvider.payMethod != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text(
                      cartProvider.payMethod!,
                      style: const TextStyle(
                        fontFamily: 'ubuntu',
                      ),
                    ),
                  ],
                ),
              ),
            // const Divider(),
            _buildWalletOption(userProvider, cartProvider),
            if (cartProvider.isPayLayShow!) ...[
              // const Divider(),
              // Padding(
              //   padding: const EdgeInsets.all(2.0),
              //   // child: Text(
              //   //   getTranslated(context, 'AVAILABLE_PAYMENT_OPTIONS'),
              //   //   style: TextStyle(
              //   //     color: Theme.of(context).colorScheme.fontColor,
              //   //     fontWeight: FontWeight.bold,
              //   //     fontSize: textFontSize16,
              //   //   ),
              //   // ),
              // ),
              if (paymentProvider.paymentMethodList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _buildPaymentOptions(paymentProvider, cartProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption(UserProvider userProvider, CartProvider cartProvider) {
    return Card(
      elevation: 0,
      child: userProvider.curBalance != '0' &&
          userProvider.curBalance.isNotEmpty &&
          userProvider.curBalance != ''
          ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CheckboxListTile(
          dense: true,
          contentPadding: const EdgeInsets.all(0),
          value: cartProvider.isUseWallet,
          onChanged: (bool? value) {
            setState(() {
              cartProvider.isUseWallet = value;
              if (value!) {
                if (cartProvider.totalPrice <= double.parse(userProvider.curBalance)) {
                  cartProvider.remWalBal = double.parse(userProvider.curBalance) - cartProvider.totalPrice;
                  cartProvider.usedBalance = cartProvider.totalPrice;
                  cartProvider.payMethod = 'Wallet';
                  cartProvider.isPayLayShow = false;
                } else {
                  cartProvider.remWalBal = 0;
                  cartProvider.usedBalance = double.parse(userProvider.curBalance);
                  cartProvider.isPayLayShow = true;
                }
                cartProvider.totalPrice -= cartProvider.usedBalance;
              } else {
                cartProvider.totalPrice += cartProvider.usedBalance;
                cartProvider.remWalBal = double.parse(userProvider.curBalance);
                cartProvider.payMethod = null;
                cartProvider.selectedMethod = null;
                cartProvider.usedBalance = 0;
                cartProvider.isPayLayShow = true;
              }
              widget.updateCheckout();
            });
          },
          title: Text(
            getTranslated(context, 'USE_WALLET'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
              fontSize: 17,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              cartProvider.isUseWallet!
                  ? '${getTranslated(context, 'REMAIN_BAL')}: ${cartProvider.remWalBal.toStringAsFixed(2)}'
                  : '${getTranslated(context, 'TOTAL_BAL')}: ${userProvider.curBalance}',
              style: TextStyle(
                fontSize: textFontSize15,
                color: Theme.of(context).colorScheme.black,
              ),
            ),
          ),
        ),
      )
          : const SizedBox(),
    );
  }

  Widget _buildPaymentOptions(PaymentProvider paymentProvider, CartProvider cartProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paymentProvider.paymentMethodList.length,
      itemBuilder: (context, index) {
        // Double-check index bounds
        if (index < 0 || index >= paymentProvider.paymentMethodList.length) {
          return const SizedBox();
        }

        final method = paymentProvider.paymentMethodList[index];
        if (method == null || method.isEmpty) {
          return const SizedBox();
        }

        return _buildPaymentOption(index, paymentProvider, cartProvider);
      },
    );
  }

  Widget _buildPaymentOption(int index, PaymentProvider paymentProvider, CartProvider cartProvider) {
    return InkWell(
      onTap: () {
        if (index >= 0 && index < paymentProvider.payModel.length) {
          setState(() {
            _handlePaymentMethodSelection(index, paymentProvider, cartProvider);
            widget.updateCheckout();
          });
        }
      },
      child: index < paymentProvider.payModel.length
          ? RadioItem(paymentProvider.payModel[index])
          : const SizedBox(),
    );
  }

  void _handlePaymentMethodSelection(
      int index, PaymentProvider paymentProvider, CartProvider cartProvider) {
    if (index < 0 || index >= paymentProvider.paymentMethodList.length) {
      return;
    }

    if (IS_SHIPROCKET_ON == '1') {
      cartProvider.isShippingDeliveryChargeApplied = false;
      if (cartProvider.isUseWallet == true) {
        cartProvider.totalPrice = cartProvider.totalPrice +
            (cartProvider.usedBalance - cartProvider.deliveryCharge);
        cartProvider.isUseWallet = false;
        cartProvider.usedBalance = 0;
      }

      if (index == 0 &&
          paymentProvider.cod &&
          cartProvider.codDeliverChargesOfShipRocket > 0) {
        cartProvider.deliveryCharge = cartProvider.codDeliverChargesOfShipRocket;
        if (cartProvider.isShippingDeliveryChargeApplied == false) {
          cartProvider.totalPrice =
              cartProvider.deliveryCharge + cartProvider.oriPrice;
          cartProvider.isShippingDeliveryChargeApplied = true;
        }
      } else if (cartProvider.prePaidDeliverChargesOfShipRocket > 0) {
        cartProvider.deliveryCharge = cartProvider.prePaidDeliverChargesOfShipRocket;
        if (cartProvider.isShippingDeliveryChargeApplied == false) {
          cartProvider.totalPrice =
              cartProvider.deliveryCharge + cartProvider.oriPrice;
          cartProvider.isShippingDeliveryChargeApplied = true;
        }
      } else {
        if (cartProvider.isPromoValid!) {
          cartProvider.totalPrice = (cartProvider.deliveryCharge +
              cartProvider.oriPrice) -
              cartProvider.promoAmt;
        } else {
          cartProvider.totalPrice = cartProvider.deliveryCharge + cartProvider.oriPrice;
        }
      }
    }

    cartProvider.selectedMethod = index;
    cartProvider.payMethod = paymentProvider.paymentMethodList[index];

    // Reset all selections
    for (var element in paymentProvider.payModel) {
      element.isSelected = false;
    }

    // Set current selection if index is valid
    if (index >= 0 && index < paymentProvider.payModel.length) {
      paymentProvider.payModel[index].isSelected = true;
    }
  }
}