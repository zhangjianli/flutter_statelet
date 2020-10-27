import 'package:flutter/widgets.dart';
import 'package:flutter_statelet/src/statelet.dart';

/// [StateletHost] manages all installed [Statelet]s
mixin StateletHost<T extends StatefulWidget> on State<T> {

  /// List that holds all statelets;
  final _statelets = <Statelet>[];

  /// Install a [Statelet]. This function should only be called
  /// in [StateletHost]'s constructor.
  @protected
  S install<S extends Statelet>(S statelet) {
    assert(statelet != null);
    statelet.host = this;
    try {
      statelet.initState();
    } catch (exception, stack) {
      _debugReportException(exception, stack,
          ErrorDescription('while initializing ${statelet.runtimeType}'));
    }
    _statelets.add(statelet);
    return statelet;
  }

  /// Subclass overrides [initState] to install statelets.
  @override
  @protected
  void initState() {
    super.initState();
  }

  /// Redirect [reassemble] call to  all [Statelet]s;
  @override
  @protected
  void reassemble() {
    super.reassemble();
    for (final statelet in _statelets) {
      try {
        statelet.reassemble();
      } catch (exception, stack) {
        _debugReportException(exception, stack,
            ErrorDescription('while reassembling ${statelet.runtimeType}'));
      }
    }
  }

  /// Redirect [didChangeDependencies] call to  all [Statelet]s;
  @override
  @protected
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final statelet in _statelets) {
      try {
        statelet.didChangeDependencies();
      } catch (exception, stack) {
        _debugReportException(
            exception,
            stack,
            ErrorDescription(
                'while calling ${statelet.runtimeType}.didChangeDependencies()'));
      }
    }
  }

  /// Redirect [didUpdateWidget] call to  all [Statelet]s;
  ///
  /// Note: Since statelet should be UI irrelevant
  /// and be reused around different [StatefulWidget]s.
  /// So please avoid to override [didUpdateWidget] in [Statelet]'s subclasses.
  @override
  @protected
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final statelet in _statelets) {
      try {
        statelet.didUpdateWidget(oldWidget);
      } catch (exception, stack) {
        _debugReportException(
            exception,
            stack,
            ErrorDescription(
                'while calling ${statelet.runtimeType}.didUpdateWidget()'));
      }
    }
  }

  /// Redirect [deactivate] call to  all [Statelet]s;
  @override
  @protected
  void deactivate() {
    for (final statelet in _statelets) {
      try {
        statelet.deactivate();
      } catch (exception, stack) {
        _debugReportException(exception, stack,
            ErrorDescription('while deactivating ${statelet.runtimeType}'));
      }
    }
    super.deactivate();
  }

  /// Redirect [dispose] call to  all [Statelet]s;
  @override
  @protected
  void dispose() {
    for (final statelet in _statelets) {
      try {
        statelet.dispose();
      } catch (exception, stack) {
        _debugReportException(exception, stack,
            ErrorDescription('while disposing ${statelet.runtimeType}'));
      }
    }
    super.dispose();
  }
}

FlutterErrorDetails _debugReportException(
    dynamic exception, StackTrace stack, DiagnosticsNode context) {
  final FlutterErrorDetails details = FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'statelet library',
      context: context);
  FlutterError.reportError(details);
  return details;
}
