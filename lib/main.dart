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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Monitor Permintaan Bantuan")),
      body: Center(
        child: helpRequests.isEmpty
            ? Text("Tidak ada permintaan bantuan.")
            : ListView.builder(
                itemCount: helpRequests.length,
                itemBuilder: (context, index) {
                  String patientId = helpRequests.keys.elementAt(index);
                  Map<dynamic, dynamic> request = helpRequests[patientId];
                  bool isRequestingHelp = request["status"] == 1;
                  String message = request["pesan"] ?? "";

                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text("$patientId"),
                      subtitle: Text(isRequestingHelp
                          ? "Pesan: $message"
                          : "Tidak meminta bantuan."),
                      trailing: Icon(
                        isRequestingHelp ? Icons.warning : Icons.check_circle,
                        color: isRequestingHelp ? Colors.red : Colors.green,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
