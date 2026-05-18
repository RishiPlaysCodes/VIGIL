import 'package:flutter/material.dart';
import '../theme/vigil_theme_v2.dart';
import '../widgets/neo_glass_card.dart';
import '../widgets/guardian_avatar_widget.dart';
import '../services/guardian_character_service.dart';

/// Guardian Character Selection Screen.
/// Premium gallery showing all 5 AI guardians with live preview.
class GuardianSelectionScreen extends StatefulWidget {
  const GuardianSelectionScreen({super.key});

  @override
  State<GuardianSelectionScreen> createState() =>
      _GuardianSelectionScreenState();
}

class _GuardianSelectionScreenState extends State<GuardianSelectionScreen> {
  final GuardianCharacterService _service = GuardianCharacterService();
  late GuardianCharacter _selected;

  @override
  void initState() {
    super.initState();
    _selected = _service.activeGuardian;
  }

  void _confirm() {
    _service.setGuardian(_selected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final guardians = _service.getAllGuardians();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHOOSE GUARDIAN',
            style: TextStyle(letterSpacing: 3, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: VigilThemeV2.backgroundGradient),
        child: Column(
          children: [
            // Live preview of selected guardian
            Container(
              padding: const EdgeInsets.all(20),
              child: NeoGlassCard(
                padding: const EdgeInsets.all(24),
                showHoloBorder: true,
                glowColor: _selected.appearance.primaryColor,
                animateGlow: true,
                child: Column(
                  children: [
                    GuardianAvatarWidget(
                      guardian: _selected,
                      context: GuardianContext.greeting,
                      size: 110,
                      showMessage: true,
                    ),
                    const SizedBox(height: 12),
                    Text(_selected.description,
                        textAlign: TextAlign.center,
                        style: VigilThemeV2.bodySM.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ),

            // Guardian grid
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: guardians.length,
                itemBuilder: (ctx, i) {
                  final g = guardians[i];
                  final isSelected = g.type == _selected.type;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NeoGlassCard(
                      padding: const EdgeInsets.all(14),
                      showHoloBorder: isSelected,
                      glowColor: g.appearance.primaryColor,
                      animateGlow: isSelected,
                      onTap: () => setState(() => _selected = g),
                      child: Row(
                        children: [
                          GuardianMiniIndicator(
                            guardian: g,
                            context: GuardianContext.monitoring,
                            size: 44,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: g.appearance.primaryColor,
                                      letterSpacing: 2,
                                    )),
                                Text(g.title,
                                    style: VigilThemeV2.caption),
                                const SizedBox(height: 4),
                                Text(g.personality.tone.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: g.appearance.accentColor,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: g.appearance.primaryColor, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected.appearance.primaryColor,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    'ACTIVATE ${_selected.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
