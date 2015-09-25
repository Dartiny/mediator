// Copyright (c) 2015, the package authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library mediator.src.core;

import 'dart:async' show Future;
import 'dart:collection' show SplayTreeMap;

/// The central point of event listener system.
///
/// Listeners are registered to the [EventDispatcher] and events are dispatched
/// through the [EventDispatcher].
abstract class EventDispatcher {

  factory EventDispatcher() => new EventDispatcherImpl();

  /// Dispatches an event to all registered listeners.
  ///
  /// [Future] will complete with event when all listeners will be invoked.
  ///
  /// You can check if the event propagation was stopped.
  ///
  ///     var event = await dispatcher.dispatch(new SomeEvent());
  ///     if (event.isPropagationStopped) {
  ///       // ...
  ///     }
  Future<Event> dispatch(Event event);

  /// Adds an event listener that listens on the specified events.
  ///
  /// The higher [priority] value, the earlier an event listener will
  /// be triggered in the chain (defaults to 0).
  ///
  /// The same listener can be added several times (even with the same priority).
  void addListener(Type eventType, EventListener listener, {int priority: 0});

  /// Removes an event listener from the specified events.
  ///
  /// All copies of the listener will be removed if the listener was registered
  /// several times for this event name.
  void removeListener(Type eventType, EventListener listener);

  /// Checks whether an event has any registered listeners.
  bool hasListeners(Type eventType);

  /// Returns the listeners of a specific event or all listeners sorted by
  /// descending priority.
  List<EventListener> getListeners(Type eventType);
}

class EventDispatcherImpl implements EventDispatcher {
  final Map<Type, Map<int, List<EventListener>>> _listeners;
  final Map<Type, List<EventListener>> _sorted;

  EventDispatcherImpl()
      : _listeners = new Map<Type, Map<int, List<EventListener>>>(),
        _sorted = new Map<Type, List<EventListener>>();

  Future<Event> dispatch(Event event) async {
    for (var listener in getListeners(event.runtimeType)) {
      if (event._propagationStopped) break;
      await listener(event);
    }

    return event;
  }

  void addListener(Type eventType, EventListener listener, {int priority: 0}) {
    if (!_listeners.containsKey(eventType)) {
      _listeners[eventType] =
          new SplayTreeMap<int, List<EventListener>>((int a, int b) => b.compareTo(a));
    }

    if (!_listeners[eventType].containsKey(priority)) {
      _listeners[eventType][priority] = new List<EventListener>();
    }

    _listeners[eventType][priority].add(listener);
    _sorted.remove(eventType);
  }

  void removeListener(Type eventType, EventListener listener) {
    if (!_listeners.containsKey(eventType)) {
      return;
    }

    var removed = false;

    _listeners[eventType].forEach((_, List<EventListener> listeners) {
      listeners.removeWhere((e) {
        if (identical(e, listener)) {
          removed = true;

          return true;
        }

        return false;
      });
    });

    if (removed) {
      _sorted.remove(eventType);
    }
  }

  bool hasListeners(Type eventType) {
    if (!_listeners.containsKey(eventType)) {
      return false;
    }

    var result = false;
    _listeners[eventType].forEach((_, List<EventListener> listeners) {
      if (listeners.isNotEmpty) result = true;
    });

    return result;
  }

  List<EventListener> getListeners(Type eventType) {
    if (!_sorted.containsKey(eventType)) {
      _sortListeners(eventType);
    }

    return _sorted.containsKey(eventType) ? _sorted[eventType] : const <EventListener>[];
  }

  void _sortListeners(Type eventType) {
    if (!_listeners.containsKey(eventType)) {
      return;
    }

    _sorted[eventType] = new List<EventListener>();

    _listeners[eventType].forEach((_, List<EventListener> listeners) {
      _sorted[eventType].addAll(listeners);
    });
  }
}

/// Method which acts as listener must to implement this signature.
typedef Future EventListener<E extends Event>(E event);

/// Event is the base class for classes containing event data.
///
/// Extend this class to create some type of event.
///
/// You can call the method [stopPropagation] to abort the execution of
/// further listeners in your event listener.
abstract class Event {
  bool _propagationStopped = false;

  /// Whether no further event listeners should be triggered.
  bool get isPropagationStopped => _propagationStopped;

  /// Stops the propagation of the event to further event listeners.
  ///
  /// If multiple event listeners are connected to the same event, no
  /// further event listener will be triggered once any trigger calls
  /// stopPropagation().
  void stopPropagation() {
    _propagationStopped = true;
  }
}
