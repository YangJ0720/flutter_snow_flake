import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_snow_flake/snow_flake.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final HashSet<int> _hashSet = HashSet();
  final StreamController<List<int>> _controller = StreamController();

  ///
  void _loadData() {
    _hashSet.clear();
    List<int> list = [];
    SnowFlake snowFlake = SnowFlake.factory();
    int number = Random().nextInt(1000);
    for (int i = 0; i < number; i++) {
      int id = snowFlake.nextId();
      list.add(id);
      _hashSet.add(id);
    }
    _controller.sink.add(list);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      builder: (_, snapshot) {
        List<int> list = snapshot.requireData;
        int length = list.length;
        return Scaffold(
          appBar: AppBar(
            title: Text('list = $length, hashSet = ${_hashSet.length}'),
            actions: [
              IconButton(
                onPressed: () => _loadData(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: ListView.builder(
            itemBuilder: (_, index) {
              String item = list[index].toString();
              return ListTile(title: Text(item));
            },
            itemCount: length,
          ),
        );
      },
      stream: _controller.stream,
      initialData: const [],
    );
  }
}
