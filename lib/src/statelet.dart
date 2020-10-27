import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'framework.dart';

/// [Statelet] is similar to [State], but without UI. [Statelet] encapsulates
/// a pieces of business logic and provides all [State]'s lifecycle callbacks.
///
/// [Statelet] can be reused around Flutter apps.
///
/// [StateletHost] holds all [Statelet]s and redirects [State]
/// lifecycle callbacks ([initState], [dispose] etc.) to those [Statelet]s
///
///
/// Example:
///
/// class _StateletExampleState extends State<StateletExample> with StateletHost {
///   ValueNotifier<int> counter;
///
///     @override
///   void initState() {
///     super.initState();
///
///     counter = install(ValueNotifierStatelet(initValue: 0)).wrapper;
///
///     install(FunctionStatelet(
///         initState: () => print('initState'),
///         dispose: () => print('dispose')));
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('Statelet example'),
///       ),
///       body: Center(
///         child: Text('Button tapped ${counter.value} times'),
///       ),
///       floatingActionButton: FloatingActionButton(
///         onPressed: () => counter.value++,
///         child: const Icon(Icons.add),
///       ),
///     );
///   }
/// }
///
/// See also:
///  * [StateletHost]
abstract class Statelet<T extends StatefulWidget> {
  StateletHost _host;

  State get state => _host;

  BuildContext get context => state.context;

  T get widget => state.widget;

  bool get mounted => state.mounted;

  set host(StateletHost host) {
    assert(host != null, 'StateletHost cannot be null');
    _host = host;
  }

  void initState() {}

  /// If the configuration of your [Statelet] might change
  /// when [didUpdateWidget] is called. Instead of retrieve
  /// configuration form widget by override [didUpdateWidget] ,
  /// it is recommended to do so in [State] and call update(new_config)
  /// function exposed by [Statelet]'s subclass.
  ///
  /// Example:
  /// class _StateletExampleState extends State<StateletExample> with StateletHost {
  ///
  ///   _StateletExampleState() {
  ///     MyStatelet myStatelet = install(MyStatelet());
  ///   }
  ///
  ///   void didUpdateWidget(StateletExample oldWidget) {
  ///     super.didUpdateWidget(oldWidget);
  ///     if (widget.config != oldWidget.config) {
  ///       myStatelet.update(widget.config);
  ///     }
  ///   }
  ///
  /// }
  void didUpdateWidget(T oldWidget) {}

  void reassemble() {}

  void setState(VoidCallback fn) {
    state.setState(fn);
  }

  void deactivate() {}

  void dispose() {}

  void didChangeDependencies() {}
}

/// A [Statelet] that holds a single value.
class ValueStatelet<V> extends Statelet {
  V _value;

  V get value => _value;

  ValueStatelet({@required V initValue})
      : assert(initValue != null),
        _value = initValue;
}

/// A [Statelet] that holds a single value wrapped in a [ValueNotifier].
/// Whenever the value is changed, [setState] will be called.
class ValueNotifierStatelet<V> extends Statelet {
  ValueNotifier<V> _valueWrapper;

  ValueNotifier<V> get wrapper => _valueWrapper;

  ValueNotifierStatelet({@required V initValue})
      : assert(initValue != null),
        _valueWrapper = ValueNotifier(initValue);

  @override
  void initState() {
    super.initState();
    _valueWrapper.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _valueWrapper?.dispose();
    super.dispose();
  }
}

typedef VoidFunction = void Function();

/// [FunctionStatelet] delegates lifecycle callbacks to input functions.
class FunctionStatelet<T extends StatefulWidget> extends Statelet<T> {
  VoidFunction _initState;
  VoidFunction _didChangeDependencies;
  void Function(T) _didUpdateWidget;
  VoidFunction _deactivate;
  VoidFunction _dispose;

  FunctionStatelet(
      {VoidFunction initState,
      VoidFunction didChangeDependencies,
      void Function(T) didUpdateWidget,
      VoidFunction deactivate,
      VoidFunction dispose})
      : _initState = initState,
        _didChangeDependencies = didChangeDependencies,
        _didUpdateWidget = didUpdateWidget,
        _deactivate = deactivate,
        _dispose = dispose;

  @override
  void didChangeDependencies() {
    _didChangeDependencies?.call();
  }

  @override
  void dispose() {
    _dispose?.call();
  }

  @override
  void deactivate() {
    _deactivate?.call();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    _didUpdateWidget?.call(oldWidget);
  }

  @override
  void initState() {
    _initState?.call();
  }
}

/// [ProxyStatelet] delegates all calls to it's child
abstract class ProxyStatelet<T extends StatefulWidget, S extends Statelet<T>>
    extends Statelet<T> {
  S _child;

  S get child => _child;

  @mustCallSuper
  ProxyStatelet({@required S child})
      : assert(child != null, 'child should not be null'),
        _child = child;

  @override
  void didChangeDependencies() {
    _child?.didChangeDependencies();
  }

  @override
  void dispose() {
    _child?.dispose();
  }

  @override
  void deactivate() {
    _child?.deactivate();
  }

  @override
  void setState(VoidCallback fn) {
    _child?.setState(fn);
  }

  @override
  void reassemble() {
    _child?.reassemble();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    _child?.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _child?.initState();
  }

  @override
  set host(StateletHost host) {
    _child.host = host;
  }
}

/// Similar to [FutureBuilder]
class FutureStatelet<T> extends Statelet {
  Future<T> _future;

  Object _activeCallbackIdentity;
  AsyncSnapshot<T> _snapshot;

  AsyncSnapshot<T> get snapshot => _snapshot;

  FutureStatelet({Future<T> future, T initialData})
      : _future = future,
        _snapshot = AsyncSnapshot<T>.withData(ConnectionState.none, initialData);

  @override
  void initState() {
    super.initState();
    _subscribe();
  }


  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  /// [FutureStatelet] dose not override [didUpdateWidget] since we'd like to
  /// keep widgets out of [Statelet]. [update] is exposed to handle
  /// configuration change.
  void update(Future<T> newFuture) {
    if (_future != newFuture) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot.inState(ConnectionState.none);
      }
      _future = newFuture;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (_future != null) {
      final Object callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      _future.then<void>((T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error);
          });
        }
      });
       _snapshot = _snapshot.inState(ConnectionState.waiting);

    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }
}
