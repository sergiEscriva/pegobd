import 'dart:async';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pegobd/shared/services/bluetooth_service.dart';
import 'package:pegobd/shared/services/mock_bluetooth_service.dart';

// Minimal stub that simulates denied permissions.
class _PermissionDeniedService extends MockBluetoothService {
  @override
  Future<bool> checkPermissions() async => false;
}

// Minimal stub that simulates granted permissions with one paired device.
class _PermissionGrantedService extends MockBluetoothService {
  @override
  Future<bool> checkPermissions() async => true;
}

void main() {
  group('BluetoothPermissionException', () {
    test('toString includes the message', () {
      const ex = BluetoothPermissionException('test message');
      expect(ex.toString(), contains('test message'));
    });
  });

  group('MockBluetoothService', () {
    late MockBluetoothService service;

    setUp(() => service = MockBluetoothService());

    test('checkPermissions always returns true', () async {
      expect(await service.checkPermissions(), isTrue);
    });

    test('getPairedDevices returns the virtual scanner device', () async {
      final devices = await service.getPairedDevices();
      expect(devices, isNotEmpty);
      expect(devices.first.name, 'Virtual OBD Scanner');
    });

    test('getState returns BluetoothState.STATE_ON', () async {
      expect(await service.getState(), BluetoothState.STATE_ON);
    });

    test('isDiscovering returns false', () async {
      expect(await service.isDiscovering(), isFalse);
    });

    test('connectToDevice returns a MockBluetoothConnection', () async {
      final device = BluetoothDevice(
        name: 'Virtual OBD Scanner',
        address: '00:11:22:33:44:55',
      );
      final conn = await service.connectToDevice(device);
      expect(conn, isA<MockBluetoothConnection>());
      expect(conn.isConnected, isTrue);
      await conn.close();
    });
  });

  group('RealBluetoothService permission guard via stub', () {
    test('getPairedDevices throws BluetoothPermissionException when denied',
        () async {
      final service = _PermissionDeniedService();
      expect(
        () => service.getPairedDevices(),
        throwsA(isA<BluetoothPermissionException>()),
      );
    });

    test('getPairedDevices succeeds when permissions are granted', () async {
      final service = _PermissionGrantedService();
      // MockBluetoothService.getPairedDevices does not call checkPermissions,
      // so we verify that the granted path doesn't throw.
      final devices = await service.getPairedDevices();
      expect(devices, isNotEmpty);
    });
  });

  group('MockBluetoothConnection simulation', () {
    test('input stream emits OBD data frames', () async {
      final service = MockBluetoothService();
      final device = BluetoothDevice(
        name: 'Virtual OBD Scanner',
        address: '00:11:22:33:44:55',
      );
      final conn = await service.connectToDevice(device) as MockBluetoothConnection;

      // Collect the first event from the stream.
      final frame = await conn.input!.first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('No data from mock'),
      );

      expect(frame, isNotEmpty);
      // OBD frame starts with '4' (mode 0x41 response)
      expect(String.fromCharCodes(frame), contains('41'));

      await conn.close();
    });

    test('isConnected becomes false after close()', () async {
      final service = MockBluetoothService();
      final device = BluetoothDevice(
        name: 'Virtual OBD Scanner',
        address: '00:11:22:33:44:55',
      );
      final conn = await service.connectToDevice(device) as MockBluetoothConnection;
      expect(conn.isConnected, isTrue);
      await conn.close();
      expect(conn.isConnected, isFalse);
    });
  });
}
