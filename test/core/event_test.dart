// Copyright (c) 2015, the package authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

library mediator.test.core.event;

import 'package:test/test.dart';
import 'package:mediator/mediator.dart';

class TestEvent extends Event {}

void main() {
  group('Event', () {
    test('.stopPropagation()', () {
      var event = new TestEvent();
      expect(event.isPropagationStopped, isFalse);

      event.stopPropagation();
      expect(event.isPropagationStopped, isTrue);
    });
  });
}
