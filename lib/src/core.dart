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
  /// If [event] not given then an instance of [Event] will be returned when
  /// future will complete.
  ///
  /// You can check if the event propagation was stopped.
  ///
  ///     var event = await dispatcher.dispatch('some-event');
  ///     if (event.isPropagationStopped) {
  ///       // ...
  ///     }
  Future<Event> dispatch(String eventName, [Event event]);

  /// Adds an event listener that listens on the specified events.
  ///
  /// The higher [priority] value, the earlier an event listener will
  /// be triggered in the chain (defaults to 0).
  ///
  /// The same listener can be added several times (even with the same priority).
  void addListener(String eventName, EventListener listener, {int priority: 0});

  /// Removes an event listener from the specified events.
  ///
  /// All copies of the listener will be removed if the listener was registered
  /// several times for this event name.
  void removeListener(String eventName, EventListener listener);

  /// Checks whether an event has any registered listeners.
  bool hasListeners(String eventName);

  /// Returns the listeners of a specific event or all listeners sorted by
  /// descending priority.
  List<EventListener> getListeners(String eventName);
}

class EventDispatcherImpl implements EventDispatcher {
  final Map<String, Map<int, List<EventListener>>> _listeners;
  final Map<String, List<EventListener>> _sorted;

  EventDispatcherImpl()
      : _listeners = new Map<String, Map<int, List<EventListener>>>(),
        _sorted = new Map<String, List<EventListener>>();

  Future<Event> dispatch(String eventName, [Event event]) async {
    if (event == null) {
      event = new Event();
    }

    for (var listener in getListeners(eventName)) {
      if (event._propagationStopped) break;
      await listener(eventName, event);
    }

    return event;
  }

  void addListener(String eventName, EventListener listener, {int priority: 0}) {
    if (!_listeners.containsKey(eventName)) {
      _listeners[eventName] =
          new SplayTreeMap<int, List<EventListener>>((int a, int b) => b.compareTo(a));
    }

    if (!_listeners[eventName].containsKey(priority)) {
      _listeners[eventName][priority] = new List<EventListener>();
    }

    _listeners[eventName][priority].add(listener);
    _sorted.remove(eventName);
  }

  void removeListener(String eventName, EventListener listener) {
    if (!_listeners.containsKey(eventName)) {
      return;
    }

    var removed = false;

    _listeners[eventName].forEach((_, List<EventListener> listeners) {
      listeners.removeWhere((e) {
        if (identical(e, listener)) {
          removed = true;

          return true;
        }

        return false;
      });
    });

    if (removed) {
      _sorted.remove(eventName);
    }
  }

  bool hasListeners(String eventName) {
    if (!_listeners.containsKey(eventName)) {
      return false;
    }

    var result = false;
    _listeners[eventName].forEach((_, List<EventListener> listeners) {
      if (listeners.isNotEmpty) result = true;
    });

    return result;
  }

  List<EventListener> getListeners(String eventName) {
    if (!_sorted.containsKey(eventName)) {
      _sortListeners(eventName);
    }

    return _sorted.containsKey(eventName) ? _sorted[eventName] : const <EventListener>[];
  }

  void _sortListeners(String eventName) {
    if (!_listeners.containsKey(eventName)) {
      return;
    }

    _sorted[eventName] = new List<EventListener>();

    _listeners[eventName].forEach((_, List<EventListener> listeners) {
      _sorted[eventName].addAll(listeners);
    });
  }
}

/// Method which acts as listener must to implement this signature.
typedef Future EventListener<E extends Event>(String eventName, E event);

/// Event is the base class for classes containing event data.
///
/// This class contains no event data. It is used by events that do not pass
/// state information to an event handler when an event is raised.
///
/// You can call the method [stopPropagation] to abort the execution of
/// further listeners in your event listener.
class Event {
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
