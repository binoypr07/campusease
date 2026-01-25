import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminLibraryPage extends StatefulWidget {
  const AdminLibraryPage({super.key});

  @override
  State<AdminLibraryPage> createState() => _AdminLibraryPageState();
}

class _AdminLibraryPageState extends State<AdminLibraryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  File? _selectedFile;
  bool _isUploading = false;

  // --- 1. PICK FILE WITH SNACKBAR ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
      Get.snackbar(
        "File Selected",
        result.files.single.name,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "Selection Cancelled",
        "No PDF was selected.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  // --- 2. UPLOAD WITH SNACKBARS ---
  Future<void> _uploadBook() async {
    if (_selectedFile == null ||
        _titleController.text.isEmpty ||
        _authorController.text.isEmpty) {
      Get.snackbar(
        "Missing Info",
        "Please provide a title, author, and select a PDF.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.pdf";
      Reference storageRef = FirebaseStorage.instance.ref().child(
        "library/$fileName",
      );
      await storageRef.putFile(_selectedFile!);
      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('library_books').add({
        'title': _titleController.text,
        'author': _authorController.text,
        'url': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Reset UI on success
      _titleController.clear();
      _authorController.clear();
      setState(() => _selectedFile = null);

      Get.snackbar(
        "Success",
        "Book uploaded to Smart Library successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        "Upload Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // --- 3. DELETE LOGIC ---
  Future<void> _deleteBook(String docId, String fileUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      await FirebaseFirestore.instance
          .collection('library_books')
          .doc(docId)
          .delete();
      Get.snackbar("Deleted", "Book removed from database and storage.");
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not delete file: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Smart Library")),
      body: Column(
        children: [
          // TOP UPLOAD CARD
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Book Title",
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: "Author Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ROW FOR ALIGNED BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text("Pick PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      _isUploading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: _uploadBook,
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text("Upload"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                    ],
                  ),
                  if (_selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Ready: ${_selectedFile!.path.split('/').last}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Current Library Books",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),

          // LIST VIEW FOR REMOVING BOOKS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('library_books')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                      title: Text(doc['title']),
                      subtitle: Text(doc['author']),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteBook(doc.id, doc['url']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
