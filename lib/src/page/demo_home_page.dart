import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_p2p_plus/flutter_p2p_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_p2p_demo_app/src/provider/wifi_direct_provider.dart';
import 'package:wifi_p2p_demo_app/src/service/permission_api.dart';

class DemoHomePage extends ConsumerStatefulWidget {
  const DemoHomePage({Key? key}) : super(key: key);

  @override
  _DemoHomePageState createState() => _DemoHomePageState();
}

class _DemoHomePageState extends ConsumerState<DemoHomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    requestPermissions().then((value) {
      if (value == PermissionStatus.granted) {
        ref.read(wifiDirectProvider).initP2p();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(wifiDirectProvider).initP2p();
    } else if (state == AppLifecycleState.paused) {
      ref.read(wifiDirectProvider).unregister();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      appBar: AppBar(
        title: const Text("Wi-Fi Direct Demo"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final _devices = ref.watch(p2pDeviceItemProvider);
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    children: _devices
                        .map(
                          (e) => GestureDetector(
                            onTap: () async {
                              if (e.deviceName != "javier") {
                                return;
                              }
                              showDialog(context: context, builder: (context)=>
                              AlertDialog(
                                title: Text("안내"),
                                content: Text("${e.deviceName} (${e.deviceAddress})를 연결할까요?"),
                                actions: [

                                ],
                              ));
                            },
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Lottie.asset(
                                      'assets/lottie/41617-chatbot.json',
                                      height: 240,
                                    ),
                                    Text(
                                      e.deviceName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      e.deviceAddress,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final isDiscovered = ref.watch(wifiDiscoveredProvider);

          return FloatingActionButton(
            onPressed: () async {
              if (isDiscovered) {
                await FlutterP2pPlus.instance.stopDiscoverDevices();
              } else {
                await FlutterP2pPlus.instance.discoverDevices();
              }
              ref.read(wifiDiscoveredProvider.notifier).state = !isDiscovered;
            },
            backgroundColor: isDiscovered ? Colors.red : Colors.green,
            child: isDiscovered ? const Icon(Icons.remove) : const Icon(Icons.search),
          );
        },
      ),
    );
  }
}
