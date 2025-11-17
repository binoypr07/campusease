import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/services/firebase_auth_service.dart';

class PendingUsersScreen extends StatelessWidget {
  const PendingUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Approvals"),
        centerTitle: true,
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("pendingUsers")
            .snapshots(),
        builder: (context, snapshot) {
          
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          var data = snapshot.data!.docs;

          if (data.isEmpty) {
            return const Center(
              child: Text(
                "No users waiting for approval",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              var user = data[index];

              String role = user['role'];
              String department = user['department'] ?? "N/A";
              String name = user['name'];
              String admission = user['admissionNumber'] ?? "-";
              String teacherId = user['teacherId'] ?? "-";

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ----------------- NAME -----------------
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ----------------- ROLE + DEPT -----------------
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Role: $role",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Dept: $department",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ----------------- EXTRA FIELDS -----------------
                      if (role == "student")
                        Text(
                          "Admission No: $admission",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),

                      if (role == "teacher")
                        Text(
                          "Teacher ID: $teacherId",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),

                      const SizedBox(height: 14),

                      // ----------------- APPROVE BUTTON -----------------
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuthService()
                                .approveUser(user.id, user.data() as Map<String, dynamic>);

                            Get.snackbar(
                              "Success",
                              "User Approved!",
                              backgroundColor: Colors.black,
                              colorText: Colors.white,
                            );
                          },
                          child: const Text("Approve"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
