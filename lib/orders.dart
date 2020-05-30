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


class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() {
    return _OrdersPageState();
  }
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orders')),
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

  Widget _buildGroupSeparator(dynamic localDate) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
          child: Text(
            DateFormat().add_MMMd().format(localDate),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )),
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
            child: GroupedListView(
              elements: orders,
              groupBy: (order) {
                DateTime dateTime = order['timestamp'].toDate().toLocal();
                return new DateTime(dateTime.year, dateTime.month, dateTime.day);
              },
              groupSeparatorBuilder: _buildGroupSeparator,
              itemBuilder: (context, element) =>
                  Card(
                    elevation: 8.0,
                    margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    child: Container(
                        child: _buildListItem(context, element)
                    ),
                  ),
              order: GroupedListOrder.DESC,
            )
        )
    );
    /*
    return ListView.separated(
      itemCount: snapshot.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          padding: EdgeInsets.all(8.0),
          height: 80,
          child: _buildListItem(context, orders[index])
        );
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(
        color: Colors.black
      ),
    );
     */
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

  Widget _buildListItem(BuildContext context, Map<String, dynamic> order) {
    int totalCost = List.from(order['items'])
        .map((e) =>
          (
            Map.from(e)['cost']
            + (Map.from(e)['extras'] == null ? 0
                : List.from(Map.from(e)['extras'])
                .map((extra) => Map.from(extra)['cost'])
                .fold(0, (value, element) => value + element))
          )
          * Map.from(e)['amount'])
        .reduce((value, element) => value + element);
    return
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          title: Text('₱' + totalCost.toString()),
          subtitle: _buildDescription(context, List.from(order['items'])),
          trailing: Text(new DateFormat().add_jm().format(order['timestamp'].toDate()).toString()),
    );
  }
}
