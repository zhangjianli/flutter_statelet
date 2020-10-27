import 'package:flutter/material.dart';
import 'package:flutter_statelet/flutter_statelet.dart';

void main() {
  runApp(MaterialApp(
    home: StateletExample(),
  ));
}

class StateletExample extends StatefulWidget {
  @override
  _StateletExampleState createState() => _StateletExampleState();
}

class _StateletExampleState extends State<StateletExample> with StateletHost {
  ValueNotifier<int> counter;

  @override
  void initState() {
    super.initState();

    counter = install(ValueNotifierStatelet(initValue: 0)).wrapper;
    install(FunctionStatelet(
        initState: () => print('initState'),
        dispose: () => print('dispose')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statelet example'),
      ),
      body: Center(
        child: Text('You have pushed the button ${counter.value} times'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
