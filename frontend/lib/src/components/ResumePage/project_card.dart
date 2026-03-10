import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/models/project_model.dart';
import 'package:flutter/material.dart';

class ProjectCard extends StatefulWidget {
  final List<Project> projects;
  final bool isEditing;

  const ProjectCard({
    super.key,
    required this.projects,
    required this.isEditing,
  });

  @override
  State<ProjectCard> createState() => ProjectCardState();
}

class ProjectCardState extends State<ProjectCard> {
  final List<ProjectEntryControllers> _controllers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant ProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projects != widget.projects) {
      _initControllers();
    }
  }

  void resetData() {
    _initControllers();
  }

  void _initControllers() {
    _controllers.clear();
    for (var project in widget.projects) {
      _controllers.add(ProjectEntryControllers(project));
    }
    if (_controllers.isEmpty && widget.isEditing) {
      _addEmptyEntry();
    }
  }

  void _addEmptyEntry() {
    setState(() {
      _controllers.add(
        ProjectEntryControllers(Project(title: "", description: null)),
      );
    });
  }

  List<Project> getUpdatedProjects() {
    return _controllers.map((c) => c.toProject()).toList();
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
              Icon(Icons.assignment_outlined, color: AppColors.inputTextColor),
              const SizedBox(width: 8),
              Text(
                "Projects",
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
                _buildProjectEntry(controllers, index),
              ],
            );
          }),
          if (_controllers.isEmpty && !widget.isEditing)
            Text(
              "No projects information",
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

  Widget _buildProjectEntry(ProjectEntryControllers controllers, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Project ${index + 1}",
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
        _buildField("Title", controllers.title),
        const SizedBox(height: 12),
        _buildField("Description", controllers.description, maxLines: 3),
      ],
    );
  }

  Widget _buildField(
    String title,
    TextEditingController controller, {
    int maxLines = 1,
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

class ProjectEntryControllers {
  final TextEditingController title;
  final TextEditingController description;

  ProjectEntryControllers(Project project)
    : title = TextEditingController(text: project.title),
      description = TextEditingController(text: project.description ?? '');

  Project toProject() {
    return Project(
      title: title.text,
      description: description.text.isEmpty ? null : description.text,
    );
  }

  void dispose() {
    title.dispose();
    description.dispose();
  }
}
