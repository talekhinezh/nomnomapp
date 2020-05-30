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
              label: Text(items.length.toString()),
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
              /*
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddItemPage(name: record.name)),
              )
               */
              setState(() {
                if (items.containsKey(record)) {
                  items = {}
                    ..addAll(items.map((key, value) =>
                        MapEntry(key, value + ((key == record) ? 1 : 0))));
                } else {
                  items = {record: 1}..addAll(items);
                }
              })
            },
          ),
      ),
    );
  }
}

class Record {
  final String name;
  final int cost;
  final String id;

  Record.fromMap(Map<String, dynamic> map, DocumentReference ref)
      : assert(map['name'] != null),
        name = map['name'],
        cost = map['cost'],
        id = ref.documentID;

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
class AddItemForm extends StatefulWidget {
  @override
  AddItemFormState createState() {
    return AddItemFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class AddItemFormState extends State<AddItemForm> {
  Map<String, dynamic> enabled;
  final List<String> extras = ['Egg', 'Rice'];

  AddItemFormState() :
    enabled = {'Egg': true, 'Rice': false };

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: ['Egg', 'Rice'].map((e) =>
          CheckboxListTile(
              title: Text(e),
              value: enabled[e],
              onChanged: (bool value) {
                setState(() {
                  var tmp = {};
                  tmp[e] = !enabled[e];
                  enabled = tmp;
                });
              },
              subtitle: const Text('₱20')
          )
      ).toList()
    );
  }
}

class AddItemPage extends StatelessWidget {
  final String name;
  AddItemPage({ this.name }) : super();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(this.name),
        ),
        body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: AddItemForm()
        )
    );
  }
}
