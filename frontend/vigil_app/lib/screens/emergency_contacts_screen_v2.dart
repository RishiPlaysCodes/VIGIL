import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../services/api_service.dart';

class EmergencyContactsScreenV2 extends StatefulWidget {
  const EmergencyContactsScreenV2({super.key});

  @override
  State<EmergencyContactsScreenV2> createState() =>
      _EmergencyContactsScreenV2State();
}

class _EmergencyContactsScreenV2State extends State<EmergencyContactsScreenV2> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getContacts();
      if (!mounted) return;
      setState(() {
        _contacts = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addContactDialog() async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final emailC = TextEditingController();
    String relationship = 'parent';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VigilThemeV2.cardBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HoloText(
                text: 'ADD CONTACT',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                    letterSpacing: 3),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameC,
                style: const TextStyle(color: VigilThemeV2.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: VigilThemeV2.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: VigilThemeV2.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: relationship,
                dropdownColor: VigilThemeV2.cardBase,
                style: const TextStyle(color: VigilThemeV2.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Icons.family_restroom_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                  DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                  DropdownMenuItem(value: 'sibling', child: Text('Sibling')),
                  DropdownMenuItem(value: 'friend', child: Text('Friend')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setSt(() => relationship = v ?? 'other'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameC.text.isEmpty || phoneC.text.isEmpty) return;
                    await _api.addContact({
                      'name': nameC.text,
                      'phone_number': phoneC.text,
                      'email': emailC.text,
                      'relationship': relationship,
                      'notify_by_sms': true,
                      'notify_by_email': emailC.text.isNotEmpty,
                    });
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    _loadContacts();
                  },
                  child: const Text('SAVE CONTACT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY CONTACTS',
            style: TextStyle(letterSpacing: 3, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _addContactDialog,
            icon: const Icon(Icons.person_add_rounded,
                color: VigilThemeV2.neonCyan),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: VigilThemeV2.neonCyan))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  NeoGlassCard(
                    padding: const EdgeInsets.all(14),
                    glowColor: VigilThemeV2.tealGlow,
                    child: Row(children: const [
                      Icon(Icons.info_outline_rounded,
                          color: VigilThemeV2.tealGlow, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'These contacts receive your live tracking link, location, and intruder evidence during emergencies.',
                          style: TextStyle(
                            fontSize: 12,
                            color: VigilThemeV2.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (_contacts.isEmpty)
                    NeoGlassCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(Icons.contacts_outlined,
                              size: 48,
                              color: VigilThemeV2.textMuted.withOpacity(0.6)),
                          const SizedBox(height: 12),
                          const Text('No Contacts Yet',
                              style: TextStyle(
                                color: VigilThemeV2.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 4),
                          Text('Add at least one to enable alerts',
                              style: VigilThemeV2.caption),
                        ],
                      ),
                    )
                  else
                    ..._contacts.map((c) => _contactCard(c)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addContactDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('ADD CONTACT',
                          style: TextStyle(letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _contactCard(Map<String, dynamic> c) {
    final name = c['name'] ?? '';
    final phone = c['phone_number'] ?? '';
    final relationship = c['relationship'] ?? 'other';
    final isPrimary = c['is_primary'] == true;

    return NeoGlassCard(
      padding: const EdgeInsets.all(14),
      glowColor: isPrimary ? VigilThemeV2.neonCyan : VigilThemeV2.borderSubtle,
      showHoloBorder: isPrimary,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isPrimary
                  ? VigilThemeV2.shieldGradient
                  : const LinearGradient(colors: [
                      Color(0xFF1F2A40),
                      Color(0xFF141B2D),
                    ]),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isPrimary
                      ? VigilThemeV2.spaceBlack
                      : VigilThemeV2.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: VigilThemeV2.textPrimary,
                      )),
                  if (isPrimary) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: VigilThemeV2.neonCyan.withOpacity(0.15),
                      ),
                      child: const Text('PRIMARY',
                          style: TextStyle(
                            fontSize: 8,
                            color: VigilThemeV2.neonCyan,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(phone,
                    style: VigilThemeV2.bodySM.copyWith(fontSize: 12)),
                Text(relationship.toString().toUpperCase(),
                    style: VigilThemeV2.caption.copyWith(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
