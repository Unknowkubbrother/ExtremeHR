import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/models/experience_model.dart';
import 'package:flutter/material.dart';

class ExperienceCard extends StatefulWidget {
  final List<Experience> experience;
  final bool isEditing;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.isEditing,
  });

  @override
  State<ExperienceCard> createState() => ExperienceCardState();
}

class ExperienceCardState extends State<ExperienceCard> {
  final List<ExperienceEntryControllers> _controllers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers.clear();
    for (var exp in widget.experience) {
      _controllers.add(ExperienceEntryControllers(exp));
    }
    if (_controllers.isEmpty && widget.isEditing) {
      _addEmptyEntry();
    }
  }

  void _addEmptyEntry() {
    setState(() {
      _controllers.add(
        ExperienceEntryControllers(
          Experience(
            company: "",
            role: "",
            startYear: null,
            startMonth: null,
            endYear: null,
            endMonth: null,
            description: "",
          ),
        ),
      );
    });
  }

  List<Experience> getUpdatedExperience() {
    return _controllers.map((c) => c.toExperience()).toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CardContent(
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline, color: AppColors.inputTextColor),
              const SizedBox(width: 8),
              Text(
                "Work Experience",
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inputTextColor,
                ),
              ),
            ],
          ),
          if (widget.isEditing)
            IconButton(
              onPressed: _addEmptyEntry,
              icon: const Icon(Icons.add, color: AppColors.primary),
            ),
        ],
      ),
      child: Column(
        children: [
          ..._controllers.asMap().entries.map((entry) {
            int index = entry.key;
            var controllers = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 32),
                _buildExperienceEntry(controllers, index),
              ],
            );
          }),
          if (_controllers.isEmpty && !widget.isEditing)
            Text(
              "No work experience information",
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExperienceEntry(
    ExperienceEntryControllers controllers,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Experience ${index + 1}",
              style: TextStyle(
                fontSize: AppFontSizes.body,
                fontWeight: FontWeight.bold,
                color: AppColors.inputTextColor,
              ),
            ),
            if (widget.isEditing)
              IconButton(
                onPressed: () {
                  setState(() {
                    _controllers.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildField("Role", controllers.role),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildField(
                "Start Month",
                controllers.startMonth,
                isNumber: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildField(
                "Start Year",
                controllers.startYear,
                isNumber: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildField(
                "End Month",
                controllers.endMonth,
                isNumber: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildField(
                "End Year",
                controllers.endYear,
                isNumber: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildField("Description", controllers.description, maxLines: 3),
      ],
    );
  }

  Widget _buildField(
    String title,
    TextEditingController controller, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppFontSizes.small,
            fontWeight: FontWeight.bold,
            color: AppColors.inputTextColor,
          ),
        ),
        const SizedBox(height: 4),
        if (widget.isEditing)
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputTextColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              controller.text.isEmpty ? "-" : controller.text,
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: Colors.black87,
              ),
            ),
          ),
      ],
    );
  }
}

class ExperienceEntryControllers {
  final TextEditingController company;
  final TextEditingController role;
  final TextEditingController startYear;
  final TextEditingController startMonth;
  final TextEditingController endYear;
  final TextEditingController endMonth;
  final TextEditingController description;

  ExperienceEntryControllers(Experience exp)
    : company = TextEditingController(text: exp.company),
      role = TextEditingController(text: exp.role),
      startYear = TextEditingController(text: exp.startYear?.toString() ?? ''),
      startMonth = TextEditingController(
        text: exp.startMonth?.toString() ?? '',
      ),
      endYear = TextEditingController(text: exp.endYear?.toString() ?? ''),
      endMonth = TextEditingController(text: exp.endMonth?.toString() ?? ''),
      description = TextEditingController(text: exp.description);

  Experience toExperience() {
    return Experience(
      company: company.text,
      role: role.text,
      startYear: int.tryParse(startYear.text),
      startMonth: int.tryParse(startMonth.text),
      endYear: int.tryParse(endYear.text),
      endMonth: int.tryParse(endMonth.text),
      description: description.text,
    );
  }

  void dispose() {
    company.dispose();
    role.dispose();
    startYear.dispose();
    startMonth.dispose();
    endYear.dispose();
    endMonth.dispose();
    description.dispose();
  }
}
