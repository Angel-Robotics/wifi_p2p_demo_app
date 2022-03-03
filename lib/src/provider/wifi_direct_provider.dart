import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_p2p_plus/flutter_p2p_plus.dart';
import 'package:flutter_p2p_plus/protos/protos.pb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_p2p_demo_app/src/model/basic_msg.dart';

final wifiDirectProvider = Provider((ref) => WifiDirectController(ref.read));

final p2pDeviceItemProvider = StateProvider<List<WifiP2pDevice>>((ref) => []);
final p2pSelectedDeviceProvider = StateProvider<WifiP2pDevice?>((ref) => null);
final wifiDiscoveredProvider = StateProvider((ref) => false);

final p2pDeviceConnectionStateProvider = StateProvider((ref) => false);
final p2pDeviceHostCheckProvider = StateProvider((ref) => false);
final p2pDeviceAddressProvider = StateProvider<String?>((ref) => null);

final p2pSocketConnectionStateProvider = StateProvider((ref) => false);

final p2pSocketInputDataProvider = StateProvider<String>((ref) => "");

final p2pSocketInputTimestampProvider = StateProvider<double>((ref) => 0.0);
final p2pSocketInputTimestampAvgProvider = StateProvider<double>((ref) => 0.0);

class WifiDirectController {
  Reader ref;

  WifiDirectController(this.ref);

  final List<StreamSubscription> _subscriptions = [];

  var _isOpen = false;

  // var _socketClientConnected = false;

  P2pSocket? _socket;
  WifiP2pDevice? _wifiP2pDevice;

  // List<WifiP2pDevice> devices = [];

  final FlutterP2pPlus flutterP2pPlus = FlutterP2pPlus.instance;

  StreamSubscription? _socketInputStreamSubscription;
  StreamSubscription? _socketStateStreamSubscription;

  BasicMsg _basicMsg = BasicMsg(msg: "", timestamp: 0);

