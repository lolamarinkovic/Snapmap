import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapmap/models/user.dart';
import 'package:snapmap/services/user_service.dart';
import 'package:snapmap/widgets/molecules/single_friend.dart';

class FriendsList extends StatefulWidget {
  const FriendsList(this.user, {Key? key}) : super(key: key);
  final User user;

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  List<FriendListItem> friendList = <FriendListItem>[];

  User user = UserService.getInstance().getCurrentUser()!;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: UserService.getInstance().currentUserStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          DocumentSnapshot<Map<String, dynamic>> doc =
              (snap.data! as DocumentSnapshot<Map<String, dynamic>>);
          User data = User.fromMap(doc.id, doc.data()!);
          if (data.friends.isEmpty) {
            return const Center(
              child: Text('You have no friends 😭'),
            );
          }

          return ListView.separated(
            itemCount: data.friends.length,
            itemBuilder: (BuildContext context, int index) {
              return FutureBuilder(
                future:
                    UserService.getInstance().getOtherUser(data.friends[index]),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data == null) {
                      return Container();
                    }
                    return Container(
                        padding: const EdgeInsets.all(8),
                        child: FriendListItem(snapshot.data));
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(
              color: Color(0xFF0EA47A),
              thickness: 0.5,
            ),
          );
        });
  }
}
