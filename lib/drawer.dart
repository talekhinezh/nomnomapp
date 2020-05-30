import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NomNomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
                title: Text('Checkout'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/checkout');
                }
            ),
            ListTile(
                title: Text('Orders'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/orders');
                }
            ),
            ListTile(
                title: Text('Customers'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/customers');
                }
            ),
            /*
            ListTile(
                title: Text('Transactions'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/transactions');
                }
            ),
             */
            ListTile(
                title: Text('Items'),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/items');
                }
            ),
          ],
        )
    );
  }
}