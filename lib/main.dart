import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter/material.dart';
import 'package:nomnom/checkout.dart';
import 'package:nomnom/orders.dart';
import 'package:nomnom/transactions.dart';
import 'items.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }

}

class _MyAppState extends State<MyApp> {
  var loggedIn = false;
  var firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _buildLandingPage(),
    );
  }

  _buildLandingPage() {
    return StreamBuilder<FirebaseUser>(
      stream: FirebaseAuth.instance.onAuthStateChanged,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return MaterialApp(
              initialRoute: '/checkout',
              routes: {
                '/checkout': (content) => CheckoutPage(),
                '/orders': (content) => OrdersPage(),
                '/transactions': (context) => TransactionsPage(),
                '/items': (content) => FoodItemsPage(),
              }
          );
        } else {
          return _buildSocialLogin();
        }
      },
    );
  }

  _buildSocialLogin() {
    return Scaffold(
      body: Container(
          color: Color.fromRGBO(0, 207, 179, 1),
          child: Center(
            child: loggedIn
                ? Text("Logged In! :)",
                style: TextStyle(color: Colors.white, fontSize: 40))
                : Stack(
              children: <Widget>[
                Container(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // wrap height
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // stretch across width of screen
                      children: <Widget>[
                        _buildFacebookLoginButton()
                      ],
                    ),
                  ),
                )
              ],
            ),
          )),
    );
  }

  Container _buildFacebookLoginButton() {
    return Container(
      margin: EdgeInsets.only(left: 16, top: 0, right: 16, bottom: 0),
      child: ButtonTheme(
        height: 48,
        child: RaisedButton(
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onPressed: () {
              initiateSignIn();
            },
            color: Color.fromRGBO(27, 76, 213, 1),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textColor: Colors.white,
            child: Text(
              "Connect with Facebook",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            )),
      ),
    );
  }

  void initiateSignIn() {
    _handleSignIn();
  }

  Future<int> _handleSignIn() async {
    FacebookLoginResult facebookLoginResult = await _handleFBSignIn();
    final accessToken = facebookLoginResult.accessToken.token;
    if (facebookLoginResult.status == FacebookLoginStatus.loggedIn) {
      final facebookAuthCred =
      FacebookAuthProvider.getCredential(accessToken: accessToken);
      final user = await firebaseAuth.signInWithCredential(facebookAuthCred);
      print("User : " + user.user.displayName);
      return 1;
    } else {
      return 0;
    }
  }

  Future<FacebookLoginResult> _handleFBSignIn() async {
    FacebookLogin facebookLogin = FacebookLogin();
    FacebookLoginResult facebookLoginResult =
    await facebookLogin.logInWithReadPermissions(['email']);
    switch (facebookLoginResult.status) {
      case FacebookLoginStatus.cancelledByUser:
        print("Cancelled");
        break;
      case FacebookLoginStatus.error:
        print("error");
        break;
      case FacebookLoginStatus.loggedIn:
        print("Logged In");
        break;
    }
    return facebookLoginResult;
  }
}
