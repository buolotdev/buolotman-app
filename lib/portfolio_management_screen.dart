import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buolot_man_app/app_state.dart';

class PortfolioManagementScreen extends StatefulWidget {
  const PortfolioManagementScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioManagementScreen> createState() => _PortfolioManagementScreenState();
}

class _PortfolioManagementScreenState extends State<PortfolioManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _servicePerformedController = TextEditingController();
  final TextEditingController _projectLocationController = TextEditingController();
  final TextEditingController _clientCompanyController = TextEditingController();
  final TextEditingController _completedDateController = TextEditingController();
  final TextEditingController _projectValueController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();

  File? _pickedImage;
  String? _base64Image;
  File? _pickedBeforeImage;
  String? _base64BeforeImage;

  @override
  void initState() {
    super.initState();
    Get.find<AppState>().syncPortfolio();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _servicePerformedController.dispose();
    _projectLocationController.dispose();
    _clientCompanyController.dispose();
    _completedDateController.dispose();
    _projectValueController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isBeforeImage}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final b64 = 'data:image/\$ext;base64,' + base64Encode(bytes);
      setState(() {
        if (isBeforeImage) {
          _pickedBeforeImage = file;
          _base64BeforeImage = b64;
        } else {
          _pickedImage = file;
          _base64Image = b64;
        }
      });
    }
  }

  Future<void> _addPortfolioItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await Get.find<AppState>().createPortfolioItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        imageUrl: _base64Image ?? '',
        beforeImageUrl: _base64BeforeImage ?? '',
        servicePerformed: _servicePerformedController.text.trim(),
        videoUrl: _videoUrlController.text.trim(),
        projectLocation: _projectLocationController.text.trim(),
        clientCompany: _clientCompanyController.text.trim(),
        completedDate: _completedDateController.text.trim(),
        projectValue: _projectValueController.text.trim(),
      );

      _titleController.clear();
      _descriptionController.clear();
      _categoryController.clear();
      _servicePerformedController.clear();
      _projectLocationController.clear();
      _clientCompanyController.clear();
      _completedDateController.clear();
      _projectValueController.clear();
      _videoUrlController.clear();
      setState(() {
        _pickedImage = null;
        _base64Image = null;
        _pickedBeforeImage = null;
        _base64BeforeImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Portfolio item added')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Add Portfolio Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Project Title *', filled: true, border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(labelText: 'Category *', filled: true, border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _servicePerformedController,
                        decoration: const InputDecoration(labelText: 'Service Performed', filled: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', filled: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientCompanyController,
                        decoration: const InputDecoration(labelText: 'Client/Company Worked For', filled: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _projectLocationController,
                        decoration: const InputDecoration(labelText: 'Project Location', filled: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _completedDateController,
                              decoration: const InputDecoration(labelText: 'Completed Date (YYYY-MM-DD)', filled: true, border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _projectValueController,
                              decoration: const InputDecoration(labelText: 'Approx. Value', filled: true, border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _videoUrlController,
                        decoration: const InputDecoration(labelText: 'Video URL (Optional)', filled: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _pickImage(isBeforeImage: true);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.image),
                              label: Text(_pickedBeforeImage == null ? 'Before Photo' : 'Before Added'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pickedBeforeImage == null ? Colors.grey[200] : Colors.green[100],
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _pickImage(isBeforeImage: false);
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.image),
                              label: Text(_pickedImage == null ? 'After Photo' : 'After Added'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pickedImage == null ? Colors.grey[200] : Colors.green[100],
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _addPortfolioItem();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500)),
                          child: const Text('Add to Portfolio', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Manage Portfolio', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
      ),
      body: GetBuilder<AppState>(
        builder: (appState) {
          if (appState.portfolioItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.collections, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No portfolio items yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showAddModal,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500)),
                    child: const Text('Add Your First Project', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: appState.portfolioItems.length,
                itemBuilder: (context, index) {
                  final item = appState.portfolioItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['image_url'] != null && item['image_url'].toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: item['image_url'].toString().startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(item['image_url'].toString().split(',').last),
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    item['image_url'],
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title'] ?? '',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => appState.removePortfolioItem(item['id']),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(item['category'] ?? '', style: const TextStyle(color: Color(0xFFFF4500), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              if (item['service_performed'] != null && item['service_performed'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('Service: \${item['service_performed']}', style: const TextStyle(fontSize: 14)),
                                ),
                              if (item['client_company'] != null && item['client_company'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('Client: \${item['client_company']}', style: const TextStyle(fontSize: 14)),
                                ),
                              const SizedBox(height: 8),
                              Text(item['description'] ?? '', style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500))),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: const Color(0xFFFF4500),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
