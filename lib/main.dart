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
  List<String> servers = [];
  int selectedIndex = 0;
  String notice = "Tap Sync, then Power to Connect";

  @override
  void initState() {
    super.initState();
    v2ray = FlutterV2ray(onStatusChanged: (s) => setState(() {
      status = s.state.toUpperCase();
      isConnected = s.state == "connected";
      if (s.state == "connected") notice = "Connected Successfully!";
    }));
    v2ray.initializeV2Ray();
    _loadStoredServers();
  }

  Future<void> _loadStoredServers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => servers = prefs.getStringList('server_list') ?? []);
  }

  Future<void> updateConfig() async {
    setState(() => notice = "Syncing Servers...");
    try {
      final url = 'https://gist.githubusercontent.com/kaungmyatjapan1999-boop/e1f6ac00358d042d58d49a8547eccc9b/raw/config.txt';
      final r = await http.get(Uri.parse(url));
      if (r.statusCode == 200 && r.body.contains("vless://")) {
        List<String> fetched = r.body.split('\n').where((s) => s.contains('://')).toList();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('server_list', fetched);
        setState(() {
          servers = fetched;
          notice = "Sync Done! Select Server.";
        });
      } else {
        setState(() => notice = "Invalid Config Link!");
      }
    } catch (e) {
      setState(() => notice = "Network Error!");
    }
  }

  void toggleVpn() async {
    if (isConnected) {
      v2ray.stopV2Ray();
    } else {
      if (servers.isEmpty) {
        await updateConfig();
        return;
      }
      setState(() => notice = "Checking Permissions...");
      // Request VPN and Notification Permission
      if (await v2ray.requestPermission()) {
        setState(() => notice = "Core Starting...");
        v2ray.startV2Ray(
          remark: "Premium Server",
          config: servers[selectedIndex].trim(),
        );
      } else {
        setState(() => notice = "Permission Denied by User");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4E9B),
      appBar: AppBar(
        title: const Text("V2RAY CONNECT", style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.sync), onPressed: updateConfig)],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          GestureDetector(
            onTap: toggleVpn,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green : Colors.white24,
                shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.power_settings_new, size: 80, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(notice, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: servers.isEmpty
                  ? const Center(child: Text("Tap Sync button at top right"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: selectedIndex == index ? Colors.blue[50] : Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.dns, color: selectedIndex == index ? Colors.blue : Colors.grey),
                            title: Text("Server ${index + 1}"),
                            onTap: () => setState(() => selectedIndex = index),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
