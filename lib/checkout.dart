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
  Map<Record, int> items = {};

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
                  'name': e.key.name,
                  'cost': e.key.cost,
                  'itemId': e.key.id,
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
              child: Text('₱' + (items.isEmpty ? '0' : items.entries.map((e) => e.key.cost * e.value)
                  .reduce((value, element) => value + element).toString())),
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
            onTap: () => {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddItemPage(record)),
              )
              /*
              setState(() {
                if (items.containsKey(record)) {
                  items = {}
                    ..addAll(items.map((key, value) =>
                        MapEntry(key, value + ((key == record) ? 1 : 0))));
                } else {
                  items = {record: 1}..addAll(items);
                }
              })
               */
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
    return this.name == other.name && this.cost == other.cost && this.id == other.id;
  }
}
// Create a Form widget.
class AddExtrasForm extends StatefulWidget {
  final List<Extra> extras;
  AddExtrasForm(List<Extra> extras) : extras = extras;

  @override
  AddExtrasFormState createState() {
    return AddExtrasFormState(extras);
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class AddExtrasFormState extends State<AddExtrasForm> {
  Map<String, dynamic> enabled = new Map();
  final List<Extra> extras;

  AddExtrasFormState(List<Extra> extras) :
    extras = extras;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: extras.map((e) =>
          CheckboxListTile(
              title: Text(e.name),
              value: enabled[e.name] == null ? false : enabled[e.name],
              onChanged: (bool value) {
                setState(() {
                  var tmp = Map.of(enabled);
                  tmp[e.name] = value;
                  enabled = tmp;
                });
              },
              subtitle: Text("₱" + e.cost.toString())
          )
      ).toList()
    );
  }
}

class AddItemPage extends StatelessWidget {
  final Record record;
  AddItemPage(Record record) : record = record, super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(record.name),
        ),
        body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: AddExtrasForm(record.extras)
        ),
        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.check),
          onPressed: () {
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
                    child: Text('₱' + record.cost.toString())
                ),
                FlatButton(
                  child: Text(record.name)
                )
              ],
            ),
        ),
    );
  }
}
