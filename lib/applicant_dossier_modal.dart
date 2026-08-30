import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';

class ApplicantDossierModal extends StatefulWidget {
  final Map<String, dynamic> user;

  const ApplicantDossierModal({super.key, required this.user});

  @override
  State<ApplicantDossierModal> createState() => _ApplicantDossierModalState();
}

class _ApplicantDossierModalState extends State<ApplicantDossierModal> {
  bool _isProcessing = false;

  void _messageApplicant() async {
    final appState = Get.find<AppState>();
    
    // Show dialog to confirm/edit message
    final TextEditingController msgController = TextEditingController(
      text: "Hello, your profile is incomplete. Please provide your missing details (e.g., ID document, Address) so we can verify your account."
    );

    final bool? shouldSend = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Message Applicant"),
        content: TextField(
          controller: msgController,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter your message here...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500)),
            child: const Text("Send Message", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldSend == true && msgController.text.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        final nameToPass = '${widget.user['first_name'] ?? ''} ${widget.user['last_name'] ?? ''}'.trim().isNotEmpty
            ? '${widget.user['first_name']} ${widget.user['last_name']}'.trim()
            : (widget.user['username'] ?? 'User');
        await appState.createOrOpenThread(
          otherPartyName: nameToPass,
          otherPartyImage: widget.user['profile_picture'] ?? '',
          initialMessage: msgController.text.trim(),
        );
        
        if (mounted) {
          // Close the dossier modal
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Message sent! Check your Messages tab to continue the chat.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error sending message: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  void _verifyUser() async {
    setState(() => _isProcessing = true);
    final appState = Get.find<AppState>();
    try {
      await appState.verifyUser(widget.user['id']);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account approved and verified successfully.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _rejectAccount() async {
    setState(() => _isProcessing = true);
    final appState = Get.find<AppState>();
    try {
      await appState.suspendUser(widget.user['id']);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account suspended/rejected.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Suspension error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final String name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isNotEmpty
        ? '${user['first_name']} ${user['last_name']}'.trim()
        : (user['username'] ?? 'Unknown User');
    final String role = (user['role'] ?? 'CLIENT').toString().toUpperCase();
    final String email = user['email'] ?? 'N/A';
    final String phone = user['phone'] ?? 'N/A';
    final String username = user['username'] ?? 'N/A';
    final String country = user['location']?.toString().split(',').last.trim() ?? 'Global';
    
    // Attempt to parse joined date or default
    final createdAt = user['created_at'];
    String joinedDate = "Unknown";
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        joinedDate = "${date.month}/${date.day}/${date.year}";
      } catch (_) {}
    }

    final bool isVerified = user['is_verified'] == true;
    final String verificationStatus = isVerified ? "Verified" : "Pending Vetting";
    final Color statusColor = isVerified ? const Color(0xFF1E8E3E) : const Color(0xFFEab308); // Orange/Yellow

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Applicant Dossier & KYC Details",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Internal Admin Verification Inspector",
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 24),

                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: user['profile_picture'] != null
                              ? NetworkImage(user['profile_picture'])
                              : null,
                          child: user['profile_picture'] == null
                              ? const Icon(Icons.person, color: Colors.white, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF001F3F),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      role,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text("Country: $country", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  const SizedBox(width: 12),
                                  Text("Joined: $joinedDate", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Contact Info
                  const Text("CONTACT INFORMATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Email Address", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                              const SizedBox(height: 16),
                              const Text("Username", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              Text("@$username", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Phone Number", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              Text(phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                              const SizedBox(height: 16),
                              const Text("Verification Status", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              Text(verificationStatus, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Documents
                  const Text("IDENTITY & COMPLIANCE DOCUMENTS (0)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "No KYC documents uploaded by this user.",
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Close"),
                        ),
                        if (!isVerified) ...[
                          OutlinedButton(
                            onPressed: _rejectAccount,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFEF4444)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Reject Account"),
                          ),
                          OutlinedButton(
                            onPressed: _messageApplicant,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Message Applicant"),
                          ),
                          ElevatedButton(
                            onPressed: _verifyUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4500),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, size: 18),
                                SizedBox(width: 8),
                                Text("Approve & Verify"),
                              ],
                            ),
                          ),
                        ]
                      ],
                    )
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}
