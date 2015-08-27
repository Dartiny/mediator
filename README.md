Mediator
========

Component implements the Mediator pattern in a simple and effective way to make your projects extensible.

\* *Inspired by [Symfony Event Dispatcher][1]*

[![Pub version](https://img.shields.io/pub/v/mediator.svg)](https://pub.dartlang.org/packages/mediator)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Dartiny/mediator/blob/master/LICENSE)
[![Coverage Status](https://coveralls.io/repos/Dartiny/mediator/badge.svg?branch=master&service=github)](https://coveralls.io/github/Dartiny/mediator?branch=master)

```dart
import 'package:mediator/mediator.dart';

main() async {
  var dispatcher = new EventDispatcher();
  
  dispatcher.addListener('event-name', (String eventName, Event event) {
  	// ...
  });
  
  var event = await dispatcher.dispatch('event-name');
  
  if (event.isPropagationStopped) {
    // ...
  }
}
```

[1]: https://github.com/symfony/EventDispatcher