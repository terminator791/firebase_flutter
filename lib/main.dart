import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PatientApp());
}

class PatientApp extends StatelessWidget {
  const PatientApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade500, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
      home: PatientHomePage(),
    );
  }
}

class PatientHomePage extends StatefulWidget {
  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  final TextEditingController messageController1 = TextEditingController();
  final TextEditingController messageController2 = TextEditingController();

  void requestHelp(String patientId, String message) async {
    if (message.isEmpty) {
      _showSnackBar('Pesan tidak boleh kosong', isError: true);
      return;
    }
    
    try {
      await database.child("help_requests/$patientId").update({
        "status": 1,
        "pesan": message,
      });
      _showSnackBar('Permintaan bantuan terkirim untuk $patientId');
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat mengirim permintaan', isError: true);
    }
  }

  void cancelHelpRequest(String patientId) async {
    try {
      await database.child("help_requests/$patientId").update({
        "status": 0,
        "pesan": "",
      });
      _showSnackBar('Permintaan bantuan dibatalkan untuk $patientId');
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat membatalkan permintaan', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Layanan Bantuan Pasien',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPatientSection('Pasien 1', messageController1, 'pasien_1'),
            const SizedBox(height: 20),
            _buildPatientSection('Pasien 2', messageController2, 'pasien_2'),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSection(String title, TextEditingController controller, String patientId) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Pesan untuk $title",
                prefixIcon: const Icon(Icons.message_outlined),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => requestHelp(patientId, controller.text),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Minta Bantuan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => cancelHelpRequest(patientId),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Batalkan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController1.dispose();
    messageController2.dispose();
    super.dispose();
  }
}