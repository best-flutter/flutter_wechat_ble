import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  bool loading;
  Widget child;

  LoadingView({this.loading, this.child});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return child;
  }
}
