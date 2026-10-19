import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/core/spill.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import '../helpers/app_paths.dart';

class _RecordingListener with ServiceListener {
  final events = <CoreEvent>[];
  final intents = <(bool, DateTime?)>[];

  @override
  void onServiceEvent(CoreEvent event) => events.add(event);

  @override
  void onServiceIntentChanged(bool running, DateTime? startedAt) =>
      intents.add((running, startedAt));
}

class _RecordingStopListener with ServiceListener {
  var stops = 0;

  @override
  void onServiceStopped() => stops++;
}

class _ThrowingListener with ServiceListener {
  var called = false;

  @override
  void onServiceEvent(CoreEvent event) {
    called = true;
    throw StateError('listener boom');
  }

  @override
  void onServiceStopped() {
    throw StateError('listener boom');
  }
}

class _MutatingListener with ServiceListener {
  final ServiceListener target;

  _MutatingListener(this.target);

  @override
  void onServiceEvent(CoreEvent event) {
    Service().removeListener(target);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = '$packageName/service';
  const channel = MethodChannel(channelName);
  const coreChannel = MethodChannel('$packageName/core');
  const codec = StandardMethodCodec();

  late List<MethodCall> calls;

  void mockChannel(
    Future<Object?>? Function(MethodCall call) handler, {
    MethodChannel target = channel,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(target, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  void mockCoreChannel(Future<Object?>? Function(MethodCall call) handler) =>
      mockChannel(handler, target: coreChannel);

  Future<void> emitFromPlatform(Object? arguments) async {
    final payload = json.encode(
      CoreMethodCall(method: CoreMethod.message, arguments: arguments).toJson(),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channelName,
          codec.encodeMethodCall(MethodCall('event', utf8.encode(payload))),
          null,
        );
  }

  setUp(() {
    calls = <MethodCall>[];
  });

  tearDown(() {
    for (final target in [channel, coreChannel]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(target, null);
    }
  });

  test('is a singleton so the platform handler is installed once', () {
    expect(Service(), same(Service()));
  });

  group('lifecycle commands', () {
    test('start and stop report the platform result', () async {
      mockChannel((call) async => call.method == 'start');

      expect(await Service().start(), isTrue);
      expect(await Service().stop(), isFalse);
      expect(calls.map((call) => call.method), ['start', 'stop']);
    });

    test('an absent start or stop result is treated as failure', () async {
      mockChannel((_) async => null);

      expect(await Service().start(), isFalse);
      expect(await Service().stop(), isFalse);
    });

    test('an absent shutdown result is treated as success', () async {
      mockChannel((_) async => null);

      expect(
        await Service().shutdown(),
        isTrue,
        reason:
            'shutdown defaults the opposite way from start/stop: a service '
            'that cannot answer is already gone',
      );
    });

    test('init and syncState fall back to an empty payload', () async {
      mockChannel((_) async => null);

      expect(await Service().init(), isEmpty);
      expect(
        await Service().syncState(
          const SharedState(
            stopTip: 'stopTip',
            startTip: 'startTip',
            localNetworkTip: 'localNetworkTip',
            currentProfileName: 'profile',
            stopText: 'stop',
            onlyStatisticsProxy: false,
          ),
        ),
        isEmpty,
      );
    });

    test('syncState sends the encoded shared state', () async {
      mockChannel((_) async => 'ok');
      const state = SharedState(
        stopTip: 'stopTip',
        startTip: 'startTip',
        localNetworkTip: 'localNetworkTip',
        currentProfileName: 'profile',
        stopText: 'stop',
        onlyStatisticsProxy: true,
      );

      expect(await Service().syncState(state), 'ok');

      final sent = json.decode(calls.single.arguments as String);
      expect(sent['currentProfileName'], 'profile');
      expect(sent['onlyStatisticsProxy'], isTrue);
    });
  });

  group('native run state', () {
    Future<void> report(
      ServiceRunState state,
      int revision, {
      bool external = false,
      bool requested = false,
      int? startedAtMillis,
    }) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            codec.encodeMethodCall(
              MethodCall('runState', {
                'state': state.name,
                'revision': revision,
                'external': external,
                'requested': requested,
                'startedAtMillis': startedAtMillis,
              }),
            ),
            null,
          );
    }

    setUp(() => mockChannel((_) async => true));

    test('a native quick action can start after a Flutter stop', () async {
      final listener = _RecordingListener();
      Service().addListener(listener);
      addTearDown(() => Service().removeListener(listener));
      await Service().stop();
      final revision = calls.last.arguments as int;
      final commands = calls.length;
      await report(
        ServiceRunState.started,
        revision,
        external: true,
        requested: true,
        startedAtMillis: 1700000000000,
      );
      expect(Service().runState, ServiceRunState.started);
      expect(listener.intents, [
        (true, DateTime.fromMillisecondsSinceEpoch(1700000000000)),
      ]);
      expect(calls, hasLength(commands));
    });

    test('a newer Flutter command rejects a queued external report', () async {
      final listener = _RecordingListener();
      Service().addListener(listener);
      addTearDown(() => Service().removeListener(listener));
      await Service().stop();
      final old = calls.last.arguments as int;
      await Service().start();
      await report(ServiceRunState.stopped, old, external: true);
      expect(Service().runState, ServiceRunState.starting);
      expect(listener.intents, isEmpty);
    });

    test('accepting a start is not native readiness', () async {
      await Service().start();
      expect(Service().runState, ServiceRunState.starting);
      await report(ServiceRunState.started, calls.last.arguments as int);
      expect(Service().runState, ServiceRunState.started);
    });

    test('stop waits for teardown and rejects a late ready report', () async {
      await Service().start();
      final start = calls.last.arguments as int;
      await report(ServiceRunState.started, start);
      await Service().stop();
      final stop = calls.last.arguments as int;
      expect(Service().runState, ServiceRunState.stopping);
      await report(ServiceRunState.started, start);
      await report(ServiceRunState.started, stop);
      expect(Service().runState, ServiceRunState.stopping);
      await report(ServiceRunState.stopped, stop);
      expect(Service().runState, ServiceRunState.stopped);
    });

    test('rapid stop-start does not reuse the previous ready state', () async {
      await Service().start();
      await report(ServiceRunState.started, calls.last.arguments as int);
      await Service().stop();
      final stale = calls.last.arguments as int;
      await Service().start();
      final newest = calls.last.arguments as int;
      expect(Service().runState, ServiceRunState.starting);
      await report(ServiceRunState.stopped, stale);
      expect(Service().runState, ServiceRunState.starting);
      await report(ServiceRunState.started, newest);
      expect(Service().runState, ServiceRunState.started);
    });

    test('a refused or throwing start leaves no pending spinner', () async {
      mockChannel((_) async => false);
      expect(await Service().start(), isFalse);
      expect(Service().runState, ServiceRunState.stopped);
      mockChannel((_) async => throw PlatformException(code: 'start_failed'));
      await expectLater(Service().start(), throwsA(isA<PlatformException>()));
      expect(Service().runState, ServiceRunState.stopped);
    });

    test('an old failing command cannot undo a newer ready service', () async {
      final pending = Completer<bool>();
      var starts = 0;
      mockChannel((call) async {
        if (call.method == 'start' && starts++ == 0) return pending.future;
        return true;
      });
      final oldStart = Service().start();
      await Service().stop();
      await Service().start();
      await report(ServiceRunState.started, calls.last.arguments as int);
      final failure = expectLater(oldStart, throwsA(isA<PlatformException>()));
      pending.completeError(PlatformException(code: 'old_start_failed'));
      await failure;
      expect(Service().runState, ServiceRunState.started);
    });

    test(
      'a native ready report survives a later acknowledgement error',
      () async {
        final pending = Completer<bool>();
        mockChannel((_) => pending.future);
        final start = Service().start();
        await Future<void>.delayed(Duration.zero);
        await report(ServiceRunState.started, calls.last.arguments as int);
        final failure = expectLater(start, throwsA(isA<PlatformException>()));
        pending.completeError(PlatformException(code: 'reply_failed'));
        await failure;
        expect(Service().runState, ServiceRunState.started);
      },
    );
  });

  group('stop reports', () {
    late _RecordingStopListener listener;

    Future<void> reportStopped(Object? revision) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            codec.encodeMethodCall(MethodCall('stopped', revision)),
            null,
          );
    }

    int lastRevision() => calls.last.arguments as int;

    setUp(() {
      mockChannel((_) async => true);
      listener = _RecordingStopListener();
      Service().addListener(listener);
    });

    tearDown(() => Service().removeListener(listener));

    test('every command carries a revision newer than the last', () async {
      await Service().start();
      final first = lastRevision();
      await Service().stop();

      expect(lastRevision(), greaterThan(first));
    });

    test(
      'a report for the start in force reaches the listeners once',
      () async {
        await Service().start();

        await reportStopped(lastRevision());
        await reportStopped(lastRevision());

        expect(listener.stops, 1);
      },
    );

    test('a report older than the newest command is dropped', () async {
      await Service().start();
      final stale = lastRevision();
      await Service().stop();
      await Service().start();

      await reportStopped(stale);

      expect(listener.stops, 0);
    });

    test(
      'a report is dropped while Flutter itself asked for the stop',
      () async {
        await Service().start();
        await Service().stop();

        await reportStopped(lastRevision());

        expect(listener.stops, 0);
      },
    );

    test('a throwing listener does not starve the next one', () async {
      final throwing = _ThrowingListener();
      Service().removeListener(listener);
      Service().addListener(throwing);
      Service().addListener(listener);
      addTearDown(() => Service().removeListener(throwing));
      await Service().start();

      await reportStopped(lastRevision());

      expect(listener.stops, 1);
    });
  });

