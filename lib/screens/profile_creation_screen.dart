// this screen handles the extra info needed after sign up (the profile picture and display name)
// this screen is pushed directly after sign up

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapmap/models/user.dart';
import 'package:snapmap/services/photo_service.dart';
import 'package:snapmap/services/user_service.dart';
import 'package:snapmap/utils/logger.dart';
import 'package:snapmap/widgets/atoms/loading.dart';
import 'package:snapmap/widgets/molecules/avatar_picker.dart';
import 'package:snapmap/widgets/organisms/nav_controller.dart';

class ProfileCreationScreen extends StatefulWidget {
  static const String routeId = '/profile_creation';
  const ProfileCreationScreen({Key? key}) : super(key: key);

  @override
  _ProfileCreationScreenState createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  String imageUrl = '';
  String displayName = '';
  Uint8List? selectedImageBytes;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final users = FirebaseFirestore.instance.collection("Users");
  User user = UserService.getInstance().getCurrentUser()!;
  bool flag = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      imageUrl = user.profileUrl;
      displayName = user.displayName;
    });
  }

  void avatarPickerCallback(Uint8List imageBytes) {
    setState(() {
      selectedImageBytes = imageBytes;
    });
  }

  // check if display name is already in use for validator
  checkUserDN(String dn) async {
    var result =
        await users.where('displayName', isEqualTo: dn.toString()).get();
    if (result.docs.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          // app bar to make it look nicer
          appBar: AppBar(
            // no back button
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // cancel button that returns back to user screen
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white, fontSize: 14))),
                const Text('Your Profile'),
                const SizedBox(width: 3),
                const Icon(Icons.edit, size: 25),
              ],
            ),
          ),
          body: Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                AvatarPicker(user, callback: avatarPickerCallback),

                /// This form sets the display name field
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: displayName,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (text) async {
                          checkUserDN(text).then((value1) {
                            if (value1) {
                              flag = true;
                            } else {
                              flag = false;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Must enter display name';
                          } else if (flag) {
                            return 'Display name already in use';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          displayName = value.toString();
                        },
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      showDialog(
                          context: context, builder: (_) => const Loading());
                      _formKey.currentState!.save();
                      if (selectedImageBytes != null) {
                        imageUrl = await uploadProfileImage(
                            user.username, selectedImageBytes!);
                        user.profileUrl = imageUrl;
                      }
                      user.displayName = displayName;
                      UserService.getInstance().setUser(user);
                      await users
                          .doc(user.username)
                          .set(user.toMap())
                          .then((value) async {
                        logger.i('Added Display Name');
                      }).catchError((e) {
                        logger.e(e);
                      });
                      Navigator.pushReplacementNamed(
                          context, NavController.routeId);
                    }
                  },
                  // make button full width and add icon
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Save Profile Changes'),
                      SizedBox(width: 10),
                      Icon(Icons.check)
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
