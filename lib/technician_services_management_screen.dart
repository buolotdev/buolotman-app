import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';
import 'api_service.dart';

class TechnicianServicesManagementScreen extends StatefulWidget {
  const TechnicianServicesManagementScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianServicesManagementScreen> createState() => _TechnicianServicesManagementScreenState();
}

class _TechnicianServicesManagementScreenState extends State<TechnicianServicesManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _myServices = [];
  
  List<dynamic> _categories = [];
  List<dynamic> _subcategories = [];
  List<dynamic> _services = [];
  
  int? _selectedCategory;
  int? _selectedSubcategory;
  int? _selectedService;
  
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _myServices = await ApiService.instance.fetchTechnicianServices();
      _categories = await ApiService.instance.fetchCategories();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubcategories(int categoryId) async {
    setState(() {
      _selectedCategory = categoryId;
      _selectedSubcategory = null;
      _selectedService = null;
      _subcategories = [];
      _services = [];
      _isLoading = true;
    });
    try {
      _subcategories = await ApiService.instance.fetchSubcategories(categoryId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading subcategories: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServices(int subcategoryId) async {
    setState(() {
      _selectedSubcategory = subcategoryId;
      _selectedService = null;
      _services = [];
      _isLoading = true;
    });
    try {
      _services = await ApiService.instance.fetchServices(subcategoryId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading services: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addService() async {
    if (_selectedService == null) return;
    setState(() => _isAdding = true);
    try {
      await ApiService.instance.publishTechnicianService({'service_id': _selectedService});
      await _loadData();
      setState(() {
        _selectedCategory = null;
        _selectedSubcategory = null;
        _selectedService = null;
        _subcategories = [];
        _services = [];
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service added successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding service: $e')));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _removeService(int id) async {
    try {
      await ApiService.instance.deleteTechnicianService(id);
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service removed.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing service: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('My Services (Hierarchy)', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Link a New Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedCategory,
                        hint: const Text('Select Category'),
                        items: _categories.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name']))).toList(),
                        onChanged: (v) {
                          if (v != null) _loadSubcategories(v);
                        },
                        decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedSubcategory,
                        hint: const Text('Select Subcategory'),
                        items: _subcategories.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name']))).toList(),
                        onChanged: (v) {
                          if (v != null) _loadServices(v);
                        },
                        decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedService,
                        hint: const Text('Select Service'),
                        items: _services.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name']))).toList(),
                        onChanged: (v) {
                          setState(() => _selectedService = v);
                        },
                        decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedService == null || _isAdding ? null : _addService,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4500),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isAdding 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Link Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('My Linked Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                const SizedBox(height: 16),
                if (_myServices.isEmpty)
                  const Text('No services linked yet. Select a service from the hierarchy above.', style: TextStyle(color: Colors.grey))
                else
                  ..._myServices.map((s) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(s['service_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${s["category_name"]} > ${s["subcategory_name"]}'),
                          const SizedBox(height: 4),
                          if (s['is_verified_skill'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Verified Skill', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Unverified', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove Service'),
                              content: const Text('Are you sure you want to unlink this service?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _removeService(s['id']);
                                  },
                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  )).toList(),
              ],
            ),
          ),
    );
  }
}
