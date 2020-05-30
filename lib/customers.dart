import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nomnom/drawer.dart';
import 'package:intl/intl.dart';
import 'package:grouped_list/grouped_list.dart';

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
          (Map<K, List<E>> map, E element) =>
      map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));
}

class CustomersPage extends StatefulWidget {
  @override
  _CustomersPageState createState() {
    return _CustomersPageState();
  }
}

class _CustomersPageState extends State<CustomersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customers')),
      drawer: NomNomDrawer(),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('orders').orderBy('timestamp', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    List<Map<String, dynamic>> orders = snapshot
        .map((e) => new Map<String, dynamic>()
      ..addAll({ 'orderId': e.documentID, })
      ..addAll(e.data)
    ).toList();
    return Center(
        child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            child:
                Card(
                  elevation: 8.0,
                  margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  child: Container(
                      child: _buildListItem(context, orders)
                  ),
                ),
        )
    );
  }

  Widget _buildDescription(BuildContext context, List items) {
    String description = items.map((e) =>
    Map.from(e)['amount'].toString()
        + 'x ' +
        Map.from(e)['name']
        + (Map.from(e)['extras'] == null || Map.from(e)['extras'].isEmpty
        ? '' : '\n      ' + List.from(Map.from(e)['extras']).map((e) => '+' + Map.from(e)['name']).join(","))
    ).join("\n");

    return Container(
        child: Text(description)
    );
  }

  Widget _buildListItem(BuildContext context, List<Map<String, dynamic>> orders) {
    int totalCost = orders.map((order) => List.from(order['items'])
        .map((e) =>
    (
        Map.from(e)['cost']
            + (Map.from(e)['extras'] == null ? 0
            : List.from(Map.from(e)['extras'])
            .map((extra) => Map.from(extra)['cost'])
            .fold(0, (value, element) => value + element))
    )
        * Map.from(e)['amount'])
        .reduce((value, element) => value + element)
    ).fold(0, (a, b) => a + b);
    return
      ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        title: Text('Josh', style: TextStyle(fontSize: 20)),
        //subtitle: ,
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('₱' + totalCost.toString(), style: TextStyle(fontSize: 20)),
            Text(orders.length.toString() + ' total orders')
          ],
        ),
      );
  }
}