import 'package:flutter/material.dart';
import '../theme/vigil_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/vigil_button.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<Map<String, dynamic>> _contacts = [
    {
      'name': 'Mom',
      'phone': '+91 98765 43210',
      'relationship': 'Parent',
      'isPrimary': true,
    },
    {
      'name': 'Dad',
      'phone': '+91 98765 43211',
      'relationship': 'Parent',
      'isPrimary': false,
    },
    {
      'name': 'Rahul',
      'phone': '+91 99887 76655',
      'relationship': 'Friend',
      'isPrimary': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: VigilTheme.cyan),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              glowColor: VigilTheme.teal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: VigilTheme.teal.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.info_outline, color: VigilTheme.teal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'These contacts will receive alerts with your location and safety status when an emergency is triggered.',
                      style: TextStyle(
                        fontSize: 12,
                        color: VigilTheme.textGrey.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._contacts.map((c) => _buildContactCard(c)),
            const SizedBox(height: 24),
            VigilButton(
              text: 'Add Contact',
              onPressed: _showAddContactDialog,
              icon: Icons.person_add_rounded,
              outlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: contact['isPrimary']
                  ? VigilTheme.primaryGradient
                  : const LinearGradient(colors: [Color(0xFF2A2F4A), Color(0xFF1A1F3A)]),
            ),
            child: Center(
              child: Text(
                contact['name'][0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: contact['isPrimary'] ? VigilTheme.deepNavy : VigilTheme.textWhite,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contact['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: VigilTheme.textWhite,
                      ),
                    ),
                    if (contact['isPrimary']) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: VigilTheme.cyan.withOpacity(0.15),
                        ),
                        child: const Text('Primary',
                            style: TextStyle(fontSize: 10, color: VigilTheme.cyan)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(contact['phone'],
                    style: TextStyle(
                        fontSize: 13, color: VigilTheme.textGrey.withOpacity(0.8))),
                Text(contact['relationship'],
                    style: TextStyle(
                        fontSize: 11, color: VigilTheme.textGrey.withOpacity(0.6))),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded, color: VigilTheme.textGrey),
            color: VigilTheme.cardDark,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'primary', child: Text('Set as Primary')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: VigilTheme.alertRed))),
            ],
            onSelected: (value) {
              // TODO: Implement actions
            },
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: VigilTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Emergency Contact',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: VigilTheme.textWhite)),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              style: const TextStyle(color: VigilTheme.textWhite),
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: VigilTheme.textWhite),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 24),
            VigilButton(
              text: 'Add Contact',
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  setState(() {
                    _contacts.add({
                      'name': nameController.text,
                      'phone': phoneController.text,
                      'relationship': 'Other',
                      'isPrimary': false,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              icon: Icons.person_add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
