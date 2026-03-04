import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

void main() {
  runApp(const RoverApp());
}

class RoverApp extends StatelessWidget {
  const RoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RoverRemote(),
    );
  }
}

class RoverRemote extends StatefulWidget {
  const RoverRemote({super.key});

  @override
  State<RoverRemote> createState() => _RoverRemoteState();
}

class _RoverRemoteState extends State<RoverRemote>
    with SingleTickerProviderStateMixin {
  double angle = 0;
  String steeringDirection = "CENTER";
  String currentStatus = "IDLE";
  String? pressedButton;
  BluetoothConnection? connection;
  List<BluetoothDevice> roverDevices = [];

  StreamSubscription<BluetoothDiscoveryResult>? discoverySubscription;

  bool isConnected = false;
  int speed = 0;
  int battery = 100;

  Timer? batteryTimer;

  late AnimationController _returnController;
  late Animation<double> _returnAnimation;

  @override
  void initState() {
    super.initState();

    // Smooth return controller
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _returnController.addListener(() {
      setState(() {
        angle = _returnAnimation.value;
      });
    });

    // Dummy battery drain
    batteryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (battery > 0) {
        setState(() => battery--);
      }
    });
  }

  @override
  void dispose() {
    batteryTimer?.cancel();
    discoverySubscription?.cancel();
    connection?.dispose();
    _returnController.dispose();
    super.dispose();
  }

  Future<void> connectBluetooth() async {
    try {
      // If already connected → disconnect
      if (isConnected) {
        await connection?.close();
        setState(() {
          isConnected = false;
        });
        return;
      }

      List<BluetoothDiscoveryResult> discoveredDevices = [];

      discoverySubscription =
          FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
            if (!discoveredDevices
                .any((d) => d.device.address == r.device.address)) {
              discoveredDevices.add(r);
            }
          });

      await Future.delayed(const Duration(seconds: 5));
      await discoverySubscription?.cancel();

      if (discoveredDevices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No Devices Found")),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: discoveredDevices.length,
              itemBuilder: (context, index) {
                final device = discoveredDevices[index].device;

                return ListTile(
                  leading: const Icon(Icons.bluetooth,
                      color: Colors.cyanAccent),
                  title: Text(
                    device.name ?? "Unknown Device",
                    style:
                    const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    device.address,
                    style:
                    const TextStyle(color: Colors.grey),
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    try {
                      connection =
                      await BluetoothConnection.toAddress(
                          device.address);

                      setState(() {
                        isConnected = true;
                      });

                      connection!.input!
                          .listen((Uint8List data) {
                        print("Incoming: ${String.fromCharCodes(data)}");
                      }).onDone(() {
                        setState(() {
                          isConnected = false;
                        });
                      });
                    } catch (e) {
                      print("Connection error: $e");
                    }
                  },
                );
              },
            ),
          );
        },
      );
    } catch (e) {
      print("Bluetooth Error: $e");
    }
  }
  void sendCommand(String cmd) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(
        Uint8List.fromList("$cmd\n".codeUnits),
      );
      connection!.output.allSent;
    }

    setState(() {
      currentStatus = cmd.toUpperCase();

      if (cmd == "forward") speed = 40;
      if (cmd == "backward") speed = 25;
      if (cmd == "stop") speed = 0;
    });

    print("COMMAND: $cmd");
  }

  // ================= STEERING =================

  Widget steeringWheel(double size) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          angle += details.delta.dx * 0.01;

          if (angle > 0.6) angle = 0.6;
          if (angle < -0.6) angle = -0.6;

          if (angle > 0.2) {
            steeringDirection = "RIGHT";
          } else if (angle < -0.2) {
            steeringDirection = "LEFT";
          } else {
            steeringDirection = "CENTER";
          }

          print("STEERING ANGLE: ${angle.toStringAsFixed(2)}");
          print("STEERING DIR: $steeringDirection");
        });
      },
      onPanEnd: (_) {
        _returnAnimation = Tween<double>(
          begin: angle,
          end: 0,
        ).animate(
          CurvedAnimation(
            parent: _returnController,
            curve: Curves.easeOutCubic,
          ),
        );

        _returnController.forward(from: 0);

        steeringDirection = "CENTER";
        print("SMOOTH RETURN TO CENTER");
      },
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF4A4A4A),
                Color(0xFF1C1C1C),
                Colors.black
              ],
              stops: [0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.9),
                blurRadius: 30,
                spreadRadius: 8,
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [

              // Outer Ring
              Container(
                width: size * 0.92,
                height: size * 0.92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade800,
                    width: 8,
                  ),
                ),
              ),

              // Bottom Spoke
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: size * 0.14,
                  height: size * 0.45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.grey, Colors.black],
                    ),
                  ),
                ),
              ),

              // Left Spoke
              Transform.rotate(
                angle: 2.3,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.55,
                  color: Colors.grey.shade800,
                ),
              ),

              // Right Spoke
              Transform.rotate(
                angle: -2.3,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.55,
                  color: Colors.grey.shade800,
                ),
              ),

              // Center Hub
              Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.black,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.7),
                      blurRadius: 15,
                      spreadRadius: 3,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget neonButton(String text, String cmd,
      {Color color = Colors.cyan, bool big = true}) {

    bool isPressed = pressedButton == cmd;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressedButton = cmd;
        });
        sendCommand(cmd);
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() {
          pressedButton = null;
        });
        sendCommand("stop");   // 🔥 Safety stop
      },
      onTapCancel: () {
        setState(() {
          pressedButton = null;
        });
        sendCommand("stop");   // 🔥 Safety stop
      },
      child: Container(
        width: big ? 95 : 75,
        height: big ? 95 : 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPressed ? color : null,
          gradient: isPressed
              ? null
              : RadialGradient(
            colors: [color.withOpacity(0.8), Colors.black],
          ),
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: isPressed ? 5 : 20,
              spreadRadius: isPressed ? 1 : 3,
            )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isPressed ? Colors.black : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget statusPanel() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Bluetooth: ",
                style: TextStyle(color: Colors.white)),
            Icon(
              Icons.circle,
              color: isConnected ? Colors.green : Colors.red,
              size: 14,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text("Speed: $speed km/h",
            style:
            const TextStyle(color: Colors.cyanAccent, fontSize: 16)),
        const SizedBox(height: 4),
        Text("Battery: $battery%",
            style:
            const TextStyle(color: Colors.orangeAccent, fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.65;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "ROVER CONTROL",
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            ElevatedButton(
              onPressed: connectBluetooth,
              child: Text(isConnected
                  ? "Disconnect"
                  : "Connect Bluetooth"),
            ),

            steeringWheel(size),

            statusPanel(),

            Column(
              children: [
                neonButton("F", "forward"),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    neonButton("L", "left"),
                    const SizedBox(width: 25),
                    neonButton("STOP", "stop",
                        color: Colors.redAccent, big: true),
                    const SizedBox(width: 25),
                    neonButton("R", "right"),
                  ],
                ),
                const SizedBox(height: 20),
                neonButton("B", "backward"),
                const SizedBox(height: 45),
              ],
            ),
          ],
        ),
      ),
    );
  }
}