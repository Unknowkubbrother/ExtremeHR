import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/constants/app_font_sizes.dart';
import 'package:client/src/components/ResumePage/card_content.dart';
import 'package:client/src/models/personal_info_model.dart';
import 'package:flutter/material.dart';

class PersonalInfoCard extends StatefulWidget {
  final PersonalInformation data;
  final bool isEditing;

  const PersonalInfoCard({
    super.key,
    required this.data,
    required this.isEditing,
  });

  @override
  State<PersonalInfoCard> createState() => PersonalInfoCardState();
}

class PersonalInfoCardState extends State<PersonalInfoCard> {
  late TextEditingController _fullNameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _fullNameController = TextEditingController(text: widget.data.fullName);
    _ageController = TextEditingController(text: widget.data.age);
    _phoneController = TextEditingController(text: widget.data.phone);
    _emailController = TextEditingController(text: widget.data.email);
    _addressController = TextEditingController(text: widget.data.address);
  }

  PersonalInformation getUpdatedData() {
    return widget.data.copyWith(
      fullName: _fullNameController.text,
      age: _ageController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      address: _addressController.text,
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CardContent(
      header: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: AppColors.inputTextColor),
          const SizedBox(width: 8),
          Text(
            "Personal Information",
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
          _buildField("Full Name", _fullNameController),
          const SizedBox(height: 12),
          _buildField("Age", _ageController),
          const SizedBox(height: 12),
          _buildField("Phone", _phoneController),
          const SizedBox(height: 12),
          _buildField("Email", _emailController),
          const SizedBox(height: 12),
          _buildField("Address", _addressController),
        ],
      ),
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
              controller.text,
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
