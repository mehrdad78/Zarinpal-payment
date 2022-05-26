import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var result;
  var verified;
  var sub;
  String getpay;
  String _latestLink = 'Unknown';
  String _gotLink;

  payment() async {
    String url = "https://api.zarinpal.com/pg/v4/payment/request.json";
    var body = jsonEncode(
      {
        "merchant_id": "YOUR MERCHANT CODE", //*Must be String
        "amount": "YOUR AMOUNT", //* Must be Double
        "description": "YOUR DESCRIPTION", //*String
        "callback_url": "**://YOUR URL.***" //*String
      },
    );

    final response = await http.post(
      Uri.encodeFull(url),
      body: body,
      headers: {
        "content-type": "application/json",
      },
    );
    setState(() {});
    result = jsonDecode(response.body);
    getpay =
        "https://www.zarinpal.com/pg/StartPay/${result['data']["authority"]}";
    print(result);
    // null unknown
    print(' payment link : $_latestLink');
    await _launchURL(url: getpay);
  }

  verifyPayment() async {
    print(' verify link : $_latestLink');
    String url = "https://api.zarinpal.com/pg/v4/payment/verify.json";
    var body = jsonEncode({
      "merchant_id": "YOUR MERHCANT CODE",
      "amount": "YOUR AMOUNT",
      "authority": result['data']["authority"]
    });
    http.Response response = await http.post(
      Uri.encodeFull(url),
      headers: {
        "Content-Type": "application/json",
        "accept": "application/json"
      },
      body: body,
    );
    setState(() {});
    verified = jsonDecode(response.body);
    print(verified);
  }

  _launchURL({String url}) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  initPlatformStateForStringUniLinks() async {
    // Attach a listener to the links stream
    sub = getLinksStream().listen((String link) {
      if (!mounted) return;
      setState(() {
        _latestLink = link ?? 'Unknown';
        try {} on FormatException {}
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestLink = 'Failed to get latest link: $err.';
      });
    });

    // Attach a second listener to the stream
//Got Link
    getLinksStream().listen((String link) {
      _gotLink = link;
      print('got link: $_gotLink');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest link
    String initialLink;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
      print('initial link: $initialLink');
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _latestLink = initialLink;
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await initPlatformStateForStringUniLinks();
    if (_latestLink != null && _latestLink != 'Unknown') {
      print('Hello');
      print('new link : $_latestLink');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
            onPressed: () async {
              setState(() {});
              payment();
              if (_gotLink.substring(_gotLink.lastIndexOf('=') + 1) == 'OK') {
                await verifyPayment();
                if (verified['code'] == 100) {}
              } else
                print("Not Succesful");
            },
            child: Text("تست درگاه ")),
      ),
    );
  }
}
