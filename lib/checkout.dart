import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:nomnom/drawer.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() {
    return _CheckoutPageState();
  }
}

class _CheckoutPageState extends State<CheckoutPage> {
  Map<CheckoutItem, int> items = {};
  int _total() {
    return items.entries.map(
            (e) => (e.key.record.cost + e.key.extras.map((e) => e.cost).fold(0, (a, b) => a + b)) * e.value)
        .fold(0, (value, element) => value + element);
  }

  Widget _buildCurrentItems(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: Colors.white,
      child: Column(
        children:[
          Expanded(
              child: Column(
                  children: items.entries.map((e) => Text(e.key.record.name + " x" + e.value.toString())).toList()
              )
          ),
          Container(
            child: RaisedButton(
              elevation: 10.0,
              textColor: Colors.white,
              padding: const EdgeInsets.fromLTRB(100.0, 25.0, 100.0, 25.0),
              color: Colors.green,
              child: Text(
                  'Checkout - ₱' + _total().toString(),
                  style: TextStyle(fontSize: 20)
              ),
              onPressed: _total() == 0 ? null : () {
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
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout')
      ),
      drawer: NomNomDrawer(),
      body: Row(
        children: [
          _buildCurrentItems(context),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child:
                Column(
                  children: [
                      Expanded(
                          child: TabBarView(
                            children: [
                              _buildBody(context, 'food'),
                              _buildBody(context, 'drinks'),
                              _buildBody(context, 'burgers'),
                            ].toList(),
                          )
                      ),
                      Container(
                          color: Colors.blue,
                          child: TabBar(
                              indicatorColor: Colors.white,
                              tabs: [
                                Tab(
                                  text: 'Food',
                                  icon: Icon(Icons.restaurant),
                                ),
                                Tab(
                                  text: 'Drinks',
                                  icon: Icon(Icons.free_breakfast),
                                ),
                                Tab(
                                  text: 'Burgers',
                                  icon: Icon(Icons.fastfood),
                                ),
                              ].toList()
                          )
                      ),
                    ]
                )
            )
          )
        ],
      ),//_buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context, String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('items').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents, category);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot, String category) {
    return Center(
      child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          child: ListView(
              children: snapshot
                  .map((e) => Record.fromSnapshot(e))
                  .where((record) => record.categories.contains(category))
                  .map((record) => _buildListItem(context, record))
                  .toList(),
            )
      )
    );
  }

  Widget _buildListItem(BuildContext context, Record record) {
    return Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            title: Text(record.name),
            trailing: Text("₱" + record.cost.toString()),
            onTap: () async {
              final CheckoutItem checkoutItem =
              record.extras.isNotEmpty ?
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddItemPage(record)),
                ) as CheckoutItem :
                CheckoutItem(record, []);

              if (checkoutItem == null) {
                return;
              }

              setState(() {
                if (items.containsKey(checkoutItem)) {
                  items = {}
                    ..addAll(items.map((key, value) =>
                        MapEntry(key, value + ((key.record == record) ? 1 : 0))));
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

  @override
  int get hashCode => hashValues(name, cost);

  @override
  bool operator ==(other) {
    return this.name == other.name && this.cost == other.cost;
  }
}

class Record {
  final String name;
  final int cost;
  final String id;
  final List<Extra> extras;
  final List<String> categories;

  Record.fromMap(Map<String, dynamic> map, DocumentReference ref)
      : assert(map['name'] != null),
        name = map['name'],
        cost = map['cost'],
        id = ref.documentID,
        categories = List.castFrom(map['categories']),
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
        && this.id == other.id;
  }
}

class CheckoutItem {
  final Record record;
  final List<Extra> extras;
  Function eq = const ListEquality().equals;

  CheckoutItem(this.record, this.extras);

  @override
  int get hashCode => record.hashCode;

  @override
  bool operator ==(other) {
    return this.record == other.record && eq(this.extras, other.extras);
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
                            if (value) {
                              tmp[e.name] = e;
                            } else {
                              tmp.remove(e.name);
                            }
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
                    child: Text('₱' + (widget.record.cost
                        + enabled.values.map((e) => e.cost).fold(0, (a, b) => a + b)).toString())
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
