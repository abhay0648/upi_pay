import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:upi_pay/upi_pay.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('UPI Pay'),
        ),
        body: const Screen(),
      ),
    );
  }
}

class Screen extends StatefulWidget {
  const Screen({Key? key}) : super(key: key);

  @override
  _ScreenState createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  String? _upiAddrError;

  final _upiAddressController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isUpiEditable = false;
  List<ApplicationMeta>? _apps;

  @override
  void initState() {
    super.initState();

    _amountController.text =
        (Random.secure().nextDouble() * 10).toStringAsFixed(2);

    Future.delayed(const Duration(milliseconds: 0), () async {
      _apps = await UpiPay.getInstalledUpiApplications(
          statusType: UpiApplicationDiscoveryAppStatusType.all);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiAddressController.dispose();
    super.dispose();
  }

  void _generateAmount() {
    setState(() {
      _amountController.text =
          (Random.secure().nextDouble() * 10).toStringAsFixed(2);
    });
  }

  Future<void> _onTap(ApplicationMeta app) async {
    final err = _validateUpiAddress(_upiAddressController.text);

    if (err != null) {
      setState(() {
        _upiAddrError = err;
      });
      return;
    }
    setState(() {
      _upiAddrError = null;
    });

    final transactionRef = Random.secure().nextInt(1 << 32).toString();
    print("Starting transaction with id $transactionRef");

    final UpiTransactionResponse upiTransactionResponse = await UpiPay.initiateTransaction(
      amount: _amountController.text,
      app: app.upiApplication,
      receiverName: 'Abhay',
      receiverUpiAddress: _upiAddressController.text,
      transactionRef: transactionRef,
      transactionNote: 'UPI Payment',
      // merchantCode: '7372',
    );

    print(upiTransactionResponse);

    // final snackBar = SnackBar(content: Text('Transfer Successfully'));
    SnackBar snackBar;
    if(upiTransactionResponse.status != null && upiTransactionResponse.status ==  UpiTransactionStatus.success){
      snackBar = const SnackBar(content: Text('Transfer Successfully'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }else{
      snackBar = const SnackBar(content: Text('Transfer failed'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: <Widget>[
          _vpa(),
          if (_upiAddrError != null) _vpaError(),
          _amount(),
          if (Platform.isIOS) _submitButton(),
          Platform.isAndroid ? _androidApps() : _iosApps(),
        ],
      ),
    );
  }

  Widget _vpa() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextFormField(
              controller: _upiAddressController,
              enabled: _isUpiEditable,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'address@upi',
                labelText: 'Receiving UPI Address',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(
                _isUpiEditable ? Icons.check : Icons.edit,
              ),
              onPressed: () {
                setState(() {
                  _isUpiEditable = !_isUpiEditable;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vpaError() {
    return Container(
      margin: const EdgeInsets.only(top: 4, left: 12),
      child: Text(
        _upiAddrError!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _amount() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _amountController,
              // readOnly: true,
              // enabled: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Amount',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.loop),
              onPressed: _generateAmount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Row(
        children: <Widget>[
          Expanded(
            child: MaterialButton(
              onPressed: () async => await _onTap(_apps![0]),
              child: Text('Initiate Transaction',
                  style: Theme.of(context)
                      .textTheme
                      .button!
                      .copyWith(color: Colors.white)),
              color: Theme.of(context).colorScheme.secondary,
              height: 48,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _androidApps() {
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Pay Using',
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          if (_apps != null) _appsGrid(_apps!.map((e) => e).toList()),
        ],
      ),
    );
  }

  Widget _iosApps() {
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Text(
              'One of these will be invoked automatically by your phone to '
                  'make a payment',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Detected Installed Apps',
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          if (_apps != null) _discoverableAppsGrid(),
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            child: Text(
              'Other Supported Apps (Cannot detect)',
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          if (_apps != null) _nonDiscoverableAppsGrid(),
        ],
      ),
    );
  }

  GridView _discoverableAppsGrid() {
    List<ApplicationMeta> metaList = [];
    for (var e in _apps!) {
      if (e.upiApplication.discoveryCustomScheme != null) {
        metaList.add(e);
      }
    }
    return _appsGrid(metaList);
  }

  GridView _nonDiscoverableAppsGrid() {
    List<ApplicationMeta> metaList = [];
    for (var e in _apps!) {
      if (e.upiApplication.discoveryCustomScheme == null) {
        metaList.add(e);
      }
    }
    return _appsGrid(metaList);
  }

  GridView _appsGrid(List<ApplicationMeta> apps) {
    apps.sort((a, b) => a.upiApplication
        .getAppName()
        .toLowerCase()
        .compareTo(b.upiApplication.getAppName().toLowerCase()));
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      // childAspectRatio: 1.6,
      physics: const NeverScrollableScrollPhysics(),
      children: apps
          .map(
            (it) => Material(
          key: ObjectKey(it.upiApplication),
          // color: Colors.grey[200],
          child: InkWell(
            onTap: Platform.isAndroid ? () async => await _onTap(it) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                it.iconImage(48),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  alignment: Alignment.center,
                  child: Text(
                    it.upiApplication.getAppName(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}

String? _validateUpiAddress(String value) {
  if (value.isEmpty) {
    return 'UPI VPA is required.';
  }
  if (value.split('@').length != 2) {
    return 'Invalid UPI VPA';
  }
  return null;
}
