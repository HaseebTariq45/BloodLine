import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

class ContactInfoModal extends StatelessWidget {
  final String name;
  final String phone;
  final String title;
  final VoidCallback? onCallPressed;
  final VoidCallback? onMessagePressed;

  const ContactInfoModal({
    super.key,
    required this.name,
    required this.phone,
    required this.title,
    this.onCallPressed,
    this.onMessagePressed,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (onCallPressed != null) {
      onCallPressed!();
      return;
    }
    
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    if (onMessagePressed != null) {
      onMessagePressed!();
      return;
    }
    
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Could not launch SMS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone, color: Colors.green),
            ),
            title: const Text('Call'),
            subtitle: Text(phone),
            onTap: () {
              Navigator.pop(context);
              _makePhoneCall(phone);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.message, color: Colors.blue),
            ),
            title: const Text('Send SMS'),
            subtitle: Text(phone),
            onTap: () {
              Navigator.pop(context);
              _sendSMS(phone);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
