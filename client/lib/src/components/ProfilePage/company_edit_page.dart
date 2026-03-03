import 'package:client/src/components/shared/main_button.dart';
import 'package:client/src/components/ProfilePage/profile_widgets.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:client/src/services/auth_storage.dart';
import 'package:client/src/services/company_services.dart';
import 'package:flutter/material.dart';

class CompanyEditPage extends StatefulWidget {
  const CompanyEditPage({super.key});

  @override
  State<CompanyEditPage> createState() => _CompanyEditPageState();
}

class _CompanyEditPageState extends State<CompanyEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _companyService = CompanyServices();
  final _authStorage = AuthStorage();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        final company = await _companyService.getMyCompany(token);
        if (company != null) {
          _nameController.text = company.name;
          _locationController.text = company.location;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading company data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final token = await _authStorage.getToken();
      if (token != null) {
        await _companyService.updateMyCompany(
          token,
          _nameController.text,
          _locationController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company updated successfully')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating company: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Company'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimaryTo,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledTextField(
                      label: 'Company Name',
                      controller: _nameController,
                      hintText: 'Enter company name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter company name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    LabeledTextField(
                      label: 'Location',
                      controller: _locationController,
                      hintText: 'Enter company location',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter company location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    MainButton(
                      text: 'Save Changes',
                      onPressed: _saveCompany,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
