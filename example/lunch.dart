// Copyright (c) 2015, the package authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'package:mediator/mediator.dart';

main() async {
  final dispatcher = new EventDispatcher();

  // Register listener for 'new_order' event:
  dispatcher.addListener('new_order', orderCostLimitListener);

  // Receive some order:
  var order = new Order('Roman', 'cleaning', 10000);

  // Dispatch event about new order:
  var event = await dispatcher.dispatch('new_order', new OrderEvent(order));
  if (!event.isPropagationStopped) {
    // Complete order...
  }
}

class Order {
  final String customer;
  final String service;
  final int cost;

  Order(this.customer, this.service, this.cost);
}

class OrderEvent extends Event {
  final Order order;

  OrderEvent(this.order);
}

Future orderCostLimitListener(String eventName, OrderEvent event) async {
  var order = event.order;

  if (order.cost > 100000) {
    // Prevent orders with cost > $1000
    event.stopPropagation();
  }
}
