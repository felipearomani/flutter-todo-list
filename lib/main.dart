import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import "package:flutter/material.dart";
import 'package:flutter/material.dart' as prefix0;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _toDoList = [];
  bool _isLoading = false;
  final _toDoTextController = TextEditingController();

  void _cleanToDoText() {
    _toDoTextController.clear();
  }

  void _doLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  @override
  void initState() {
    super.initState();

    _doLoading(true);

    readData()
      .then((data) {
        setState(() {
          _toDoList = jsonDecode(data);
        });

        _doLoading(false);
      });
  }

  void _addToDo(String term) {
    setState(() {
      _toDoList.add({
        "title": term,
        "ok": false
      });
      saveData();
      _cleanToDoText();
    });
  }

  void _recoveryToDo(index, item) {
    setState(() {
      _toDoList.insert(index, item);
    });
  }

  void _removeTodo(index) {
    setState(() {
      _toDoList.removeAt(index);
      saveData();
    });
  }

  void _changeChecked(checked, index) {
    setState(() {
      _toDoList[index]['ok'] = checked;
      saveData();
    });
  }

  Future<Void> _refresh() async {
    Future.delayed(Duration(seconds: 2));

    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok']) return 1;
        else if(!a['ok'] && b['ok']) return -1;
        else return 0;
      });

      saveData();
    });

    return Future.value(null);
  }

  Widget _renderLoading() {
    return Container(
      child: SpinKitFadingCube(
        color: Colors.lightBlue,
        size: 100.0,
      ),
    );
  }

  Widget _renderList() {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(20, 0, 10, 20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _toDoTextController,
                  decoration: InputDecoration(
                    labelText: "Nova Tarefa",
                    labelStyle: TextStyle(color: Colors.lightBlue),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (term) {
                    _addToDo(term);
                  },
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _cleanToDoText();
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: (context, index) {
                  return _getListItems(context, index);
                }
            ),
          )
        )
      ],
    );
  }

  Widget _getListItems(context, int index) {
    return Dismissible(
        key: UniqueKey(),
        background: Container(
          color: Colors.red[300],
          child: Align(
              alignment: Alignment(-0.9, 0.0),
              child: Icon(Icons.delete, color: Colors.white),
          ),
        ),
        child: CheckboxListTile(
          title: Text(_toDoList[index]["title"],
            style: TextStyle(color: Colors.grey[500]),
          ),
          secondary: CircleAvatar(
              backgroundColor: _toDoList[index]["ok"]
                  ? Colors.blueAccent
                  : Colors.orangeAccent,
              child: _toDoList[index]["ok"]
                  ? Icon(Icons.check)
                  : Icon(Icons.av_timer, color: Colors.white)
          ),
          value: _toDoList[index]["ok"],
          onChanged: (checked) {
            _changeChecked(checked, index);
          },
        ),
      onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {

            var item = _toDoList[index];
            var itemTitle = item["title"];

            _removeTodo(index);

            Scaffold.of(context).removeCurrentSnackBar();

            Scaffold
                .of(context)
                .showSnackBar(SnackBar(
                  content: Text('$itemTitle removido com sucesso!'),
                  action: SnackBarAction(
                    label: "Desfazer",
                    onPressed: () {
                      _recoveryToDo(index, item);
                    },
                  ),

                ));
          }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: _isLoading
          ? _renderLoading()
          : _renderList()
    );
  }

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return new File("${directory.path}/data.json");
  }

  Future<File> saveData() async {
    final file = await _localFile;
    var encode = jsonEncode(_toDoList);
    return file.writeAsString(encode);
  }

  Future<String> readData() async {

      var file = await _localFile;
      // To show the loading Widget waiting 5 seconds
      await Future.delayed(Duration(seconds: 3));

      var isFileExists = await file.exists();

      if (isFileExists) {
        return file.readAsString();
      } else {
        return Future.value("[]");
      }
  }

}
