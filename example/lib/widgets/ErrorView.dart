import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  String message;
  Widget child;

  ErrorView({this.message, this.child});

  @override
  Widget build(BuildContext context) {
    if (message != null) {
      return new Center(
          child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Icon(Icons.error_outline, color: Colors.redAccent, size: 60.0),
          new Padding(
            padding: new EdgeInsets.all(10.0),
            child: new Text(message),
          )
        ],
      ));
    }

    return child;
  }
}