  group('getRunTime', () {
    test('maps a millisecond stamp to a DateTime', () async {
      final stamp = DateTime.utc(2026, 8, 16).millisecondsSinceEpoch;
      mockChannel((_) async => stamp);

      expect(
        await Service().getRunTime(),
        DateTime.fromMillisecondsSinceEpoch(stamp),
      );
    });

    test('treats zero and a missing stamp as not running', () async {
      mockChannel((_) async => 0);
      expect(await Service().getRunTime(), isNull);

      mockChannel((_) async => null);
      expect(await Service().getRunTime(), isNull);
    });
  });

  group('invokeMethod', () {
    test('encodes the call and decodes the response envelope', () async {
      mockCoreChannel(
        (_) async => utf8.encode(
          json.encode(
            const CoreMethodResponse(id: '7', result: {'up': 1}).toJson(),
          ),
        ),
      );

      final response = await Service().invokeMethod(
        const CoreMethodCall(
          id: '7',
          method: CoreMethod.getTraffic,
          arguments: true,
        ),
      );

      final sent =
          json.decode(calls.single.arguments as String) as Map<String, Object?>;
      expect(calls.single.method, 'invokeMethod');
      expect(sent['id'], '7');
      expect(sent['method'], CoreMethod.getTraffic.name);
      expect(
        sent['arguments'],
        isTrue,
        reason: 'arguments stay structured JSON, never a pre-encoded string',
      );
      expect(response!.id, '7');
      expect(response.result, {'up': 1});
      expect(response.error, isNull);
    });

    test('decodes a large UTF-8 envelope off the calling isolate', () async {
      final names = List.generate(5000, (index) => '节点-$index');
      mockCoreChannel(
        (_) async => utf8.encode(
          json.encode(CoreMethodResponse(id: '3', result: names).toJson()),
        ),
      );

      final response = await Service().invokeMethod(
        const CoreMethodCall(id: '3', method: CoreMethod.getProxies),
      );

      expect(response!.result, names);
    });

    test('reads an envelope the Core spilled to a file', () async {
      final home = Directory.systemTemp.createTempSync('service_spill');
      addTearDown(() => home.deleteSync(recursive: true));
      await useAppPaths(home);
      final file = File(join(home.path, coreSpillDirectoryName, '1.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          json.encode(
            const CoreMethodResponse(id: '8', result: 'big').toJson(),
          ),
        );
      mockCoreChannel(
        (_) async => utf8.encode(
          json.encode(CoreMethodResponse(id: '8', file: file.path).toJson()),
        ),
      );

      final response = await Service().invokeMethod(
        const CoreMethodCall(id: '8', method: CoreMethod.getConfig),
      );

      expect(response!.result, 'big');
      expect(file.existsSync(), isFalse);
    });

    test('returns null when the platform sends no envelope', () async {
      mockCoreChannel((_) async => null);

      expect(
        await Service().invokeMethod(
          const CoreMethodCall(method: CoreMethod.getTraffic),
        ),
        isNull,
      );
    });

    test('surfaces a Core error inside the envelope', () async {
      mockCoreChannel(
        (_) async => utf8.encode(
          json.encode({
            'id': '1',
            'result': null,
            'error': {'code': 'unavailable', 'message': 'core down'},
          }),
        ),
      );

      final response = await Service().invokeMethod(
        const CoreMethodCall(id: '1', method: CoreMethod.getTraffic),
      );

      expect(response!.error, isNotNull);
      expect(response.error!.code, 'unavailable');
      expect(response.error!.message, 'core down');
    });
  });

