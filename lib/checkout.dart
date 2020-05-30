import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nomnom/drawer.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() {
    return _CheckoutPageState();
  }
}

class _CheckoutPageState extends State<CheckoutPage> {
  Map<CheckoutItem, int> items = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      drawer: NomNomDrawer(),
      body: _buildBody(context),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          Firestore.instance.collection('orders')
              .add({
                'timestamp': DateTime.now(),
                'items': items.entries.map((e) => {
                  'name': e.key.record.name,
                  'cost': e.key.record.cost,
                  'itemId': e.key.record.id,
                  'extras': e.key.extras.map((extra) => {'name': extra.name, 'cost': extra.cost}).toList(),
                  'amount': e.value,
                }).toList()
              })
            .then((value) => Navigator.pushReplacementNamed(context, '/orders'));
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FlatButton(
              child: Text('₱' + items.entries.map(
                      (e) => (e.key.record.cost +
                          e.key.extras.map((e) => e.cost).fold(0, (a, b) => a + b)) * e.value
              ).fold(0, (value, element) => value + element).toString()),
            ),
            FlatButton.icon(
              label: Text(items.isEmpty ? '0' : items.values.reduce((value, element) => value + element).toString()),
              icon: Icon(Icons.format_list_bulleted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return Center(
      child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.only(top: 19.0),
            children: snapshot.map((data) => _buildListItem(context, data)).toList(),
          )
      )
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            title: Text(record.name),
            trailing: Text("₱" + record.cost.toString()),
            onTap: () async {
              final checkoutItem = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddItemPage(record)),
              ) as CheckoutItem;

              setState(() {
                if (items.containsKey(checkoutItem)) {
                  items = {}
                    ..addAll(items.map((key, value) =>
                        MapEntry(key, value + ((key == record) ? 1 : 0))));
                } else {
                  items = {checkoutItem: 1}..addAll(items);
                }
              });
            },
          ),
      ),
    );
  }
}

class Extra {
  final String name;
  final int cost;
  Extra({ this.name, this.cost});

  Extra.fromMap(Map<String, dynamic> map) :
    name = map['name'],
    cost = map['cost'];
}

class Record {
  final String name;
  final int cost;
  final String id;
  final List<Extra> extras;

  Record.fromMap(Map<String, dynamic> map, DocumentReference ref)
      : assert(map['name'] != null),
        name = map['name'],
        cost = map['cost'],
        id = ref.documentID,
        extras = map['extras'] == null ? [] : List.from(map['extras']).map((e) => Extra.fromMap(e)).toList();

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, snapshot.reference);

  @override
  int get hashCode => hashValues(name, cost, id);

  @override
  String toString() => "Record<$name:$cost>";

  @override
  bool operator ==(other) {
    return this.name == other.name && this.cost == other.cost
        && this.id == other.id && this.extras == other.extras;
  }
}

class CheckoutItem {
  final Record record;
  final List<Extra> extras;

  CheckoutItem(this.record, this.extras);

  @override
  int get hashCode => record.hashCode^extras.hashCode;

  @override
  bool operator ==(other) {
    return this.record == other.record && this.extras == other.extras;
  }
}

// Create a Form widget.
class AddItemPage extends StatefulWidget {
  final Record record;
  AddItemPage(Record record) : record = record, super();

  @override
  AddItemPageState createState() {
    return AddItemPageState();
  }
}

class AddItemPageState extends State<AddItemPage> {
  Map<String, Extra> enabled = new Map();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.record.name),
        ),
        body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: ListView(
                children: widget.record.extras.map((e) =>
                    CheckboxListTile(
                        title: Text(e.name),
                        value: enabled[e.name] != null,
                        onChanged: (bool value) {
                          setState(() {
                            var tmp = Map.of(enabled);
                            tmp[e.name] = e;
                            enabled = tmp;
                          });
                        },
                        subtitle: Text("₱" + e.cost.toString())
                    )
                ).toList()
            )
        ),
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.check),
          onPressed: () {
            Navigator.pop(context, CheckoutItem(widget.record, enabled.values.toList()));
          },
        ),
        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
            notchMargin: 4.0,
            child: new Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FlatButton(
                    child: Text('₱' + widget.record.cost.toString())
                ),
                FlatButton(
                  child: Text(widget.record.name)
                )
              ],
            ),
        ),
    );
  }
}
