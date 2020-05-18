import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nomnom/drawer.dart';
import 'package:timeago/timeago.dart' as timeago;

class TransactionsPage extends StatefulWidget {
  @override
  _TransactionsPageState createState() {
    return _TransactionsPageState();
  }
}

class _TransactionsPageState extends State<TransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transactions')),
      drawer: NomNomDrawer(),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('transactions').snapshots(),
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
    final transaction = Transaction.fromSnapshot(data);

    return Padding(
      key: ValueKey(transaction.transactionId),
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: ListTile(
          title: Text("PHP" + transaction.totalCost.toString()),
          subtitle: Text(transaction.items),
          trailing: Text(timeago.format(transaction.timestamp.toDate())),
        ),
      ),
    );
  }
}

class Transaction {
  final String transactionId;
  final int totalCost;
  final Timestamp timestamp;
  final DocumentReference reference;
  final String items;

  Transaction.fromMap(Map<String, dynamic> map, {this.reference})
      : this.transactionId = reference.documentID,
        totalCost = List.from(map['items'])
            .map((e) => Map.from(e)['cost'] * Map.from(e)['amount'])
            .reduce((value, element) => value + element),
        timestamp = map['timestamp'],
        items = List.from(map['items']).map((e) =>
          Map.from(e)['name'] + ' x' + Map.from(e)['amount'].toString()
        ).join(", ")
  ;

  Transaction.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference)
  ;

  @override
  String toString() => "Record<$timestamp>";
}