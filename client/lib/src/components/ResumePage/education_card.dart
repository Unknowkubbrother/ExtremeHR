import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/models/education_model.dart';
import 'package:flutter/material.dart';

class EducationCard extends StatefulWidget {
  final List<Education> education;
  final bool isEditing;

  const EducationCard({
    super.key,
    required this.education,
    required this.isEditing,
  });

  @override
  State<EducationCard> createState() => EducationCardState();
}

class EducationCardState extends State<EducationCard> {
  final List<EducationEntryControllers> _controllers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _controllers.clear();
    for (var edu in widget.education) {
      _controllers.add(EducationEntryControllers(edu));
    }
    if (_controllers.isEmpty && widget.isEditing) {
      _addEmptyEntry();
    }
  }

  void _addEmptyEntry() {
    setState(() {
      _controllers.add(
        EducationEntryControllers(
          Education(
            institution: "",
            degree: "",
            faculty: "",
            major: "",
            gpax: "",
            startDate: "",
            endDate: "",
          ),
        ),
      );
    });
  }

  List<Education> getUpdatedEducation() {
    return _controllers.map((c) => c.toEducation()).toList();
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
              Icon(Icons.school_outlined, color: AppColors.inputTextColor),
              const SizedBox(width: 8),
              Text(
                "Education",
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
                _buildEducationEntry(controllers, index),
              ],
            );
          }),
          if (_controllers.isEmpty && !widget.isEditing)
            Text(
              "No education information",
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

  Widget _buildEducationEntry(
    EducationEntryControllers controllers,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Education ${index + 1}",
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
        _buildField("Institution", controllers.institution),
        const SizedBox(height: 12),
        _buildField("Degree", controllers.degree),
        const SizedBox(height: 12),
        _buildField("คณะ (Faculty)", controllers.faculty),
        const SizedBox(height: 12),
        _buildField("สาขา (Major)", controllers.major),
        const SizedBox(height: 12),
        _buildField("เกรดเฉลี่ย (GPAX)", controllers.gpax),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildField("Start Date", controllers.startDate)),
            const SizedBox(width: 12),
            Expanded(child: _buildField("End Date", controllers.endDate)),
          ],
        ),
      ],
    );
  }

  Widget _buildField(String title, TextEditingController controller) {
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

class EducationEntryControllers {
  final TextEditingController institution;
  final TextEditingController degree;
  final TextEditingController faculty;
  final TextEditingController major;
  final TextEditingController gpax;
  final TextEditingController startDate;
  final TextEditingController endDate;

  EducationEntryControllers(Education edu)
    : institution = TextEditingController(text: edu.institution),
      degree = TextEditingController(text: edu.degree),
      faculty = TextEditingController(text: edu.faculty),
      major = TextEditingController(text: edu.major),
      gpax = TextEditingController(text: edu.gpax),
      startDate = TextEditingController(text: edu.startDate),
      endDate = TextEditingController(text: edu.endDate);

  Education toEducation() {
    return Education(
      institution: institution.text,
      degree: degree.text,
      faculty: faculty.text,
      major: major.text,
      gpax: gpax.text,
      startDate: startDate.text,
      endDate: endDate.text,
    );
  }

  void dispose() {
    institution.dispose();
    degree.dispose();
    faculty.dispose();
    major.dispose();
    gpax.dispose();
    startDate.dispose();
    endDate.dispose();
  }
}
