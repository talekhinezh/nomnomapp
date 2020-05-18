import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nomnom/transactions.dart';
import 'items.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/transactions',
      routes: {
        '/items': (content) => FoodItemsPage(),
        '/transactions': (context) => TransactionsPage()
      }
    );
  }
}


