import 'package:client/src/components/HR/HomeHRPage/main_navigation_page.dart';
import 'package:client/src/components/shared/main_button.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/components/shared/confirm.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/models/jobModify_model.dart';
import 'package:client/src/models/jobDetail_model.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/job_services.dart';
import 'package:flutter/material.dart';

class JobEditPage extends StatefulWidget {
  final JobDetail? job; // null => Create

  const JobEditPage({super.key, this.job});

  @override
  State<JobEditPage> createState() => _JobEditPageState();
}

class _JobEditPageState extends State<JobEditPage> {
  final JobServices _jobService = JobServices();
  final AuthStorage _authStorage = AuthStorage();
  final _formKey = GlobalKey<FormState>();

  final ConfirmDialog _deleteDialog = ConfirmDialog(
    title: "Delete this job?",
    content: "This action cannot be undone.",
    confirmText: "Delete",
    cancelText: "Cancel",
    confirmColor: Colors.red,
    cancelColor: AppColors.textPrimaryTo,
  );

  bool _isLoading = false; // ใช้กับ Save/Create
  bool _isDeleting = false;

  late TextEditingErrorControllers _controllers;

  // Lists
  List<String> _jobFields = [];
  List<String> _responsibilities = [];
  List<String> _qualifications = [];
  List<String> _skills = [];

  static const List<String> _presetJobTags = [
    "Technology",
    "Business",
    "Marketing",
    "Sales",
    "Finance",
    "Human Resources",
    "Education",
    "Healthcare",
    "Customer Service",
  ];

