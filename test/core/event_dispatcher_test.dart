// Copyright (c) 2015, the package authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library mediator.test.event_dispatcher;

import 'dart:async' show Future;
import 'package:test/test.dart';
import 'package:mediator/mediator.dart';

class EventA extends Event {}
class EventB extends Event {}
class EventC extends Event {}

class TestEventListener {
  bool shouldStopPropagation = false;
  int callsAmount = 0;
  final List<EventListener> _calls;

  TestEventListener(this._calls);

  Future call(Event event) async {
    callsAmount++;
    _calls.add(this);

    if (shouldStopPropagation) {
      event.stopPropagation();
    }
  }
}

void main() {
  group('EventDispatcher', () {
    EventDispatcher dispatcher;
    List<EventListener> calls;

    TestEventListener listenerA;
    TestEventListener listenerB;
    TestEventListener listenerC;

    setUp(() {
      dispatcher = new EventDispatcher();
      calls = new List<EventListener>();
      listenerA = new TestEventListener(calls);
      listenerB = new TestEventListener(calls);
      listenerC = new TestEventListener(calls);
    });
    tearDown(() {
      dispatcher = null;
      calls = null;
      listenerA = null;
      listenerB = null;
      listenerC = null;
    });

    test('Initial state.', () {
      expect(dispatcher.hasListeners(EventA), isFalse);
      expect(dispatcher.hasListeners(EventB), isFalse);

      expect(dispatcher.getListeners(EventA), hasLength(0));
      expect(dispatcher.getListeners(EventB), hasLength(0));
    });

    test('.addListener()', () {
      dispatcher
        ..addListener(EventA, listenerA)
        ..addListener(EventB, listenerA)
        ..addListener(EventB, listenerB);

      expect(dispatcher.hasListeners(EventA), isTrue);
      expect(dispatcher.hasListeners(EventB), isTrue);

      expect(dispatcher.getListeners(EventA), hasLength(1));
      expect(dispatcher.getListeners(EventB), hasLength(2));
    });

    test('.getListeners() Sortes by priority.', () {
      dispatcher
        ..addListener(EventA, listenerA, priority: -10)
        ..addListener(EventA, listenerB, priority: 10)
        ..addListener(EventA, listenerC);

      expect(dispatcher.getListeners(EventA), equals([listenerB, listenerC, listenerA]));
    });

    test('.removeListener()', () {
      dispatcher.addListener(EventA, listenerA);
      expect(dispatcher.hasListeners(EventA), isTrue);

      dispatcher.removeListener(EventA, listenerA);
      expect(dispatcher.hasListeners(EventA), isFalse);

      dispatcher.removeListener(EventC, listenerA);
    });

    group('.dispatch', () {
      test('Common.', () async {
        dispatcher
          ..addListener(EventA, listenerA)
          ..addListener(EventB, listenerB);

        var event = new EventA();
        expect(await dispatcher.dispatch(event), same(event));
        expect(listenerA.callsAmount, 1);
        expect(listenerB.callsAmount, 0);

        expect(await dispatcher.dispatch(new EventC()), const isInstanceOf<EventC>());


        event = new EventB();
        dispatcher.addListener(EventB, (ev) async {
          expect(ev, same(event));
        });
        expect(await dispatcher.dispatch(event), same(event));
      });

      test('By priority.', () async {
        dispatcher
        ..addListener(EventA, listenerA, priority: -10)
        ..addListener(EventA, listenerB, priority: 10)
        ..addListener(EventA, listenerC);

        await dispatcher.dispatch(new EventA());
        expect(calls, [listenerB, listenerC, listenerA]);
      });

      test('Stop event proppagation.', () async {
        dispatcher
          ..addListener(EventA, listenerA)
          ..addListener(EventA, listenerB..shouldStopPropagation = true)
          ..addListener(EventA, listenerC);

        var event = await dispatcher.dispatch(new EventA());
        expect(calls, [listenerA, listenerB]);
        expect(event.isPropagationStopped, isTrue);
      });

      test('Leazy registration.', () async {
        dispatcher.addListener(EventA, (event) async {
          dispatcher.addListener(event.runtimeType, listenerA);
        });

        await dispatcher.dispatch(new EventA());
        expect(listenerA.callsAmount, 0);

        await dispatcher.dispatch(new EventA());
        expect(listenerA.callsAmount, 1);
      });

      test('Removing of listener by listener', () async {
        dispatcher
          ..addListener(EventA, listenerA)
          ..addListener(EventA, (event) async {
            dispatcher.removeListener(event.runtimeType, listenerA);
          });

        await dispatcher.dispatch(new EventA());
        expect(listenerA.callsAmount, 1);

        await dispatcher.dispatch(new EventA());
        expect(listenerA.callsAmount, 1);
      });
    });
  });
}
