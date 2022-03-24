import 'package:flutter/material.dart';
import 'package:flutter_p2p_plus/flutter_p2p_plus.dart';
import 'package:flutter_p2p_plus/protos/protos.pb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_p2p_demo_app/src/provider/backpack_button_provider.dart';
import 'package:wifi_p2p_demo_app/src/provider/emr_button_state_provider.dart';
import 'package:wifi_p2p_demo_app/src/provider/joystick_state_provider.dart';
import 'package:wifi_p2p_demo_app/src/provider/wifi_direct_provider.dart';

class DemoConnectedPage extends ConsumerStatefulWidget {
  DemoConnectedPage({Key? key, required this.device}) : super(key: key);
  WifiP2pDevice device;

  @override
  ConsumerState<DemoConnectedPage> createState() => _DemoConnectedPageState();
}

class _DemoConnectedPageState extends ConsumerState<DemoConnectedPage> {


  Future connectDevice() async {
    print("[Call] connectDevice()");
    FlutterP2pPlus _flutterP2pPlus = ref.read(wifiDirectProvider).flutterP2pPlus;
    print("[Device] : ${widget.device} | ${widget.device.deviceAddress} | "
        "${widget.device.deviceName}");
    try {
      bool? result = await _flutterP2pPlus.connect(widget.device);
      print("[connect] result: $result");
      if (result ?? false) {
        ref.read(p2pDeviceConnectionStateProvider.notifier).state = true;
      }
    } catch (e) {
      ref.read(p2pDeviceConnectionStateProvider.notifier).state = false;
      print(e.toString());
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(e.toString()),
        ),
      );
    }

    // await Future.delayed(const Duration(seconds: 10));
    // await _flutterP2pPlus.stopDiscoverDevices();
    // await Future.delayed(const Duration(seconds: 3));
    print("[Info] Completed connectDevice()");
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connectDevice().then((value) {
      print("ref.read(p2pDeviceAddressProvider): ${ref.read(p2pDeviceAddressProvider)}");
      Future.delayed(const Duration(seconds: 5)).then((value) {
        connectSocket();
      });
    });
  }

  Future connectSocket() async {
    print("[Call] connectSocket()");
    // FlutterP2pPlus _flutterP2pPlus = ref.read(wifiDirectProvider).flutterP2pPlus;
    await ref.read(wifiDirectProvider).connectToPort(8000);
  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.device.deviceName} | ${widget.device.deviceAddress}"),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: const Text("연결을 종료하시겠습니까?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("취소")),
                    TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          // Navigator.of(context).pop();
                          try {
                            await ref.read(wifiDirectProvider).writeString2Host("close");
                          } catch (error, s) {
                            debugPrint("[Error]: ${error.toString()}, ${s.toString()}");
                          }

                          Navigator.of(context).pop();
                        },
                        child: const Text("확인"))
                  ],
                ),
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                  flex: 10,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 100,
                          child: Row(
                            children: [
                              Expanded(
                                child: Consumer(
                                  builder: (BuildContext context, WidgetRef ref, Widget? child) {
                                    final conState = ref.watch(p2pDeviceConnectionStateProvider);
                                    return Container(
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: conState ? Colors.green : Colors.red,
                                      ),
                                      child: const Center(
                                          child: Text(
                                        "디바이스 연결 여부",
                                      )),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: Consumer(
                                  builder: (BuildContext context, WidgetRef ref, Widget? child) {
                                    final conState = ref.watch(p2pSocketConnectionStateProvider);
                                    return Container(
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: conState ? Colors.green : Colors.red,
                                      ),
                                      child: const Center(
                                          child: Text(
                                        "무선 통신 결합 성립",
                                      )),
                                    );
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                        const Divider(color: Colors.black),

                        ListTile(
                          title: const Text("아이피 할당"),
                          trailing: Consumer(
                            builder: (BuildContext context, WidgetRef ref, Widget? child) {
                              final addr = ref.watch(p2pDeviceAddressProvider);
                              return Text(addr ?? "-");
                            },
                          ),
                        ),
                        const Divider(
                          color: Colors.black,
                        ),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  onTap: () async {
                                    await ref.read(wifiDirectProvider).writeString2Host("Hello World");
                                  },
                                  title: const Text(
                                    "테스트 패킷 전달",
                                  ),
                                ),
                              ),
                              const VerticalDivider(
                                color: Colors.black,
                              ),
                              Expanded(
                                child: ListTile(
                                  onTap: () async {
                                    await ref.read(wifiDirectProvider).writeString2Host("start");
                                  },
                                  title: const Text(
                                    "시작",
                                  ),
                                ),
                              ),
                              const VerticalDivider(
                                color: Colors.black,
                              ),
                              Expanded(
                                child: ListTile(
                                  onTap: () async {
                                    await ref.read(wifiDirectProvider).writeString2Host("end");
                                    ref.read(wifiDirectProvider).clearBenchmarkValues();
                                  },
                                  title: const Text(
                                    "종료",
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const Divider(
                          color: Colors.black,
                        ),
                        Consumer(builder: (context, ref, _) {
                          final diff = ref.watch(p2pSocketInputTimestampProvider);
                          final avg = ref.watch(benchmarkPackAvgTime);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "패킷타임: ${diff.toStringAsFixed(8)} s",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "평균: ${avg.toStringAsFixed(8)} s",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "${(diff * 1000).toStringAsFixed(8)} ms",
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }),
                        const Divider(
                          color: Colors.black,
                        ),
                        SizedBox(
                          height: 100,
                          child: Row(
                            children: [
                              Expanded(
                                child: Consumer(
                                  builder: (BuildContext context, WidgetRef ref, Widget? child) {
                                    final emrState = ref.watch(emrButtonStateProvider);
                                    return Container(
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: emrState ? Colors.green : Colors.red,
                                      ),
                                      child: const Center(
                                          child: Text(
                                            "비상버튼",
                                          )),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: Colors.black,
                        ),
                        SizedBox(
                          height: 100,
                          child: Row(
                            children: [
                              Expanded(
                                child: Consumer(
                                  builder: (BuildContext context, WidgetRef ref, Widget? child) {
                                    final backpackState = ref.watch(backpackButtonProvider);
                                    return GridView.count(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 4,
                                      crossAxisSpacing: 4,
                                      children: backpackState
                                          .map((e) => Container(
                                              decoration: BoxDecoration(
                                                color: e ? Colors.red : Colors.green,
                                              ),
                                              child: Text("")))
                                          .toList(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: Colors.black,
                        ),

                      ],
                    ),
                  )),
              Expanded(
                  flex: 7,
                  child: Row(
                    children: [
                      Expanded(
                          child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(),
                        ),
                        child: Column(
                          children: [
                            const Text("Raw Data"),
                            Expanded(child: Consumer(
                              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                                final data = ref.watch(p2pSocketInputDataProvider);
                                return Column(children: [
                                  Row(
                                    children: [
                                      Text(
                                        data.length.toString(),
                                      ),
                                      const SizedBox(
                                        width: 16,
                                      ),
                                      Text(
                                        data.split("\n").length.toString(),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Text(data),
                                    ),
                                  ),
                                ]);
                              },
                            )),
                          ],
                        ),
                      )),
                      Expanded(
                          child: Column(
                        children: [
                          SizedBox(
                            // height: 300,
                            child: Consumer(builder: (context, ref, _) {
                              final joy = ref.watch(joyButtonStateProvider);
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  children: joy
                                      .map(
                                        (e) => Container(
                                          decoration: BoxDecoration(
                                            color: e ? Colors.red : Colors.green,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                            }),
                          ),
                          Consumer(builder: (context, ref, _) {
                            final joy = ref.watch(joyAxisStateProvider);
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                children: joy
                                    .map(
                                      (e) => Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(),
                                        ),
                                        padding: EdgeInsets.all(8),
                                        child: Center(
                                          child: Text(e.toStringAsFixed(8)),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                          }),
                        ],
                      ))
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
