// Copyright (c) 2015, the package authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library mediator.test.event_dispatcher;

import 'dart:async' show Future;
import 'package:test/test.dart';
import 'package:mediator/mediator.dart';

const EVENT_A = 'event_a';
const EVENT_B = 'event_b';

class TestEventListener {
  bool shouldStopPropagation = false;
  int callsAmount = 0;
  final List<EventListener> _calls;

  TestEventListener(this._calls);

  Future call(String eventName, Event event) async {
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
      expect(dispatcher.hasListeners(EVENT_A), isFalse);
      expect(dispatcher.hasListeners(EVENT_B), isFalse);

      expect(dispatcher.getListeners(EVENT_A), hasLength(0));
      expect(dispatcher.getListeners(EVENT_B), hasLength(0));
    });

    test('.addListener()', () {
      dispatcher
        ..addListener(EVENT_A, listenerA)
        ..addListener(EVENT_B, listenerA)
        ..addListener(EVENT_B, listenerB);

      expect(dispatcher.hasListeners(EVENT_A), isTrue);
      expect(dispatcher.hasListeners(EVENT_B), isTrue);

      expect(dispatcher.getListeners(EVENT_A), hasLength(1));
      expect(dispatcher.getListeners(EVENT_B), hasLength(2));
    });

    test('.getListeners() Sortes by priority.', () {
      dispatcher
        ..addListener(EVENT_A, listenerA, priority: -10)
        ..addListener(EVENT_A, listenerB, priority: 10)
        ..addListener(EVENT_A, listenerC);

      expect(dispatcher.getListeners(EVENT_A), equals([listenerB, listenerC, listenerA]));
    });

    test('.removeListener()', () {
      dispatcher.addListener(EVENT_A, listenerA);
      expect(dispatcher.hasListeners(EVENT_A), isTrue);

      dispatcher.removeListener(EVENT_A, listenerA);
      expect(dispatcher.hasListeners(EVENT_A), isFalse);

      dispatcher.removeListener('not-exists', listenerA);
    });

    group('.dispatch', () {
      test('Common.', () async {
        dispatcher
          ..addListener(EVENT_A, listenerA)
          ..addListener(EVENT_B, listenerB);

        await dispatcher.dispatch(EVENT_A);
        expect(listenerA.callsAmount, 1);
        expect(listenerB.callsAmount, 0);

        expect(await dispatcher.dispatch('no_event'), const isInstanceOf<Event>());
        expect(await dispatcher.dispatch(EVENT_A), const isInstanceOf<Event>());

        var event = new Event();
        dispatcher.addListener(EVENT_B, (name, ev) async {
          expect(name, EVENT_B);
          expect(ev, same(event));
        });
        expect(await dispatcher.dispatch(EVENT_B, event), same(event));
      });

      test('By priority.', () async {
        dispatcher
          ..addListener(EVENT_A, listenerA, priority: -10)
          ..addListener(EVENT_A, listenerB, priority: 10)
          ..addListener(EVENT_A, listenerC);

        await dispatcher.dispatch(EVENT_A);
        expect(calls, [listenerB, listenerC, listenerA]);
      });

      test('Stop event proppagation.', () async {
        dispatcher
          ..addListener(EVENT_A, listenerA)
          ..addListener(EVENT_A, listenerB..shouldStopPropagation = true)
          ..addListener(EVENT_A, listenerC);

        var returned = await dispatcher.dispatch(EVENT_A);
        expect(calls, [listenerA, listenerB]);
        expect(returned.isPropagationStopped, isTrue);
      });

      test('Leazy registration.', () async {
        dispatcher.addListener(EVENT_A, (name, _) async {
          dispatcher.addListener(name, listenerA);
        });

        await dispatcher.dispatch(EVENT_A);
        expect(listenerA.callsAmount, 0);

        await dispatcher.dispatch(EVENT_A);
        expect(listenerA.callsAmount, 1);
      });

      test('Removing of listener by listener', () async {
        dispatcher
          ..addListener(EVENT_A, listenerA)
          ..addListener(EVENT_A, (name, _) async {
            dispatcher.removeListener(name, listenerA);
          });

        await dispatcher.dispatch(EVENT_A);
        expect(listenerA.callsAmount, 1);

        await dispatcher.dispatch(EVENT_A);
        expect(listenerA.callsAmount, 1);
      });
    });
  });
}
