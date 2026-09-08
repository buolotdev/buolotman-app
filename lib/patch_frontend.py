import os

settings_path = r'c:\Users\Haram\Desktop\buolot-man-app\lib\technician_profile_settings_screen.dart'
with open(settings_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update TabController length
if 'length: 8' in content:
    content = content.replace('length: 8', 'length: 9')

# 2. Add Portfolio Tab
target_tab = "Tab(text: 'References'),"
if target_tab in content and "Tab(text: 'Portfolio')" not in content:
    content = content.replace(target_tab, target_tab + "\n              Tab(text: 'Portfolio'),")

# 3. Add _buildPortfolioTab() in TabBarView
target_view = "_buildReferencesTab(),"
if target_view in content and "_buildPortfolioTab()" not in content:
    content = content.replace(target_view, target_view + "\n                    // Tab 9: Portfolio\n                    _buildPortfolioTab(),")

# 4. Add _buildPortfolioTab Method
portfolio_method = """
  Widget _buildPortfolioTab() {
    return GetBuilder<AppState>(
      builder: (appState) {
        final items = appState.portfolioItems;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Portfolio & Previous Work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 8),
            const Text('Add projects to prove your skills to clients.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No portfolio items added yet.')))
            else
              ...items.map((item) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(item['title'] ?? 'Project', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['description'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {},
                  ),
                ),
              )).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Get.snackbar('Coming Soon', 'Portfolio management will be fully integrated in the next update!');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500)),
              child: const Text('Add Portfolio Project'),
            ),
          ],
        );
      },
    );
  }
"""
if '_buildPortfolioTab()' in content and 'Widget _buildPortfolioTab()' not in content:
    # insert before _buildPayoutSettingsTab
    target_method = "  Widget _buildPayoutSettingsTab() {"
    content = content.replace(target_method, portfolio_method + "\n" + target_method)

# 5. Replace Skills text field with better selector placeholder
skills_target = "_buildTextField('Skills (comma separated)', _skillsController),"
skills_replacement = """
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Service Categories & Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_skillsController.text.isEmpty ? 'Select your services...' : _skillsController.text),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                           // Open category selector modal
                           Get.bottomSheet(
                             Container(
                               color: Colors.white,
                               padding: const EdgeInsets.all(20),
                               child: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   const Text('Select Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                   const SizedBox(height: 16),
                                   ListTile(
                                     title: const Text('Electrical Engineering Services'),
                                     subtitle: const Text('Residential, Commercial, Solar...'),
                                     onTap: () {
                                        setState(() {
                                            _skillsController.text = 'Electrical Engineering, Solar PV, Residential Electrical';
                                        });
                                        Get.back();
                                     },
                                   ),
                                   ListTile(
                                     title: const Text('Plumbing Services'),
                                     onTap: () {
                                        setState(() {
                                            _skillsController.text = 'Pipe Fitting, Water Heaters';
                                        });
                                        Get.back();
                                     },
                                   ),
                                 ]
                               )
                             )
                           );
                        },
                      ),
                      const Divider(),
"""
if skills_target in content:
    content = content.replace(skills_target, skills_replacement)

with open(settings_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("technician_profile_settings_screen.dart patched successfully.")
