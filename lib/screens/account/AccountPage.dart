import 'dart:ui';

import 'package:bluetooth_app/model/Account.dart';
import 'package:bluetooth_app/provider/Account.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Account user;
  bool _showPopUp;

  @override
  void initState() {
    super.initState();

    _showPopUp = false;
    user = Provider.of<AccountProvider>(context, listen: false).getUser();
  }

  @override
  Widget build(BuildContext context) {
    double _screenWidth = MediaQuery.of(context).size.width;
    double _screenHeight = MediaQuery.of(context).size.height;

    Container _avatarWidget() {
      return Container(
        width: 110,
        height: 110.0,
        child: Stack(
          overflow: Overflow.visible,
          children: <Widget>[
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withOpacity(0.02),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.black.withOpacity(0.03),
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Color(0xFFF7F7F7),
                child: Text('A', textScaleFactor: 3.0),
              ),
            ),
            Positioned(
              bottom: 0,
              right: -5,
              child: Container(
                width: 30,
                height: 30,
                padding: EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      offset: Offset(0.0, 2.5),
                      blurRadius: 30.5,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {},
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: _screenHeight,
            width: _screenWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    // ------------------ Avatar ------------------ //
                    _avatarWidget(),
                    SizedBox(height: 16),

                    // ------------------ User Name ------------------ //
                    Text(
                      user?.name ?? '',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.phone ?? '',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    SizedBox(height: 32),

                    // ------------------ List Menu ------------------ //
                    Ink(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white24, width: 0.75),
                        ),
                      ),
                      child: ListTile(
                        title: Text('Edit Profile'),
                        leading: Icon(Icons.account_circle),
                        // trailing: Icon(Icons.navigate_next),
                        contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        onTap: () {},
                      ),
                    ),
                    // ------------------ Manage Device ------------------ //
                    Ink(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white24,
                            width: 0.75,
                          ),
                          bottom: BorderSide(
                            color: Colors.white24,
                            width: 0.75,
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Text('Saved Device'),
                        leading: Icon(Icons.dock),
                        // trailing: Icon(Icons.navigate_next),
                        contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        onTap: () => setState(() => _showPopUp = true),
                      ),
                    ),
                    // ------------------ Manage Device ------------------ //
                    Ink(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white24,
                            width: 0.75,
                          ),
                          bottom: BorderSide(
                            color: Colors.white24,
                            width: 0.75,
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Text('Log Out'),
                        leading: Icon(Icons.exit_to_app),
                        // trailing: Icon(Icons.navigate_next),
                        contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        onTap: () => setState(() => _showPopUp = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          !_showPopUp
              ? SizedBox()
              : InkWell(
                  onTap: () => setState(() => _showPopUp = false),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      height: _screenHeight,
                      width: _screenWidth,
                      alignment: Alignment.center,
                      color: Colors.transparent,
                    ),
                  ),
                ),
          !_showPopUp
              ? SizedBox()
              : Container(
                  width: _screenWidth * 0.7,
                  height: _screenHeight * 0.25,
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  child: user?.savedDeviceId == null
                      ? Column(
                          children: <Widget>[
                            Expanded(
                              child: Icon(
                                Icons.delete_outline,
                                size: 80,
                              ),
                            ),
                            Text(
                              'You don\'t have any saved devices.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: <Widget>[
                            Text(
                              'SAVED DEVICE',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(height: 2, color: Colors.white10),
                            SizedBox(height: 12),
                            Text(
                              'Device ID: ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              user?.savedDeviceId ?? '',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Expanded(child: SizedBox()),
                            RaisedButton(
                              child: Text('Forgot Device'),
                              onPressed: () {
                                Provider.of<AccountProvider>(context,
                                        listen: false)
                                    .setDeviceId(null);
                                setState(() {});
                              },
                            )
                          ],
                        ),
                )
        ],
      ),
    );
  }
}
