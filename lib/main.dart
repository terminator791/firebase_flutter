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
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.indigo,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: NurseHomePage(),
    );
  }
}

class NurseHomePage extends StatefulWidget {
  @override
  _NurseHomePageState createState() => _NurseHomePageState();
}

class _NurseHomePageState extends State<NurseHomePage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  Map<String, dynamic> helpRequests = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenForHelpRequests();
  }

  void _listenForHelpRequests() {
    database.child("help_requests").onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      setState(() {
        helpRequests = data != null 
          ? data.map((key, value) => MapEntry(key.toString(), value))
          : {};
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat permintaan bantuan');
    });
  }

  void disableHelpRequest(String patientId) async {
    try {
      await database.child("help_requests/$patientId").update({
        "status": 0,
        "pesan": "",
      });
      _showSuccessSnackBar("Permintaan bantuan untuk $patientId telah ditangani");
    } catch (e) {
      _showErrorSnackBar("Gagal mematikan permintaan: $e");
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter help requests to only include those with status 1
    final requestingHelp = helpRequests.entries.where((entry) => entry.value["status"] == 1).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Monitoring Permintaan Bantuan"),
        actions: [
          // Badge to show number of active help requests
          Container(
            margin: EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${requestingHelp.length}',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : requestingHelp.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 100,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Tidak Ada Permintaan Bantuan",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: requestingHelp.length,
              itemBuilder: (context, index) {
                String patientId = requestingHelp[index].key;
                Map<dynamic, dynamic> request = requestingHelp[index].value;
                String message = request["pesan"] ?? "";

                return Dismissible(
                  key: Key(patientId),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => disableHelpRequest(patientId),
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: Icon(
                          Icons.person,
                          color: Colors.indigo,
                        ),
                      ),
                      title: Text(
                        patientId.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      subtitle: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onPressed: () => disableHelpRequest(patientId),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}