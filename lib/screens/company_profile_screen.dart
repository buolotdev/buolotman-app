import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_service.dart';
import '../core/username_utils.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});
  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      bg = Color(0xFFF5F7FA),
      muted = Color(0xFF64748B);
  final api = ApiService();
  final username = TextEditingController();
  final form = <String, TextEditingController>{};
  bool loading = true,
      saving = false,
      uploadingLogo = false,
      uploadingCover = false;
  Map<String, dynamic> profile = {};
  List<dynamic> documents = [];
  String? logoUrl, coverUrl;
  String _initialUsername = '';

  final fields = const [
    ('company_name', 'Company name', TextInputType.text),
    ('registration_number', 'Registration number', TextInputType.text),
    ('company_size', 'Company size', TextInputType.text),
    ('year_founded', 'Year founded', TextInputType.number),
    ('industry', 'Industry', TextInputType.text),
    ('subject_title', 'Subject / title', TextInputType.text),
    ('country', 'Country', TextInputType.text),
    ('city', 'City', TextInputType.text),
    ('headquarters', 'Headquarters', TextInputType.streetAddress),
    (
      'latitude',
      'Latitude',
      TextInputType.numberWithOptions(decimal: true, signed: true),
    ),
    (
      'longitude',
      'Longitude',
      TextInputType.numberWithOptions(decimal: true, signed: true),
    ),
    ('website', 'Website', TextInputType.url),
    ('team_size', 'Team size', TextInputType.number),
    ('response_time', 'Response time', TextInputType.text),
  ];

  @override
  void initState() {
    super.initState();
    for (final f in fields) {
      form[f.$1] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in form.values) {
      c.dispose();
    }
    username.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<dynamic>([
        api.companyProfile(),
        api.companyVerificationDocuments(),
        api.profile(),
      ]);
      final data = Map<String, dynamic>.from(values[0] as Map);
      if (!mounted) return;
      profile = data;
      final account = Map<String, dynamic>.from(values[2] as Map);
      username.text = normalizeUsername('${account['username'] ?? ''}');
      _initialUsername = username.text;
      for (final f in fields) {
        form[f.$1]!.text = data[f.$1]?.toString() ?? '';
      }
      logoUrl = data['logo_url']?.toString();
      coverUrl = data['cover_url']?.toString();
      documents = values[1] is List ? values[1] as List : [];
      setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _snack('Could not load company profile.');
      }
    }
  }

  Future<void> _uploadDocument(String title, String type) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
      withData: true,
    );
    if (!mounted || result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    if (file.bytes!.length > 25 * 1024 * 1024) {
      _snack('Documents must be 25 MB or smaller.');
      return;
    }
    try {
      final upload = await api.uploadCompanyVerificationDocumentBytes(
        bytes: file.bytes!,
        filename: file.name,
        documentType: type,
      );
      if (upload is! Map || upload['id'] == null)
        throw const ApiException('Upload returned no document record.', 500);
      documents = await api.companyVerificationDocuments();
      if (mounted) {
        setState(() {});
        _snack('$title uploaded for admin verification.');
      }
    } catch (e) {
      if (mounted)
        _snack(e is ApiException ? e.message : 'Document upload failed.');
    }
  }

  Future<void> _deleteDocument(dynamic id) async {
    try {
      await api.deleteCompanyVerificationDocument(id);
      documents = await api.companyVerificationDocuments();
      if (mounted) {
        setState(() {});
        _snack('Document deleted.');
      }
    } catch (e) {
      if (mounted)
        _snack(e is ApiException ? e.message : 'Could not delete document.');
    }
  }

  void _preview(String url) => showDialog(
    context: context,
    builder: (_) => Dialog(
      child: InteractiveViewer(
        child: Image.network(
          _url(url),
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Preview unavailable.'),
          ),
        ),
      ),
    ),
  );

  List<String> _array(String key) {
    final v = profile[key];
    return v is List
        ? v.map((x) => '$x'.trim()).where((x) => x.isNotEmpty).toList()
        : [];
  }

  Future<void> _save() async {
    final normalizedUsername = normalizeUsername(username.text);
    final usernameError = validateUsername(normalizedUsername);
    if (usernameError != null) {
      _snack(usernameError);
      return;
    }
    if (normalizedUsername != _initialUsername) {
      try {
        final result = await api.checkUsernameAvailability(normalizedUsername);
        if (result['available'] != true) {
          _snack('That username is already taken.');
          return;
        }
      } catch (_) {
        _snack('We could not verify username availability.');
        return;
      }
    }
    setState(() => saving = true);
    try {
      final data = <String, dynamic>{};
      for (final f in fields) {
        final value = form[f.$1]!.text.trim();
        if (f.$1 == 'team_size') {
          data[f.$1] = int.tryParse(value) ?? 0;
        } else {
          data[f.$1] = value;
        }
      }
      data['services_offered'] = _comma(profile['services_offered']);
      data['areas_of_expertise'] = _comma(profile['areas_of_expertise']);
      data['business_hours'] = _comma(profile['business_hours']);
      if (logoUrl != null) data['logo_url'] = logoUrl;
      if (coverUrl != null) data['cover_url'] = coverUrl;
      await api.updateProfile({'username': normalizedUsername});
      final saved = await api.updateCompanyProfile(data);
      profile = saved;
      if (mounted) _snack('Company profile saved.');
    } catch (e) {
      if (mounted)
        _snack(
          e is ApiException ? e.message : 'Could not save company profile.',
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  List<String> _comma(dynamic value) => value is List
      ? value.map((x) => '$x'.trim()).where((x) => x.isNotEmpty).toList()
      : (value
                ?.toString()
                .split(',')
                .map((x) => x.trim())
                .where((x) => x.isNotEmpty)
                .toList() ??
            []);
  Future<void> _upload(bool cover) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (!mounted || image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.length > 25 * 1024 * 1024) {
      _snack('Images must be 25 MB or smaller.');
      return;
    }
    setState(() {
      if (cover)
        uploadingCover = true;
      else
        uploadingLogo = true;
    });
    try {
      final url = cover
          ? await api.uploadBannerBytes(bytes: bytes, filename: image.name)
          : await api.uploadAvatarBytes(bytes: bytes, filename: image.name);
      await api.updateCompanyProfile({(cover ? 'cover_url' : 'logo_url'): url});
      if (mounted)
        setState(() {
          if (cover)
            coverUrl = url;
          else
            logoUrl = url;
        });
      _snack(cover ? 'Company banner updated.' : 'Company logo updated.');
    } catch (e) {
      if (mounted)
        _snack(e is ApiException ? e.message : 'Image upload failed.');
    } finally {
      if (mounted)
        setState(() {
          if (cover)
            uploadingCover = false;
          else
            uploadingLogo = false;
        });
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  String _url(String? value) =>
      value == null || value.isEmpty ? '' : api.resolveImageUrl(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Company profile'),
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: Text(
              saving ? 'Saving...' : 'Save',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _branding(),
                _section('Company information', [
                  _accountField('Username', username),
                  ...fields.map((f) => _field(f.$1, f.$2, f.$3)),
                ]),
                _arraySection('Services offered', 'services_offered'),
                _arraySection('Areas of expertise', 'areas_of_expertise'),
                _arraySection('Business hours', 'business_hours'),
                _verification(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save company profile'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _branding() {
    final banner = coverUrl != null && coverUrl!.isNotEmpty;
    final logo = logoUrl != null && logoUrl!.isNotEmpty;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company branding',
              style: TextStyle(
                color: navy,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            banner
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _url(coverUrl),
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback('Banner'),
                    ),
                  )
                : _imageFallback('Banner'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: uploadingCover ? null : () => _upload(true),
              icon: const Icon(Icons.image_outlined),
              label: Text(uploadingCover ? 'Uploading...' : 'Change banner'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: orange,
                  backgroundImage: logo ? NetworkImage(_url(logoUrl)) : null,
                  child: logo
                      ? null
                      : const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 14),
                OutlinedButton.icon(
                  onPressed: uploadingLogo ? null : () => _upload(false),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(uploadingLogo ? 'Uploading...' : 'Change logo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(String text) => Container(
    height: 130,
    width: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFE2E8F0),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(color: muted)),
  );
  Widget _section(String title, List<Widget> children) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(top: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
  Widget _field(String key, String label, TextInputType type) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: form[key],
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _accountField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.alternate_email),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
  Widget _arraySection(String label, String key) => _section(label, [
    TextFormField(
      initialValue: _array(key).join(', '),
      maxLines: key == 'business_hours' ? 3 : 2,
      onChanged: (v) => profile[key] = v
          .split(',')
          .map((x) => x.trim())
          .where((x) => x.isNotEmpty)
          .toList(),
      decoration: InputDecoration(
        labelText: key == 'business_hours'
            ? 'Add hours separated by commas'
            : 'Comma-separated values',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  ]);
  Widget _verification() {
    final verified = profile['is_verified'] == true;
    return _section('Company verification', [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          verified ? Icons.verified : Icons.pending_outlined,
          color: verified ? Colors.green : orange,
        ),
        title: Text(
          verified ? 'Approved' : 'Pending admin verification',
          style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          verified
              ? 'Your company profile is verified.'
              : 'Verification status is controlled by the administrator.',
          style: const TextStyle(color: muted),
        ),
      ),
      _docSlot(
        'RCCM Certificate',
        'Corporate registration certificate',
        'certificate',
      ),
      _docSlot(
        'IFU Tax Certificate',
        'Official tax certificate',
        'certificate',
      ),
      _docSlot(
        'Representative Authorization',
        'Authorization for company representative',
        'id',
      ),
      const SizedBox(height: 12),
      if (documents.isEmpty)
        const Text('No documents uploaded yet.', style: TextStyle(color: muted))
      else
        ...documents.map(
          (doc) => Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.file_present, color: orange),
              title: Text(
                '${doc['file_name'] ?? doc['document_type'] ?? 'Legal document'}',
              ),
              subtitle: Text(
                doc['status'] == 'approved'
                    ? 'Verified'
                    : '${doc['status'] ?? 'Under review'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ('${doc['file_url'] ?? ''}'.isNotEmpty)
                    IconButton(
                      onPressed: () => _preview('${doc['file_url']}'),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                  IconButton(
                    onPressed: () => _deleteDocument(doc['id']),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _docSlot(String title, String subtitle, String type) => Card(
    elevation: 0,
    child: ListTile(
      leading: const Icon(Icons.description_outlined, color: orange),
      title: Text(
        title,
        style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: muted)),
      trailing: OutlinedButton(
        onPressed: () => _uploadDocument(title, type),
        child: const Text('Upload'),
      ),
    ),
  );
}