  group('event dispatch', () {
    test('fans a batched event list out to every listener', () async {
      final first = _RecordingListener();
      final second = _RecordingListener();
      Service().addListener(first);
      Service().addListener(second);
      addTearDown(() {
        Service().removeListener(first);
        Service().removeListener(second);
      });

      await emitFromPlatform([
        {'type': CoreEventType.crash.name, 'data': 'boom'},
        {'type': CoreEventType.loaded.name, 'data': 'provider'},
      ]);

      for (final listener in [first, second]) {
        expect(listener.events.map((event) => event.type), [
          CoreEventType.crash,
          CoreEventType.loaded,
        ]);
        expect(listener.events.first.data, 'boom');
      }
    });

    test('accepts a single event object as well as a list', () async {
      final listener = _RecordingListener();
      Service().addListener(listener);
      addTearDown(() => Service().removeListener(listener));

      await emitFromPlatform({
        'type': CoreEventType.crash.name,
        'data': 'boom',
      });

      expect(listener.events.single.type, CoreEventType.crash);
    });

    test('a throwing listener does not starve the others', () async {
      final throwing = _ThrowingListener();
      final healthy = _RecordingListener();
      Service().addListener(throwing);
      Service().addListener(healthy);
      addTearDown(() {
        Service().removeListener(throwing);
        Service().removeListener(healthy);
      });

      await emitFromPlatform([
        {'type': CoreEventType.crash.name, 'data': 'boom'},
      ]);

      expect(throwing.called, isTrue);
      expect(healthy.events.single.type, CoreEventType.crash);
    });

    test('mutating listeners during dispatch does not throw', () async {
      final second = _RecordingListener();
      final mutating = _MutatingListener(second);
      Service().addListener(mutating);
      Service().addListener(second);
      addTearDown(() {
        Service().removeListener(mutating);
        Service().removeListener(second);
      });

      await expectLater(
        emitFromPlatform([
          {'type': CoreEventType.crash.name, 'data': 'boom'},
        ]),
        completes,
      );
    });

    test('an unparsable event is dropped without losing the batch', () async {
      final listener = _RecordingListener();
      Service().addListener(listener);
      addTearDown(() => Service().removeListener(listener));

      await emitFromPlatform([
        {'type': 'notAnEventType'},
        {'type': CoreEventType.crash.name, 'data': 'boom'},
      ]);

      expect(listener.events.single.type, CoreEventType.crash);
    });

    test('a removed listener stops receiving events', () async {
      final listener = _RecordingListener();
      Service().addListener(listener);
      expect(Service().hasListeners, isTrue);
      Service().removeListener(listener);
      expect(Service().hasListeners, isFalse);

      await emitFromPlatform([
        {'type': CoreEventType.crash.name, 'data': 'boom'},
      ]);

      expect(listener.events, isEmpty);
    });

    test('an unknown platform method is reported as unimplemented', () async {
      final unknown = await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            codec.encodeMethodCall(const MethodCall('nope')),
            null,
          );
      final known = await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            codec.encodeMethodCall(MethodCall('event', Uint8List(0))),
            null,
          );

      expect(
        unknown,
        isNull,
        reason:
            'the handler throws MissingPluginException, which a method channel '
            'answers with a null reply rather than an error envelope',
      );
      expect(known, isNotNull);
    });
  });
}
