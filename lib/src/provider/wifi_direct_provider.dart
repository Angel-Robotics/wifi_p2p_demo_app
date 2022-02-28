import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_p2p_plus/flutter_p2p_plus.dart';
import 'package:flutter_p2p_plus/protos/protos.pb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final p2pDeviceItemProvider = StateProvider<List<WifiP2pDevice>>((ref) => []);
final wifiDiscoveredProvider = StateProvider((ref) => false);
final wifiDirectProvider = Provider((ref) => WifiDirectController(ref.read));
final p2pDeviceConnectionStateProvider = StateProvider((ref) => false);
final p2pDeviceHostCheckProvider = StateProvider((ref) => false);

class WifiDirectController {
  Reader ref;

  WifiDirectController(this.ref);

  final List<StreamSubscription> _subscriptions = [];
  var _deviceAddress = "";
  // var _isConnected = false;
  // var _isHost = false;
  var _isOpen = false;
  var _socketClientConnected = false;

  P2pSocket? _socket;
  WifiP2pDevice? _wifiP2pDevice;
  List<WifiP2pDevice> devices = [];

  final FlutterP2pPlus flutterP2pPlus = FlutterP2pPlus.instance;

  StreamSubscription? _socketInputStreamSubscription;
  StreamSubscription? _socketStateStreamSubscription;

  Future dispose() async {
    _socketInputStreamSubscription?.cancel();
    _socketStateStreamSubscription?.cancel();
    flutterP2pPlus.removeGroup();
    for (var element in _subscriptions) {
      element.cancel();
    }
    if (ref(p2pDeviceConnectionStateProvider)) {
      if (_wifiP2pDevice != null) {
        FlutterP2pPlus.instance.cancelConnect(_wifiP2pDevice!);
      }
    }
  }

  void unregister() {
    _socketInputStreamSubscription?.cancel();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    flutterP2pPlus.unregister();
  }

  void _openPortAndAccept(int port) async {
    if (!_isOpen) {
      var socket = await flutterP2pPlus.openHostPort(port);
      // setState(() {
      //   _socket = socket;
      // });

      var buffer = "";
      socket?.inputStream.listen((data) {
        var msg = String.fromCharCodes(data.data);
        buffer += msg;
        if (data.dataAvailable == 0) {
          socket.writeString("Successfully received: $buffer");
          buffer = "";
        }
      });

      debugPrint("_openPort done");
      _isOpen = await flutterP2pPlus.acceptPort(port) ?? false;
      debugPrint("_accept done: $_isOpen");
    }
  }

  void initP2p() async {
    _subscriptions.add(FlutterP2pPlus.wifiEvents.stateChange!.listen((change) {
      debugPrint("[Listen] stateChange: ${change.isEnabled}");
    }));

    _subscriptions.add(FlutterP2pPlus.wifiEvents.connectionChange!.listen((change) {
      debugPrint("[Listen] connectionChange() ${change.wifiP2pInfo.groupOwnerAddress}");
      ref(p2pDeviceConnectionStateProvider.notifier).state = change.networkInfo.isConnected;
      ref(p2pDeviceHostCheckProvider.notifier).state = change.wifiP2pInfo.isGroupOwner;
      _deviceAddress = change.wifiP2pInfo.groupOwnerAddress;

      debugPrint(
          "[Listen] connectionChange: ${change.wifiP2pInfo.isGroupOwner}, Connected: ${change.networkInfo.isConnected} | _deviceAddress: ${_deviceAddress}");
    }));

    _subscriptions.add(FlutterP2pPlus.wifiEvents.thisDeviceChange!.listen((change) {
      debugPrint(
          "[Listen] deviceChange: ${change.deviceName} / ${change.deviceAddress} / ${change.primaryDeviceType} / ${change.secondaryDeviceType} ${change.isGroupOwner ? 'GO' : '-GO'}");
    }));

    _subscriptions.add(FlutterP2pPlus.wifiEvents.discoveryChange!.listen((change) {
      debugPrint("[Listen] discoveryStateChange: ${change.isDiscovering}");
    }));

    _subscriptions.add(FlutterP2pPlus.wifiEvents.peersChange!.listen((change) {
      debugPrint("[Listen] peersChange: ${change.devices.length}");
      // for (var device in change.devices) {
      //   debugPrint("device: ${device.deviceName} / ${device.deviceAddress}");
      // }
      ref(p2pDeviceItemProvider.notifier).state = change.devices;
    }));

    await flutterP2pPlus.register();
    await flutterP2pPlus.discoverDevices();

    ref(wifiDiscoveredProvider.notifier).state = true;
  }
}
