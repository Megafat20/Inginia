import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../models/provider_details_model.dart';
import '../../repositories/provider_repository.dart';
import '../../services/location_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/availability_model.dart';

class ReservationModal extends StatefulWidget {
  final int providerId;
  final String providerName;
  final List<Competance> competances;
  final List<Availability> availabilities;

  const ReservationModal({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.competances,
    this.availabilities = const [],
  });

  @override
  State<ReservationModal> createState() => _ReservationModalState();
}

class _ReservationModalState extends State<ReservationModal> {
  final _repository = ProviderRepository();
  final _pageController = PageController();
  final _modalMapController = MapController();

  // State
  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;

  // Form Data
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _selectedCompetanceId;
  String? _addressMode = 'gps'; // 'gps' or 'manual'
  final _addressController = TextEditingController();
  final _addressNotesController = TextEditingController(); // Floor, code, etc.
  final _otherServiceController = TextEditingController();
  final _descriptionController = TextEditingController();
  Position? _currentPosition;

  // Audio Recording
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _audioPath;
  bool _isPlaying = false;

  // Search Logic
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  double? _manualLat;
  double? _manualLng;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _initLocation();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _addressController.dispose();
    _addressNotesController.dispose();
    _otherServiceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/desc_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = null;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      print("Record error: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      print("Stop error: $e");
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioPath == null) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      print("Playback error: $e");
    }
  }

  void _deleteAudio() {
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (file.existsSync()) file.deleteSync();
      setState(() {
        _audioPath = null;
        _isPlaying = false;
      });
      _audioPlayer.stop();
    }
  }

  Future<void> _initLocation() async {
    try {
      final pos = await LocationService().getCurrentLocation();
      if (mounted && pos != null) {
        setState(() => _currentPosition = pos);
        if (_addressMode == 'gps') {
          _moveTo(LatLng(pos.latitude, pos.longitude));
        }
      }
    } catch (_) {}
  }

  // --- Draft Logic ---
  String get _draftKey => 'reservation_draft_${widget.providerId}';

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'date': _selectedDate?.toIso8601String(),
      'time_hour': _selectedTime?.hour,
      'time_minute': _selectedTime?.minute,
      'competance_id': _selectedCompetanceId,
      'address_mode': _addressMode,
      'address': _addressController.text,
      'address_notes': _addressNotesController.text,
      'other_service': _otherServiceController.text,
      'description': _descriptionController.text,
      'saved_at': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_draftKey, jsonEncode(data));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_draftKey);
    if (jsonStr != null) {
      try {
        final data = jsonDecode(jsonStr);
        setState(() {
          if (data['date'] != null) {
            _selectedDate = DateTime.parse(data['date']);
          }
          if (data['time_hour'] != null && data['time_minute'] != null) {
            _selectedTime = TimeOfDay(
              hour: data['time_hour'],
              minute: data['time_minute'],
            );
          }
          _selectedCompetanceId = data['competance_id'];
          _addressMode = data['address_mode'] ?? 'gps';
          _addressController.text = data['address'] ?? '';
          _addressNotesController.text = data['address_notes'] ?? '';
          _otherServiceController.text = data['other_service'] ?? '';
          _descriptionController.text = data['description'] ?? '';
        });
      } catch (e) {
        prefs.remove(_draftKey);
      }
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  void _moveTo(LatLng pos) {
    _modalMapController.move(pos, 15.0);
  }

  // --- Location Search ---
  Timer? _searchDebounce;

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 3) {
        setState(() {
          _locationSuggestions = [];
          _isSearchingLocation = false;
        });
        return;
      }

      if (mounted) setState(() => _isSearchingLocation = true);

      try {
        final results = await LocationService().searchLocations(query);
        if (mounted) {
          setState(() {
            _locationSuggestions = results;
            _isSearchingLocation = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearchingLocation = false);
      }
    });
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final lat = suggestion['lat'];
    final lng = suggestion['lng'];
    setState(() {
      _addressController.text = suggestion['display_name'];
      _manualLat = lat;
      _manualLng = lng;
      _locationSuggestions = [];
    });

    // S'assurer que le rebuild a eu lieu avant de bouger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveTo(LatLng(lat, lng));
    });

    FocusScope.of(context).unfocus();
  }
  // -------------------

  void _nextStep() {
    // Validation per step
    if (_currentStep == 0) {
      if (_selectedDate == null || _selectedTime == null) {
        _showError("Veuillez sélectionner une date et une heure.");
        return;
      }
      if (widget.competances.isNotEmpty && _selectedCompetanceId == null) {
        _showError("Veuillez sélectionner un service.");
        return;
      }
    } else if (_currentStep == 1) {
      if (_addressMode == 'manual' && _addressController.text.trim().isEmpty) {
        _showError("Veuillez saisir une adresse.");
        return;
      }
      if (_addressMode == 'gps' && _currentPosition == null) {
        _showError(
          "Impossible de récupérer votre position GPS. Veuillez saisir l'adresse manuellement.",
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedCompetanceId == -1 &&
          _otherServiceController.text.trim().isEmpty) {
        _showError("Veuillez préciser le service souhaité.");
        return;
      }
      // Description is now optional as per user request
      /*
      if (_descriptionController.text.trim().isEmpty && _audioPath == null) {
        _showError("Veuillez ajouter une description (texte ou audio).");
        return;
      }
      */
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: 300.ms,
        curve: Curves.easeInOut,
      );
      _saveDraft();
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: 300.ms,
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      double? lat = _addressMode == 'gps' ? _currentPosition?.latitude : null;
      double? lng = _addressMode == 'gps' ? _currentPosition?.longitude : null;

      if (_addressMode == 'manual') {
        // Prioritize manually selected coordinates from search suggestions
        if (_manualLat != null && _manualLng != null) {
          lat = _manualLat;
          lng = _manualLng;
        } else if (_addressController.text.isNotEmpty) {
          // Fallback geocoding if user just typed without selecting suggestion
          final coords = await LocationService().geocodeAddress(
            _addressController.text,
          );
          if (coords != null) {
            lat = coords['lat'];
            lng = coords['lng'];
          }
        }
      }

      String finalDescription = _descriptionController.text;
      if (_addressMode == 'manual') {
        finalDescription += "\n\n[Adresse: ${_addressController.text}]";
        if (_addressNotesController.text.isNotEmpty) {
          finalDescription +=
              "\n[Notes Adresse: ${_addressNotesController.text}]";
        }
      }

      await _repository.submitReservation(
        providerId: widget.providerId,
        requestedDate: _selectedDate!,
        time: timeStr,
        description: finalDescription,
        competanceId: _selectedCompetanceId == -1
            ? null
            : _selectedCompetanceId,
        otherService: _selectedCompetanceId == -1
            ? _otherServiceController.text
            : null,
        latitude: lat,
        longitude: lng,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        audioDescriptionPath: _audioPath,
      );

      await _clearDraft();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Pickers ---
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _findFirstAvailableDate(now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime day) {
        if (widget.availabilities.isEmpty) return true;
        // Map DateTime working day to English day string
        final daysOfWeek = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ];
        final dayName = daysOfWeek[day.weekday - 1];
        return widget.availabilities.any(
          (a) => a.day.toLowerCase() == dayName && a.isActive,
        );
      },
      builder: (context, child) => Theme(
        data: AppTheme.lightTheme.copyWith(
          colorScheme: ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  DateTime _findFirstAvailableDate(DateTime start) {
    if (widget.availabilities.isEmpty) return start;
    final daysOfWeek = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    for (int i = 0; i < 90; i++) {
      final date = start.add(Duration(days: i));
      final dayName = daysOfWeek[date.weekday - 1];
      if (widget.availabilities.any(
        (a) => a.day.toLowerCase() == dayName && a.isActive,
      )) {
        return date;
      }
    }
    return start;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: AppTheme.lightTheme.copyWith(
          colorScheme: ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // Taller modal
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          ..._buildRemainingContent(),
        ],
      ),
    );
  }

  List<Widget> _buildRemainingContent() {
    return [
      Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // Header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (_currentStep > 0)
              IconButton(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back),
              ),
            Expanded(
              child: Text(
                "Demande de service",
                textAlign: _currentStep > 0 ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (_currentStep > 0) const SizedBox(width: 48), // balance
          ],
        ),
      ),

      // Progress Bar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: List.generate(_totalSteps, (index) {
            final isActive = index <= _currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 24),

      // Content
      Expanded(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe
          children: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
            _buildStep4(),
          ],
        ),
      ),

      // Footer
      Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Text(
                    _currentStep == _totalSteps - 1
                        ? "Confirmer la demande"
                        : "Suivant",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    ];
  }

  // --- Step Builders ---

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "1. Service et Date",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Choisissez le type de service et le moment souhaité.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          const Text("Service", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ...widget.competances.map((c) {
                final isSelected = _selectedCompetanceId == c.id;
                return ChoiceChip(
                  label: Text("${c.title} (${c.price}F)"),
                  selected: isSelected,
                  selectedColor: AppTheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primary : AppTheme.textDark,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  onSelected: (val) =>
                      setState(() => _selectedCompetanceId = val ? c.id : null),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
              ChoiceChip(
                label: const Text("Autre service..."),
                selected: _selectedCompetanceId == -1,
                selectedColor: AppTheme.primary.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: _selectedCompetanceId == -1
                      ? AppTheme.primary
                      : AppTheme.textDark,
                  fontWeight: _selectedCompetanceId == -1
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                onSelected: (val) =>
                    setState(() => _selectedCompetanceId = val ? -1 : null),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedCompetanceId == -1
                        ? AppTheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            "Date et Heure",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDate == null
                              ? "Sélectionner"
                              : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.access_time, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text(
                          _selectedTime == null
                              ? "Sélectionner"
                              : _selectedTime!.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onAddressModeChanged(String? value) {
    setState(() => _addressMode = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (value == 'gps' && _currentPosition != null) {
        _moveTo(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        );
      } else if (value == 'manual' &&
          _manualLat != null &&
          _manualLng != null) {
        _moveTo(LatLng(_manualLat!, _manualLng!));
      }
    });
  }

  Widget _buildStep2() {
    final activeLat = _addressMode == 'gps'
        ? _currentPosition?.latitude
        : _manualLat;
    final activeLng = _addressMode == 'gps'
        ? _currentPosition?.longitude
        : _manualLng;
    final markerPos = (activeLat != null && activeLng != null)
        ? LatLng(activeLat, activeLng)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "2. Lieu de la prestation",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Où le prestataire doit-il intervenir ?",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Map Preview
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                mapController: _modalMapController,
                options: MapOptions(
                  initialCenter:
                      markerPos ??
                      const LatLng(13.5116, 2.1254), // Default to Niamey
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.inginia.niger',
                  ),
                  if (markerPos != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: markerPos,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.primary,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildRadioOption(
            value: 'gps',
            icon: Icons.my_location,
            title: "Ma position actuelle",
            subtitle: _currentPosition != null
                ? "Position GPS détectée"
                : "Recherche de la position...",
          ),
          const SizedBox(height: 12),
          _buildRadioOption(
            value: 'manual',
            icon: Icons.edit_location_alt,
            title: "Saisir une adresse",
            subtitle: "Rechercher un lieu précis",
          ),

          if (_addressMode == 'manual') ...[
            const SizedBox(height: 24),
            TextFormField(
              controller: _addressController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: "Rechercher une adresse",
                hintText: "Quartier, Rue, repères...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearchingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
            if (_locationSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _locationSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = _locationSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on_outlined, size: 20),
                      title: Text(
                        suggestion['display_name'],
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSuggestion(suggestion),
                    );
                  },
                ),
              ),
            if (_locationSuggestions.isEmpty &&
                _addressController.text.length >= 3 &&
                !_isSearchingLocation)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  "Aucun résultat trouvé pour cette recherche.",
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressNotesController,
              decoration: InputDecoration(
                labelText: "Précisions sur le lieu (Optionnel)",
                hintText: "Étage, porte, indications...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.info_outline),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _addressMode == value;
    return InkWell(
      onTap: () => _onAddressModeChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primary : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "3. Description",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Détaillez votre besoin (texte ou audio).",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Audio Description Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                if (_audioPath == null && !_isRecording)
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Ajouter une description audio",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _startRecording,
                        icon: const Icon(
                          Icons.mic_none_rounded,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                    ],
                  )
                else if (_isRecording)
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Enregistrement en cours...",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      ).animate(onPlay: (c) => c.repeat()).fade().scale(),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _stopRecording,
                        icon: const Icon(
                          Icons.stop_circle_rounded,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ],
                  )
                else if (_audioPath != null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.audiotrack_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Description audio enregistrée",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: _togglePlayback,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: _deleteAudio,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  "Complément d'information par écrit (Optionnel si audio)...",
              fillColor: Colors.grey.shade50,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_selectedCompetanceId == -1) ...[
            const SizedBox(height: 24),
            const Text(
              "Type de service souhaité",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _otherServiceController,
              decoration: InputDecoration(
                hintText: "Ex: Installation spécifique, nettoyage...",
                fillColor: Colors.grey.shade50,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final competance = widget.competances
        .where((c) => c.id == _selectedCompetanceId)
        .firstOrNull;
    final dateStr = _selectedDate != null
        ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
        : "-";
    final timeStr = _selectedTime?.format(context) ?? "-";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "4. Récapitulatif",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Vérifiez les informations avant d'envoyer.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  Icons.person,
                  "Prestataire",
                  widget.providerName,
                ),
                const Divider(height: 30),
                _buildSummaryRow(
                  Icons.work,
                  "Service",
                  _selectedCompetanceId == -1
                      ? _otherServiceController.text
                      : (competance?.title ?? "Non spécifié"),
                ),
                if (competance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 36),
                    child: Text(
                      "${competance.price} FCFA",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                const Divider(height: 30),
                _buildSummaryRow(
                  Icons.event,
                  "Date & Heure",
                  "$dateStr à $timeStr",
                ),
                const Divider(height: 30),
                _buildSummaryRow(
                  Icons.location_on,
                  "Lieu",
                  _addressMode == 'gps'
                      ? "Position GPS actuelle"
                      : _addressController.text,
                ),
                const Divider(height: 30),
                _buildSummaryRow(
                  Icons.description,
                  "Description",
                  _audioPath != null
                      ? "Audio + ${_descriptionController.text.isNotEmpty ? 'Texte' : 'Sans texte'}"
                      : (_descriptionController.text.isNotEmpty
                            ? _descriptionController.text
                            : "Non spécifié"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
