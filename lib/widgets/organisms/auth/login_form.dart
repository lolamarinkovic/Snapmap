import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:snapmap/screens/profile_creation_screen.dart';
import 'package:snapmap/services/email_service.dart';
import 'package:snapmap/services/auth_service.dart';
import 'package:snapmap/utils/logger.dart';
import 'package:snapmap/widgets/themes/dark_green.dart';
import '../nav_controller.dart';
import '../../molecules/welcome_section.dart';
import '../../molecules/login_page_button_info.dart';
import '../../molecules/login_page_divider.dart';
import '../../atoms/textbutton_text.dart';

// login form first page of the application

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _accountRecovery = TextEditingController();
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  String email = '';
  String password = '';
  String username = '';
  String confirmPass = '';
  String errorText = '';
  bool pageFlag = false;
  bool errorExists = false;
  bool redeyeOn = false;

  final users = FirebaseFirestore.instance.collection("Users");

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // create stack of image / appropriate text depending on
                  // if user is on login form or signup form
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Opacity(
                          opacity: 0.6,
                          child: Image.asset(
                              'images/login_signup_form_picture.jpg')),
                      // change text depending on signup / login
                      pageFlag
                          ? const WelcomeSection(
                              message: 'Welcome to Snapmap!',
                              information:
                                  'Enter your information below to start snapping!')
                          : const WelcomeSection(
                              message: 'Welcome Back!',
                              information:
                                  'Login below to see what you missed!')
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: const InputDecoration(
                      errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red)),
                      errorStyle: TextStyle(color: Colors.red),
                      prefixIcon: Icon(Icons.account_circle),
                      labelText: "Username",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter a Username';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      username = value.toString();
                    },
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: pageFlag,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red)),
                        errorStyle: TextStyle(color: Colors.red),
                        prefixIcon: Icon(Icons.alternate_email),
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        // check to see if email for sign up is valid
                        if (value == null || value.isEmpty) {
                          return 'Please Enter an Email Address';
                        } else if (!emailValidator(value)) {
                          return 'Enter valid email';
                        } else {
                          return null;
                        }
                      },
                      onSaved: (value) {
                        email = value.toString();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    obscureText: !redeyeOn,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red)),
                      errorStyle: const TextStyle(color: Colors.red),
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          redeyeOn = !redeyeOn;
                          setState(() {});
                        },
                        icon: redeyeOn
                            ? const Icon(Icons.remove_red_eye_outlined)
                            : const Icon(Icons.remove_red_eye),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter a Password';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      password = value.toString();
                    },
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: pageFlag,
                    child: TextFormField(
                      obscureText: !redeyeOn,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red)),
                        errorStyle: TextStyle(color: Colors.red),
                        labelText: "Confirm Password",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Confirm Your Password';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        confirmPass = value.toString();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                      visible: errorExists,
                      child: Text(errorText,
                          style: const TextStyle(color: Colors.red))),
                  Visibility(
                    visible: !pageFlag,
                    child: InkWell(
                      child: const Text("Forgot Password?"),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Account Recovery"),
                                content: const Text(
                                    "Enter email to recover password:"),
                                actions: [
                                  TextField(
                                    decoration: const InputDecoration(
                                      label: Text('Email'),
                                      prefixIcon: Icon(Icons.email),
                                      border: OutlineInputBorder(),
                                    ),
                                    controller: _accountRecovery,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      return Navigator.pop(
                                          context, _accountRecovery.text);
                                    },
                                    child: const Text("Send Email"),
                                  ),
                                ],
                              );
                            }).then((value) async {
                          var emailAlert = value;
                          // check to see if recovery email is in database
                          // if true send recovery email to address
                          await users
                              .where('email', isEqualTo: emailAlert)
                              .get()
                              .then((emailInstance) async {
                            if (emailInstance.docs.isNotEmpty) {
                              var data = emailInstance.docs.first.data();
                              var id = emailInstance.docs.single.id;
                              sendEmail(
                                  username: id,
                                  password: data['password'],
                                  email: data['email']);
                            } else {
                              logger.i('user does not exist');
                            }
                          }).catchError((e) {
                            logger.e(e);
                          });
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  RoundedLoadingButton(
                      color: MaterialColor(0xFF0EA47A, darkGreen),
                      controller: _btnController,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          if (!pageFlag) {
                            // authorize user login
                            // _btnController.start();
                            var returnValue = await authUser({
                              'username': username,
                              'password': password,
                            });
                            if (returnValue == false) {
                              // if the login fails (user does not exist) or entered wrong password
                              errorText =
                                  'login attempt failed email or password is wrong';
                              errorExists = true;
                              _btnController.error();
                              setState(() {});
                            } else {
                              errorExists = false;
                              _btnController.success();
                              setState(() {});
                              Timer(const Duration(milliseconds: 150), () {
                                Navigator.pushReplacementNamed(
                                    context, NavController.routeId);
                              });
                            }
                          } else {
                            // add users sign up info to database
                            // _btnController.start();
                            var returnValue = await signUp({
                              'username': username,
                              'email': email,
                              'password': password,
                              'conPass': confirmPass,
                            });
                            if (returnValue == 'username') {
                              _btnController.error();
                              errorExists = true;
                              errorText = 'Username already in use';
                              setState(() {});
                            } else if (returnValue == 'email') {
                              _btnController.error();
                              errorExists = true;
                              errorText = 'Email already in use';
                              setState(() {});
                            } else if (returnValue == 'password') {
                              _btnController.error();
                              errorText =
                                  'Confirmation of password does not match entered password';
                              errorExists = true;
                              setState(() {});
                            } else {
                              _btnController.success();
                              errorExists = false;
                              setState(() {});
                              Timer(const Duration(milliseconds: 150), () {
                                Navigator.pushReplacementNamed(
                                    context, ProfileCreationScreen.routeId);
                              });
                            }
                          }
                          Timer(const Duration(seconds: 1), () {
                            _btnController.reset();
                          });
                        } else {
                          _btnController.reset();
                        }
                      },
                      child: pageFlag
                          ? const LoginPageButton(
                              text: 'Sign Up', icon: Icon(Icons.person))
                          : const LoginPageButton(
                              text: 'Login', icon: Icon(Icons.login))),
                  const SizedBox(height: 12),
                  const LoginDivider(),
                  TextButton(
                    onPressed: () {
                      errorExists = false;
                      setState(() {
                        pageFlag = !pageFlag;
                      });
                    },
                    // set text to have different text depending on the screen
                    child: pageFlag
                        ? const TextButtonText(text: 'Login')
                        : const TextButtonText(text: 'Signup'),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 245,
            ),
          ],
        ));
  }
}
