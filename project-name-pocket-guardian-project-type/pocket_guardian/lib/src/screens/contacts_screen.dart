import 'package:flutter/material.dart';

import '../widgets/section_card.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.onChanged,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Primary Emergency Contact',
        child: Column(
          children: [
            TextField(
              controller: nameController,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'Contact name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
