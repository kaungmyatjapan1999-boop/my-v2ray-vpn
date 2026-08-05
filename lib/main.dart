import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaterialApp(home: VpnHome(), debugShowCheckedModeBanner: false));

class VpnHome extends StatefulWidget {
  const VpnHome({super.key});
  @override
  State<VpnHome> createState() => _VpnHomeState();
}

class _VpnHomeState extends State<VpnHome> {
  late FlutterV2ray v2ray;
  bool isConnected = false;
  String status = "DISCONNECTED";
  String savedConfig = "";

  @override
  void initState() {
    super.initState();
    v2ray = FlutterV2ray(onStatusChanged: (s) => setState(() {
      status = s.state.toUpperCase();
      isConnected = s.state == "connected";
    }));
    v2ray.initializeV2Ray();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => savedConfig = prefs.getString('v2ray_config') ?? "");
  }

  Future<void> updateConfig() async {
    try {
      final url = 'https://gist.githubusercontent.com/kaungmyatjapan1999-boop/e1f6ac00358d042d58d49a8547eccc9b/raw/config.txt';
      final r = await http.get(Uri.parse(url));
      if (r.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('v2ray_config', r.body.trim());
        setState(() => savedConfig = r.body.trim());
      }
    } catch (e) {
      print(e);
    }
  }

  void toggleVpn() async {
    if (isConnected) {
      v2ray.stopV2Ray();
    } else {
      if (savedConfig.isEmpty) await updateConfig();
      if (savedConfig.isNotEmpty && await v2ray.requestPermission()) {
        v2ray.startV2Ray(remark: "Server", config: savedConfig.split('\n')[0].trim());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4E9B),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, actions: [
        IconButton(icon: const Icon(Icons.sync, color: Colors.white), onPressed: updateConfig)
      ]),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("V2RAY CONNECT", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
          GestureDetector(
            onTap: toggleVpn,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: isConnected ? Colors.green : Colors.white24, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
              child: const Icon(Icons.power_settings_new, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 40),
          Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
