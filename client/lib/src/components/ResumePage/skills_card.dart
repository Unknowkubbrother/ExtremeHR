import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:flutter/material.dart';

class SkillsCard extends StatefulWidget {
  final List<String> skills;
  final bool isEditing;

  const SkillsCard({super.key, required this.skills, required this.isEditing});

  @override
  State<SkillsCard> createState() => SkillsCardState();
}

class SkillsCardState extends State<SkillsCard> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers = widget.skills
        .map((skill) => TextEditingController(text: skill))
        .toList();
    if (_controllers.isEmpty && widget.isEditing) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> getUpdatedSkills() {
    return _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  void _addSkill() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeSkill(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CardContent(
      header: Row(
        children: [
          Icon(Icons.psychology_outlined, color: AppColors.inputTextColor),
          const SizedBox(width: 8),
          Text(
            "Skills",
            style: TextStyle(
              fontSize: AppFontSizes.body,
              fontWeight: FontWeight.bold,
              color: AppColors.inputTextColor,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isEditing) ...[
            ..._controllers.asMap().entries.map((entry) {
              int idx = entry.key;
              TextEditingController controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.inputTextColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          hintText: "Enter skill",
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeSkill(idx),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addSkill,
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Add Skill"),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ] else ...[
            if (widget.skills.isEmpty)
              Text(
                "No skills added yet.",
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.skills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: AppFontSizes.small,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}
