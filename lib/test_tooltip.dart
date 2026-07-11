import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          children: [
            Tooltip(
              message: 'Tooltip 1',
              child: Container(width: 100, height: 100, color: Colors.red),
            ),
            Tooltip(
              message: 'Tooltip 2',
              child: Container(width: 100, height: 100, color: Colors.blue),
            ),
          ],
        ),
      ),
    ),
  ));
}
