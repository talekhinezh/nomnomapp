import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nomnom/drawer.dart';
import 'package:intl/intl.dart';

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
      stream: Firestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 19.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final order = Order.fromSnapshot(data);

    return Padding(
      key: ValueKey(order.orderId),
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: ListTile(
          title: Text('₱' + order.totalCost.toString()),
          subtitle: Text(order.items),
          trailing: Text(new DateFormat().add_yMd().add_jm().format(order.timestamp.toDate()).toString()),
        ),
      ),
    );
  }
}

class Order {
  final String orderId;
  final int totalCost;
  final Timestamp timestamp;
  final DocumentReference reference;
  final String items;

  Order.fromMap(Map<String, dynamic> map, {this.reference})
      : this.orderId = reference.documentID,
        totalCost = List.from(map['items'])
            .map((e) => Map.from(e)['cost'])
            .reduce((value, element) => value + element),
        timestamp = map['timestamp'],
        items = List.from(map['items']).map((e) =>
        Map.from(e)['name'] + ' x' + Map.from(e)['amount'].toString()
        ).join(", ")
  ;

  Order.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference)
  ;

  @override
  String toString() => "Order<$timestamp>";
}