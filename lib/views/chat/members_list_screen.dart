import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MembersListScreen extends StatelessWidget {
  final String classId;
  const MembersListScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Members: $classId",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2C34),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          // ── Loading ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          // ── Error ──
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) return const SizedBox();

          // ── Filter: match classYear (student) OR assignedClass (teacher) ──
          final allDocs = snapshot.data!.docs;
          var members = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['classYear'] == classId ||
                data['assignedClass'] == classId;
          }).toList();

          if (members.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_off, color: Colors.white38, size: 60),
                  SizedBox(height: 12),
                  Text(
                    "No members found",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // ── Sort: teacher first, then alphabetical ──
          members.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aIsTeacher = aData['role'] == 'teacher';
            final bIsTeacher = bData['role'] == 'teacher';

            if (aIsTeacher && !bIsTeacher) return -1;
            if (!aIsTeacher && bIsTeacher) return 1;

            // alphabetical by name
            final aName = (aData['name'] ?? '').toString().toLowerCase();
            final bName = (bData['name'] ?? '').toString().toLowerCase();
            return aName.compareTo(bName);
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final userData = members[index].data() as Map<String, dynamic>;
              final isTeacher = userData['role'] == 'teacher';
              final name = userData['name'] ?? 'Unknown';
              final profileImageUrl = userData['profileImageUrl'] as String?;

              return Card(
                color: const Color(0xFF1F2C34),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isTeacher
                      ? const BorderSide(color: Colors.green, width: 1.2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),

                  // ── Avatar with Cloudinary image ──
                  leading: _buildAvatar(
                    imageUrl: profileImageUrl,
                    name: name,
                    isTeacher: isTeacher,
                  ),

                  // ── Name ──
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  // ── Role / subjects ──
                  subtitle: Text(
                    isTeacher
                        ? _teacherSubtitle(userData)
                        : "Student • ${userData['department'] ?? userData['classYear'] ?? ''}",
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),

                  // ── Teacher badge ──
                  trailing: isTeacher
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "ADMIN",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Avatar widget ────────────────────────────────────────────────────────
  Widget _buildAvatar({
    required String? imageUrl,
    required String name,
    required bool isTeacher,
  }) {
    final fallbackColor = isTeacher ? Colors.green : Colors.blueAccent;
    final fallbackIcon = isTeacher ? Icons.verified_user : Icons.person;
    final initials = _getInitials(name);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 24,
          backgroundImage: imageProvider,
          backgroundColor: fallbackColor,
        ),
        // While loading: show initials
        placeholder: (context, url) => CircleAvatar(
          radius: 24,
          backgroundColor: fallbackColor,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        // On error: show icon
        errorWidget: (context, url, error) => CircleAvatar(
          radius: 24,
          backgroundColor: fallbackColor,
          child: Icon(fallbackIcon, color: Colors.white, size: 22),
        ),
      );
    }

    // No image → initials avatar
    return CircleAvatar(
      radius: 24,
      backgroundColor: fallbackColor,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
          : Icon(fallbackIcon, color: Colors.white, size: 22),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _teacherSubtitle(Map<String, dynamic> data) {
    final subjects = data['subjects'];
    if (subjects is List && subjects.isNotEmpty) {
      return "Teacher • ${subjects.join(', ')}";
    }
    return "Teacher";
  }
}
