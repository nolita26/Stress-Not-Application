import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';
import 'package:stress_detector/DashboardPage.dart';
import 'package:stress_detector/Essentials/FadeAnimation.dart';
import 'package:stress_detector/Essentials/Loading.dart';
import 'package:stress_detector/Essentials/ThemeColor.dart';
import 'package:stress_detector/AdditionalInfo.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.onAuthStateChanged,
        builder: (ctx, userSnapshot) {
          if (userSnapshot.hasData) {
            return DashboardPage();
          } else if (userSnapshot.hasError) {
            return CircularProgressIndicator();
          }
          return LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String uid;
  LoginScreen({Key key, this.uid}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;
  String title = "";

  @override
  void initState() {
    super.initState();
  }

  FirebaseAuth _auth = FirebaseAuth.instance;

  final TwitterLogin twitterLogin = TwitterLogin(
      consumerKey: 'xxxxxxxxxxxxxxxxxxxxxxxx',
      consumerSecret: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
  );

  void _signInWithTwitter(String token, String secret) async {
    final AuthCredential credential = TwitterAuthProvider.getCredential(
        authToken: token,
        authTokenSecret: secret
    );
    await _auth.signInWithCredential(credential);
  }

  void login() async {
    final TwitterLoginResult result = await twitterLogin.authorize();
    String newMessage;
    if (result.status == TwitterLoginStatus.loggedIn) {
      setState(() => loading = true);
      _signInWithTwitter(result.session.token, result.session.secret);
      print(result.session.username);
      print(result.session.userId);

      try {
        var response = await http.post(
            Uri.encodeFull("http://10.0.2.2:5000/tweets"),
            headers: {"Content-Type": "application/json"},
            body: json.encode({
              'username': result.session.username.toString(),
              'user_id': result.session.userId.toString(),
            })
        );
        var data = json.decode(response.body);
        print(data);
      } catch(error) {
        print(error);
      }


      newMessage = "Logged in! username: ${result.session.username}";

      print('Logged in successfully!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    } else if (result.status == TwitterLoginStatus.cancelledByUser) {
      newMessage = "Login cancelled by user.";
    } else {
      newMessage = "Login error: ${result.errorMessage}";
    }
    setState(() {
      title = newMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return loading ? Loading() : Scaffold(
      body: Center(
        child: Container(
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Positioned(
                      child: Image.asset('assets/images.jpg',
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        fit:BoxFit.fill,),
                    ),
                    Positioned(
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: 190.0,),
                          FadeAnimation(0.5,
                            Image.asset('assets/applogo.png', width: 120.0, height: 120.0,),
                          ),
                          SizedBox(height: 30.0,),
                          FadeAnimation(0.7,
                            Text('Welcome to Stress Not!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 27.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          SizedBox(height: 20.0,),
                          FadeAnimation(0.9,
                              Container(
                                padding: EdgeInsets.only(left: 30, right: 30),
                                child: Text('Real time Twitter monitoring tool for mental health analysis and evaluation.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                          ),
                          SizedBox(height: 30.0,),
                          FadeAnimation(1.1, InkWell(
                            onTap: () {
                              login();
                            },
                            borderRadius: BorderRadius.circular(30),
                            splashColor: kThemeColor,
                            child: Container(
                              height: 50,
                              width: 300,
                              padding: EdgeInsets.only(left: 50, right: 50, top: 10, bottom: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.black,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Image.asset(
                                    'assets/twitter.png',
                                    width: 25,
                                    height: 25,
                                  ),
                                  SizedBox(width: 20,),
                                  Text(
                                    'Sign In with Twitter',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                          SizedBox(height: 20),
                          Text(
                            title == null ? "" : title,
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),

              ],
            ),
        ),
      )
    );
  }
}