  Future initP2p() async {
    _subscriptions.add(FlutterP2pPlus.wifiEvents.stateChange!.listen((change) {
      debugPrint("[Listen] stateChange: ${change.isEnabled}");
    }));

    _subscriptions.add(FlutterP2pPlus.wifiEvents.connectionChange!.listen((change) {
      debugPrint("[Listen] connectionChange() ${change.wifiP2pInfo.groupOwnerAddress}");
      ref(p2pDeviceConnectionStateProvider.notifier).state = change.networkInfo.isConnected;
      ref(p2pDeviceHostCheckProvider.notifier).state = change.wifiP2pInfo.isGroupOwner;
      ref(p2pDeviceAddressProvider.notifier).state = change.wifiP2pInfo.groupOwnerAddress;
      // _deviceAddress = change.wifiP2pInfo.groupOwnerAddress;
      debugPrint("[Listen] connectionChange: ${change.wifiP2pInfo.isGroupOwner},"
          " Connected: ${change.networkInfo.isConnected} | _deviceAddress: ${change.wifiP2pInfo.groupOwnerAddress}");
    }));

    _subscriptions.add(FlutterP2pPlus.wifiEvents.thisDeviceChange!.listen((change) {
      debugPrint(
          "[Listen] deviceChange: ${change.deviceName} / ${change.deviceAddress} / ${change.primaryDeviceType} / ${change.secondaryDeviceType} ${change.isGroupOwner ? 'GO' : '-GO'}");
    }));

    _subscriptions.add(FlutterP2pPlus.wifiEvents.discoveryChange!.listen((change) {
      debugPrint("[Listen] discoveryStateChange: ${change.isDiscovering}");
      ref(wifiDiscoveredProvider.notifier).state = change.isDiscovering;
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

  void unregister() {
    _socketInputStreamSubscription?.cancel();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    flutterP2pPlus.unregister();
  }

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

  void _openPortAndAccept(int port) async {
    if (!_isOpen) {
      var _socket = await flutterP2pPlus.openHostPort(port);
      // setState(() {
      //   _socket = socket;
      // });

      var buffer = "";
      _socket?.inputStream.listen((data) {
        var msg = String.fromCharCodes(data.data);
        buffer += msg;
        if (data.dataAvailable == 0) {
          _socket.writeString("Successfully received: $buffer");
          buffer = "";
        }
      });

      debugPrint("_openPort done");
      _isOpen = await flutterP2pPlus.acceptPort(port) ?? false;
      debugPrint("_accept done: $_isOpen");
    }
  }

  connectToPort(int port) async {
    String? _deviceAddress = ref(p2pDeviceAddressProvider);
    print("[Info] _deviceAddress: ${_deviceAddress}");
    var socket = await flutterP2pPlus.connectToHost(
      _deviceAddress ?? "192.168.15.240",
      // "192.168.15.240",
      port,
      timeout: 10000,
    );
    ref(p2pSocketConnectionStateProvider.notifier).state = true;
    _socket = socket;
    // setState(() {
    //   _socketClientConnected = true;
    //   _socket = socket;
    // });
    await _socketInputStreamSubscription?.cancel();
    _socketInputStreamSubscription = null;
    await _socketStateStreamSubscription?.cancel();
    _socketStateStreamSubscription = null;

    _socketInputStreamSubscription ??= socket?.inputStream.listen((data) {
      var msg = utf8.decode(data.data);
      print("[Info][Socket][Input][MSG] :  $msg");
      if(msg.split("}{").length > 1){
        print("============ 데이터 밀려 들어옴 ==============");
      }else{
        try {
          double diffTime = (BasicMsg.fromJson(jsonDecode(msg)).timestamp ?? 0) - (_basicMsg.timestamp ?? 0);
          _basicMsg = BasicMsg.fromJson(jsonDecode(msg));
          ref(p2pSocketInputDataProvider.notifier).state += "$msg - ${DateTime.now()}\n";
          ref(p2pSocketInputTimestampProvider.notifier).state = diffTime;
        } catch (e) {
          print("[Error] ${e.toString()}");
        }
      }
      if (ref(p2pSocketInputDataProvider).length > 5000) {
        ref(p2pSocketInputDataProvider.state).state = "";
      }


      // _rcvText += "$msg \n";
      // setState(() {
      //   _rcvText += "$msg \n";
      // });
      // snackBar("Received from ${_isHost ? "Host" : "Client"} $msg");
    });

    _socketStateStreamSubscription ??= socket?.stateStream.listen((event) {
      debugPrint("[Listen] Socket State: $event");
      ref(p2pSocketConnectionStateProvider.notifier).state = false;
      // setState(() {
      //   _socketClientConnected = false;
      // });
      // showDialog(
      //     context: context,
      //     builder: (context) => const AlertDialog(
      //       content: Text("Socket Host Disconnected"),
      //     ));
    });

    debugPrint("_connectToPort done");
  }

  Future<bool?> socketDisconnect() async {
    debugPrint("[Call] socketDisconnect()");
    bool result = false;
    if (ref(p2pDeviceHostCheckProvider)) {
      await flutterP2pPlus.closeHostPort(8000);
    } else {
      await flutterP2pPlus.disconnectFromHost(8000);
    }
    _socketInputStreamSubscription?.cancel();
    _socketInputStreamSubscription = null;
    ref(p2pSocketConnectionStateProvider.notifier).state = false;
    ref(p2pSocketInputDataProvider.state).state = "";
    // setState(() {
    //   _socketClientConnected = false;
    // });
    // if (_wifiP2pDevice != null) {
    //   result = await FlutterP2pPlus.cancelConnect(_wifiP2pDevice!) ?? false;
    // }

    return result;
  }

  Future<bool?> teardown() async {
    bool? result = await flutterP2pPlus.removeGroup();
    unregister();
    _socket = null;
    if ((result ?? false)) _isOpen = false;
    return result;
  }

  Future<bool> checkPermission() async {
    // if (!await FlutterP2pPlus?.isLocationPermissionGranted()) {
    //   await FlutterP2pPlus.requestLocationPermission();
    //   return false;
    // }
    if (await Permission.location.status.isDenied) {
      return false;
    }
    return true;
  }

  Future<bool> writeString2Host(String data) async {
    bool? result = await _socket?.writeString(data);
    return result ?? false;
  }
}
