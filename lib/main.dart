import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NurseApp());
}

class NurseApp extends StatelessWidget {
  const NurseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: NurseHomePage());
  }
}

class NurseHomePage extends StatefulWidget {
  @override
  _NurseHomePageState createState() => _NurseHomePageState();
}

class _NurseHomePageState extends State<NurseHomePage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  Map<String, dynamic> helpRequests = {};

  @override
  void initState() {
    super.initState();
    _listenForHelpRequests();
  }

  // Fungsi untuk mendengarkan perubahan data permintaan bantuan
  void _listenForHelpRequests() {
    database.child("help_requests").onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          helpRequests = data.map((key, value) => MapEntry(key.toString(), value));
        });
      }
    });
  }

  // Fungsi untuk mematikan permintaan bantuan
  void disableHelpRequest(String patientId) async {
    try {
      await database.child("help_requests/$patientId").update({
        "status": 0,
        "pesan": "",
      });
      print("Permintaan bantuan untuk $patientId telah dimatikan.");
    } catch (e) {
      print("Terjadi kesalahan saat mematikan permintaan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter help requests to only include those with status 1
    final requestingHelp = helpRequests.entries.where((entry) => entry.value["status"] == 1).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Monitor Permintaan Bantuan")),
      body: Center(
        child: requestingHelp.isEmpty
            ? Text("Tidak ada permintaan bantuan.")
            : ListView.builder(
                itemCount: requestingHelp.length,
                itemBuilder: (context, index) {
                  String patientId = requestingHelp[index].key;
                  Map<dynamic, dynamic> request = requestingHelp[index].value;
                  String message = request["pesan"] ?? "";

                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text("$patientId"),
                      subtitle: Text("Pesan: $message"),
                      trailing: IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => disableHelpRequest(patientId),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
