import 'package:flutter/material.dart';

import 'app_state.dart';

class CompanyAnalyticsScreen extends StatelessWidget {
  const CompanyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final profile = state.companyProfile ?? const <String, dynamic>{};
        final quotes = state.companyQuotes;
        final services = state.companyServices;
        final profileViews = _number(profile['profile_views']);
        final accepted = quotes.where((q) {
          final status = q['status']?.toString().toLowerCase();
          return status == 'approved' || status == 'accepted';
        }).length;
        final quoteCount = quotes.length;
        final conversion = quoteCount == 0
            ? 0
            : (accepted * 100 / quoteCount).round();
        final completed = _number(profile['completed_tasks']);
        final completedRate = quoteCount == 0
            ? 0
            : (completed * 100 / quoteCount).round();
        final dist = _ratingDistribution(profile);
        final totalReviews = _number(dist['total']);

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            title: const Text('Company analytics'),
            backgroundColor: const Color(0xFF062B52),
            foregroundColor: Colors.white,
          ),
          body: RefreshIndicator(
            onRefresh: () => state.syncAll(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                _sectionTitle('Performance overview'),
                _metricGrid([
                  _metric('Profile views', profileViews.toString()),
                  _metric('Quote requests', quoteCount.toString()),
                  _metric('Conversion rate', '$conversion%'),
                  _metric('Completed projects', completed.toString()),
                  _metric(
                    'Average rating',
                    _decimal(profile['average_rating']),
                  ),
                ]),
                const SizedBox(height: 18),
                _card('Lead conversion funnel', [
                  _bar('Profile views', 100, '$profileViews'),
                  _bar(
                    'Quote requests',
                    quoteCount == 0 ? 0 : 100,
                    '$quoteCount',
                  ),
                  _bar('Accepted quotes', conversion, '$accepted'),
                  _bar('Completed projects', completedRate, '$completed'),
                ]),
                const SizedBox(height: 18),
                _card(
                  'Service performance',
                  services.isEmpty
                      ? [
                          const Text(
                            'No services active.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ]
                      : services
                            .map(
                              (service) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['title']?.toString() ?? 'Service',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF062B52),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${service['views'] ?? 0} views  •  ${service['quotes_count'] ?? 0} quotes  •  ${service['acceptance_rate'] ?? 0}% accepted',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                ),
                const SizedBox(height: 18),
                _card('Traffic sources', [
                  _bar(
                    'Search',
                    _number(profile['traffic_search']),
                    _number(profile['traffic_search']).toString(),
                  ),
                  _bar(
                    'Direct',
                    _number(profile['traffic_direct']),
                    _number(profile['traffic_direct']).toString(),
                  ),
                  _bar(
                    'Recommendations',
                    _number(profile['traffic_recommendations']),
                    _number(profile['traffic_recommendations']).toString(),
                  ),
                  _bar(
                    'External traffic',
                    _number(profile['traffic_external']),
                    _number(profile['traffic_external']).toString(),
                  ),
                ]),
                const SizedBox(height: 18),
                _card('Rating distribution', [
                  for (final stars in ['5', '4', '3', '2', '1'])
                    _bar(
                      '$stars stars',
                      totalReviews == 0
                          ? 0
                          : (_number(dist[stars]) * 100 / totalReviews).round(),
                      _number(dist[stars]).toString(),
                    ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  static int _number(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ??
      (double.tryParse(value?.toString() ?? '') ?? 0).round();
  static String _decimal(dynamic value) =>
      double.tryParse(value?.toString() ?? '')?.toStringAsFixed(2) ?? '0.00';
  static Map<String, dynamic> _ratingDistribution(
    Map<String, dynamic> profile,
  ) {
    final raw = profile['rating_distribution'];
    return raw is Map
        ? raw.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
  }

  static Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Color(0xFF062B52),
      ),
    ),
  );

  static Widget _metricGrid(List<_Metric> metrics) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: metrics
        .map(
          (m) => SizedBox(
            width: 164,
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.label,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.value,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF062B52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(),
  );

  static Widget _card(String title, List<Widget> children) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF062B52),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );

  static Widget _bar(String label, int value, String count) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF334155))),
            Text(
              count,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF062B52),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0, 100) / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFFFF4B13),
          ),
        ),
      ],
    ),
  );
}

class _Metric {
  const _Metric(this.label, this.value);
  final String label;
  final String value;
}

_Metric _metric(String label, String value) => _Metric(label, value);
