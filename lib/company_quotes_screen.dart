import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';
import 'chat_screen.dart';

const _quoteNavy = Color(0xFF001F3F);
const _quoteOrange = Color(0xFFFF4500);

class CompanyQuotesScreen extends StatefulWidget {
  const CompanyQuotesScreen({super.key});
  @override
  State<CompanyQuotesScreen> createState() => _CompanyQuotesScreenState();
}

class _CompanyQuotesScreenState extends State<CompanyQuotesScreen> {
  String filter = 'all';
  bool loading = false;
  Future<void> _load() async {
    setState(() => loading = true);
    try {
      await AppStateScope.of(context).syncCompanyQuotes();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AppState>(
    builder: (state) {
      final all = state.companyQuotes;
      final quotes = all
          .where((q) => filter == 'all' || q['status']?.toString() == filter)
          .toList();
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Quote requests',
            style: TextStyle(color: _quoteNavy, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _quoteNavy,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: loading ? null : _load,
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: _quoteOrange,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _stats(all),
              const SizedBox(height: 16),
              _filters(),
              const SizedBox(height: 16),
              if (quotes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 70),
                  child: Center(
                    child: Text(
                      'No quote requests found.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ...quotes.map((q) => _QuoteCard(quote: q, state: state)),
            ],
          ),
        ),
      );
    },
  );
  Widget _stats(List<Map<String, dynamic>> qs) {
    int n(String s) => qs.where((q) => q['status']?.toString() == s).length;
    return Row(
      children: [
        _stat('Total', qs.length),
        _stat('Pending', n('pending')),
        _stat('Approved', n('approved')),
        _stat('Rejected', n('rejected')),
      ],
    );
  }

  Widget _stat(String label, int value) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: _quoteNavy,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    ),
  );
  Widget _filters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: ['all', 'pending', 'approved', 'rejected'].map((v) {
        final selected = filter == v;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              v == 'all'
                  ? 'All quotes'
                  : '${v[0].toUpperCase()}${v.substring(1)}',
            ),
            selected: selected,
            onSelected: (_) => setState(() => filter = v),
            selectedColor: const Color(0xFFFFE5DC),
            labelStyle: TextStyle(
              color: selected ? _quoteOrange : const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: selected ? _quoteOrange : const Color(0xFFE2E8F0),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _QuoteCard extends StatelessWidget {
  final Map<String, dynamic> quote;
  final AppState state;
  const _QuoteCard({required this.quote, required this.state});
  @override
  Widget build(BuildContext context) {
    final status = quote['status']?.toString() ?? 'pending';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => _details(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quote['client_name']?.toString() ?? 'Client',
                      style: const TextStyle(
                        color: _quoteNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _badge(status),
                ],
              ),
              const SizedBox(height: 10),
              _line('Service', quote['service']),
              _line('Budget', quote['budget']),
              _line('Deadline', quote['deadline']),
              _line('Location', quote['location']),
              _line('Priority', quote['priority']),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'View quote details',
                  style: TextStyle(
                    color: _quoteOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            '$label:',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value?.toString().isNotEmpty == true ? value.toString() : 'N/A',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _quoteNavy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _badge(String value) {
    final color = value == 'approved'
        ? const Color(0xFF16A34A)
        : value == 'rejected'
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        value[0].toUpperCase() + value.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _details(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuoteDetails(quote: quote, state: state),
  );
}

class _QuoteDetails extends StatefulWidget {
  final Map<String, dynamic> quote;
  final AppState state;
  const _QuoteDetails({required this.quote, required this.state});
  @override
  State<_QuoteDetails> createState() => _QuoteDetailsState();
}

class _QuoteDetailsState extends State<_QuoteDetails> {
  bool busy = false;
  bool get terminal =>
      ['approved', 'rejected'].contains(widget.quote['status']?.toString());
  Future<void> _update(String status) async {
    setState(() => busy = true);
    try {
      await widget.state.updateCompanyQuote(
        widget.quote['id'].toString(),
        status,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Quote approved and project conversion requested.'
                  : 'Quote rejected.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not update quote: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final name = q['client_name']?.toString() ?? 'Client';
    return DraggableScrollableSheet(
      initialChildSize: .86,
      maxChildSize: .96,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            Text(
              'Quote request details',
              style: const TextStyle(
                color: _quoteNavy,
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _section(
              'Client information',
              'Name: $name\nEmail: ${q['client_email'] ?? 'N/A'}\nPhone: ${q['client_phone'] ?? 'N/A'}',
            ),
            _section('Requested service', '${q['service'] ?? 'N/A'}'),
            _section(
              'Budget and deadline',
              'Budget: ${q['budget'] ?? 'N/A'}\nDeadline: ${q['deadline'] ?? 'N/A'}',
            ),
            _section(
              'Location and priority',
              'Location: ${q['location'] ?? 'N/A'}\nPriority: ${q['priority'] ?? 'N/A'}',
            ),
            _section(
              'Project summary',
              q['project_summary'] ?? 'No summary provided.',
            ),
            _section(
              'Technical details',
              q['technical_details'] ?? 'None provided.',
            ),
            _attachments(q['attachments']),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: name.isEmpty ? null : _message,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message client'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: terminal || busy
                        ? null
                        : () => _update('approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _quoteOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      busy ? 'Updating...' : 'Approve & start project',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: terminal || busy ? null : () => _update('rejected'),
                child: const Text('Reject quote'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String value) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _quoteNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Color(0xFF475569), height: 1.45),
        ),
      ],
    ),
  );
  Widget _attachments(dynamic raw) {
    final files = raw is List ? raw : const [];
    return _section(
      'Attachments',
      files.isEmpty
          ? 'No attachments.'
          : files
                .map(
                  (f) =>
                      '📎 ${f is Map ? (f['name'] ?? f['url'] ?? 'Attachment') : f}',
                )
                .join('\n'),
    );
  }

  void _message() {
    final id = widget.state.threads
        .where((t) => t.name == widget.quote['client_name'])
        .map((t) => t.id)
        .firstOrNull;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          name: widget.quote['client_name']?.toString() ?? 'Client',
          image: '',
          threadId: id,
        ),
      ),
    );
  }
}
