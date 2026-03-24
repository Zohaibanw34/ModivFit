import 'package:flutter/material.dart';

import 'package:fitness_app/features/home/services/app_api_service.dart';
import 'package:fitness_app/layout/main_layout.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  final AppApiService _apiService = AppApiService();

  String _range = 'week'; // 'day', 'week', 'month'
  bool _loading = true;
  String? _error;
  int _totalSteps = 0;
  int _points = 0;
  List<_StepBar> _bars = const [];

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getStepsSummary(range: _range);
      if (result['ok'] != true) {
        setState(() {
          _error = 'Unable to load steps';
          _loading = false;
        });
        return;
      }
      final data = result['data'] as Map<String, dynamic>;
      final summary = data['data'] as Map<String, dynamic>? ?? data;
      final days = (summary['days'] ?? []) as List;

      int total = 0;
      final bars = <_StepBar>[];
      for (final d in days) {
        final m = (d as Map).cast<String, dynamic>();
        final steps = (m['steps'] ?? 0) is int
            ? m['steps'] as int
            : int.tryParse('${m['steps']}') ?? 0;
        total += steps;
        bars.add(
          _StepBar(
            label: (m['label'] ?? '').toString(),
            steps: steps,
          ),
        );
      }

      setState(() {
        _totalSteps = total;
        _points = (summary['points'] as int?) ?? (total * 10);
        _bars = bars;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to connect to server';
        _loading = false;
      });
    }
  }

  void _changeRange(String range) {
    if (_range == range) return;
    setState(() => _range = range);
    _loadSteps();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Steps',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 0,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TotalHeader(totalSteps: _totalSteps),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Steps',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          DropdownButton<String>(
                            value: _range,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'day',
                                child: Text('Day'),
                              ),
                              DropdownMenuItem(
                                value: 'week',
                                child: Text('Week'),
                              ),
                              DropdownMenuItem(
                                value: 'month',
                                child: Text('Month'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) _changeRange(v);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _bars.isEmpty
                            ? const Center(
                                child: Text('No step data for this range.'),
                              )
                            : _StepsChart(bars: _bars),
                      ),
                      const SizedBox(height: 16),
                      _PointsCard(points: _points),
                    ],
                  ),
                ),
    );
  }
}

class _TotalHeader extends StatelessWidget {
  final int totalSteps;

  const _TotalHeader({required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE0F2FE),
            child: Icon(Icons.directions_walk, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total steps',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                '$totalSteps steps',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_upward, size: 18, color: Colors.green),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  final int points;

  const _PointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Points Earned',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Text(
            '$points',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsChart extends StatelessWidget {
  final List<_StepBar> bars;

  const _StepsChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final maxSteps = bars.fold<int>(0, (m, e) => e.steps > m ? e.steps : m);
    const height = 180.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((bar) {
        final ratio = maxSteps == 0 ? 0.0 : bar.steps / maxSteps;
        final barHeight = ratio * height;
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: height,
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: barHeight,
                  width: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF16A34A), Color(0x9916A34A)],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                bar.label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StepBar {
  final String label;
  final int steps;

  const _StepBar({required this.label, required this.steps});
}