  @override
  void initState() {
    super.initState();
    _controllers = TextEditingErrorControllers(widget.job);
    if (widget.job != null) {
      _jobFields = List.from(widget.job!.jobFields);
      _responsibilities = List.from(widget.job!.responsibilities);
      _qualifications = List.from(widget.job!.qualifications);
      _skills = List.from(widget.job!.skills);
    }
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final token = await _authStorage.getToken();
      if (token == null) return;

      if (widget.job == null) {
        final jobCreate = JobCreate(
          title: _controllers.title.text,
          jobFields: _jobFields,
          description: _controllers.description.text,
          responsibilities: _responsibilities,
          qualifications: _qualifications,
          skills: _skills,
          headcount: int.tryParse(_controllers.headcount.text) ?? 1,
          minAge: int.tryParse(_controllers.minAge.text) ?? 18,
          maxAge: int.tryParse(_controllers.maxAge.text) ?? 99,
          minSalary: int.tryParse(_controllers.minSalary.text) ?? 0,
          maxSalary: int.tryParse(_controllers.maxSalary.text) ?? 0,
        );
        await _jobService.createJob(token, jobCreate);
        if (mounted) Navigator.pop(context);
      } else {
        final jobUpdate = JobUpdate(
          id: widget.job!.id,
          title: _controllers.title.text,
          jobFields: _jobFields,
          description: _controllers.description.text,
          responsibilities: _responsibilities,
          qualifications: _qualifications,
          skills: _skills,
          headcount: int.tryParse(_controllers.headcount.text) ?? 1,
          minAge: int.tryParse(_controllers.minAge.text) ?? 18,
          maxAge: int.tryParse(_controllers.maxAge.text) ?? 99,
          minSalary: int.tryParse(_controllers.minSalary.text) ?? 0,
          maxSalary: int.tryParse(_controllers.maxSalary.text) ?? 0,
        );
        await _jobService.updateJob(token, jobUpdate);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteJob() async {
    if (widget.job == null) return;

    // confirm
    final confirm = await _deleteDialog.show(context);

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      final token = await _authStorage.getToken();
      if (token == null) return;

      final ok = await _jobService.deleteJob(token, widget.job!.id);
      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Deleted successfully")));
        // ส่งค่า non-null กลับไปให้หน้าก่อนรู้ว่าเกิด action
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainNavigationHRPage(state: 1)),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _isDeleting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimaryTo,
        elevation: 0,
        title: Text(
          widget.job == null ? "Create Job" : "Edit Job",
          style: TextStyle(
            fontSize: AppFontSizes.subtitle,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryTo,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Basic Info =====
              CardContent(
                header: Row(
                  children: [
                    Icon(Icons.work_outline, color: AppColors.inputTextColor),
                    const SizedBox(width: 8),
                    Text(
                      "Job Information",
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
                    _buildTextField("Job Title", _controllers.title),
                    const SizedBox(height: 12),

                    // ✅ textarea: ขยายตามข้อความ เห็นยาว ๆ ได้หมด
                    _buildTextField(
                      "Description",
                      _controllers.description,
                      keyboardType: TextInputType.multiline,
                      minLines: 6,
                      maxLines: null, // expand
                    ),
                  ],
                ),
              ),

              // ===== Requirements =====
              CardContent(
                header: Row(
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      color: AppColors.inputTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Requirements",
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inputTextColor,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Headcount",
                            _controllers.headcount,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Min Age",
                            _controllers.minAge,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            "Max Age",
                            _controllers.maxAge,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Min Salary",
                            _controllers.minSalary,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            "Max Salary",
                            _controllers.maxSalary,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ===== Tags =====
              CardContent(
                header: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.inputTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Job Tags",
                          style: TextStyle(
                            fontSize: AppFontSizes.body,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inputTextColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                      onPressed: busy ? null : _openJobTagsPicker,
                      tooltip: "Add tag",
                    ),
                  ],
                ),
                child: _buildSelectedTagsList(),
              ),

              // ===== Lists =====
              CardContent(
                header: Row(
                  children: [
                    Icon(Icons.checklist_rtl, color: AppColors.inputTextColor),
                    const SizedBox(width: 8),
                    Text(
                      "Details",
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inputTextColor,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListEditor(
                      "Responsibilities",
                      _responsibilities,
                      (newList) => setState(() => _responsibilities = newList),
                    ),
                    const Divider(height: 24),
                    _buildListEditor(
                      "Qualifications",
                      _qualifications,
                      (newList) => setState(() => _qualifications = newList),
                    ),
                    const Divider(height: 24),
                    _buildListEditor(
                      "Skills",
                      _skills,
                      (newList) => setState(() => _skills = newList),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ===== Save/Create =====
              MainButton(
                text: widget.job == null ? "Create Job" : "Save Changes",
                onPressed: busy ? null : _save,
                isLoading: _isLoading,
              ),

              // ✅ Delete button ใต้ Save (เฉพาะ Edit)
              if (widget.job != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(_isDeleting ? "Deleting..." : "Delete Job"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: busy ? null : _deleteJob,
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _buildSelectedTagsList() {
    if (_jobFields.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "No tags yet. Tap + to add.",
          style: TextStyle(
            fontSize: AppFontSizes.body,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: _jobFields.asMap().entries.map((entry) {
        final idx = entry.key;
        final val = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(child: Text("• $val")),
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () {
                  final newList = List<String>.from(_jobFields)..removeAt(idx);
                  setState(() => _jobFields = newList);
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int? minLines,
    int? maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSizes.small,
            fontWeight: FontWeight.bold,
            color: AppColors.inputTextColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          validator: (value) =>
              value == null || value.trim().isEmpty ? "Required" : null,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListEditor(
    String label,
    List<String> items,
    Function(List<String>) onUpdate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () => _addItem(label, items, onUpdate),
            ),
          ],
        ),
        if (items.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "No items",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final val = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(child: Text("• $val")),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () {
                    final newList = List<String>.from(items)..removeAt(idx);
                    onUpdate(newList);
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _addItem(
    String label,
    List<String> items,
    Function(List<String>) onUpdate,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Add $label",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                minLines: 1,
                maxLines: 5,
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Type...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  final newList = List<String>.from(items)..add(text);
                  onUpdate(newList);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    final newList = List<String>.from(items)..add(text);
                    onUpdate(newList);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Add"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Job tag picker (tap = add + close) ----------

  Future<void> _openJobTagsPicker() async {
    final customController = TextEditingController();

    bool isAlreadyAdded(String tag) {
      final lower = tag.trim().toLowerCase();
      return _jobFields.any((t) => t.trim().toLowerCase() == lower);
    }

    void addTagAndClose(BuildContext ctx, String tag) {
      final cleaned = tag.trim();
      if (cleaned.isEmpty) return;
      if (isAlreadyAdded(cleaned)) return;
      setState(() => _jobFields = [..._jobFields, cleaned]);
      Navigator.pop(ctx);
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Select Job Tag",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Custom tag",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.inputTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: customController,
                        decoration: InputDecoration(
                          hintText: "Type your own tag...",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (v) {
                          final text = v.trim();
                          if (text.isEmpty || isAlreadyAdded(text)) return;
                          addTagAndClose(ctx, text);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final text = customController.text.trim();
                        if (text.isEmpty || isAlreadyAdded(text)) return;
                        addTagAndClose(ctx, text);
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _presetJobTags.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final tag = _presetJobTags[i];
                      if (isAlreadyAdded(tag)) return const SizedBox.shrink();

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          tag,
                          style: TextStyle(
                            color: AppColors.textPrimaryTo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => addTagAndClose(ctx, tag),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TextEditingErrorControllers {
  final title = TextEditingController();
  final description = TextEditingController();
  final headcount = TextEditingController();
  final minAge = TextEditingController();
  final maxAge = TextEditingController();
  final minSalary = TextEditingController();
  final maxSalary = TextEditingController();

  TextEditingErrorControllers(JobDetail? job) {
    if (job != null) {
      title.text = job.title;
      description.text = job.description;
      headcount.text = job.headcount.toString();
      minAge.text = job.minAge.toString();
      maxAge.text = job.maxAge.toString();
      minSalary.text = job.minSalary.toString();
      maxSalary.text = job.maxSalary.toString();
    }
  }

  void dispose() {
    title.dispose();
    description.dispose();
    headcount.dispose();
    minAge.dispose();
    maxAge.dispose();
    minSalary.dispose();
    maxSalary.dispose();
  }
}
