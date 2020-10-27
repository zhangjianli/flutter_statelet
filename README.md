# flutter_statelet

A Flutter package that helps you to reuse business logic.

# What is `Statelet`

A `Statelet` is similar to a `state`，but without `Widget build()`. 
That means `Statelet` has all the lifecycle callbacks `State`
has and represent piece of business logic that can be reused around.

A `State` can have multiple `Statelet`s, and you don't have to worry
about `setup` and `teardown` processes. Thease will be taken care of by 
`StateletHost`. 

# How to ues `Statelet`
See Counter example below:
```dart
void main() {
  runApp(MaterialApp(
    home: StateletExample(),
  ));
}

class StateletExample extends StatefulWidget {
  @override
  _StateletExampleState createState() => _StateletExampleState();
}
// Mix in the state with StateletHost
class _StateletExampleState extends State<StateletExample> with StateletHost {
  ValueNotifier<int> counter;

  @override
  void initState() {
    super.initState();
    // call install add the statelet to the State.
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

```
Checkout [statelet.dart](lib/src/statelet.dart) for more infomation.



