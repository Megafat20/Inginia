import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/availability_model.dart';
import '../../repositories/provider_repository.dart';

class ProviderPlanningScreen extends StatefulWidget {
  const ProviderPlanningScreen({super.key});

  @override
  State<ProviderPlanningScreen> createState() => _ProviderPlanningScreenState();
}

class _ProviderPlanningScreenState extends State<ProviderPlanningScreen> {
  final _repository = ProviderRepository();
  bool _isLoading = true;

  // Structure locale pour l'édition
  final List<String> _daysIds = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _daysLabels = {
    'monday': 'Lundi',
    'tuesday': 'Mardi',
    'wednesday': 'Mercredi',
    'thursday': 'Jeudi',
    'friday': 'Vendredi',
    'saturday': 'Samedi',
    'sunday': 'Dimanche',
  };

  final Map<String, Availability> _schedule = {};

  @override
  void initState() {
    super.initState();
    _fetchPlanning();
  }

  Future<void> _fetchPlanning() async {
    final list = await _repository.getAvailabilities();
    setState(() {
      for (var day in _daysIds) {
        // Find existing or default
        final existing = list.firstWhere(
          (e) => e.day == day,
          orElse: () => Availability(
            day: day,
            startTime: "09:00",
            endTime: "18:00",
            isActive: false,
          ),
        );
        _schedule[day] = existing;
      }
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      // Filter active only
      final activeSlots = _schedule.values.where((e) => e.isActive).toList();
      await _repository.updateAvailabilities(activeSlots);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Planning enregistré !"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectTime(String day, bool isStart) async {
    final current = _schedule[day]!;
    final timeStr = isStart ? current.startTime : current.endTime;
    final parts = timeStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      setState(() {
        _schedule[day] = Availability(
          day: day,
          startTime: isStart ? formatted : current.startTime,
          endTime: !isStart ? formatted : current.endTime,
          isActive: current.isActive,
        );
      });
    }
  }

  void _toggleDay(String day, bool value) {
    final current = _schedule[day]!;
    setState(() {
      _schedule[day] = Availability(
        day: day,
        startTime: current.startTime,
        endTime: current.endTime,
        isActive: value,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Mon Planning",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Enregistrer le planning",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
      body: _isLoading && _schedule.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _daysIds.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final dayId = _daysIds[index];
                final item = _schedule[dayId]!;
                return _buildDayCard(dayId, item);
              },
            ),
    );
  }

  Widget _buildDayCard(String dayId, Availability item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: item.isActive
            ? Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _daysLabels[dayId]!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: item.isActive ? AppTheme.primary : AppTheme.textLight,
                ),
              ),
              const Spacer(),
              Switch(
                value: item.isActive,
                onChanged: (v) => _toggleDay(dayId, v),
                activeThumbColor: AppTheme.primary,
              ),
            ],
          ),
          if (item.isActive) ...[
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildTimeButton(
                    "De",
                    item.startTime,
                    () => _selectTime(dayId, true),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeButton(
                    "À",
                    item.endTime,
                    () => _selectTime(dayId, false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
