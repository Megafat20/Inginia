import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/reservation_model.dart';
import '../../repositories/provider_repository.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class MissionDetailsModal extends StatefulWidget {
  final Reservation reservation;
  final VoidCallback onUpdate;

  const MissionDetailsModal({
    super.key,
    required this.reservation,
    required this.onUpdate,
  });

  @override
  State<MissionDetailsModal> createState() => _MissionDetailsModalState();
}

class _MissionDetailsModalState extends State<MissionDetailsModal> {
  late Reservation _reservation;
  final _repository = ProviderRepository();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
  }

  Future<void> _uploadPhotos(String type) async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      imageQuality: 80,
    );

    if (pickedFiles.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isUploading = true);

      try {
        await _repository.uploadReservationPhotos(
          reservationId: _reservation.id,
          filePaths: pickedFiles.map((f) => f.path).toList(),
          type: type,
        );

        // Refresh local data
        widget.onUpdate();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${pickedFiles.length} photo(s) ajoutée(s) avec succès !",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final apiBase = ApiService.baseUrl;
    // Usually http://10.0.2.2:8000/api
    // We need root: http://10.0.2.2:8000
    final root = apiBase.replaceAll('/api', '');
    return '$root/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.assignment_outlined, color: AppTheme.primary),
                const SizedBox(width: 12),
                const Text(
                  "Détails de la mission",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Center(child: _buildStatusBadge(_reservation.status)),
                  const SizedBox(height: 24),

                  // Info Grid
                  _buildInfoRow(
                    Icons.calendar_today,
                    "Date",
                    "${_reservation.requestedDate.day}/${_reservation.requestedDate.month}/${_reservation.requestedDate.year} à ${_reservation.requestedDate.hour}h${_reservation.requestedDate.minute.toString().padLeft(2, '0')}",
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.work_outline,
                    "Service",
                    _reservation.serviceTitle,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.person_outline,
                    "Prestataire",
                    _reservation.providerName,
                  ),
                  const SizedBox(height: 16),
                  if (_reservation.price != null)
                    _buildInfoRow(
                      Icons.attach_money,
                      "Prix estimé",
                      "${_reservation.price} FCFA",
                    ),

                  const SizedBox(height: 24),
                  const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      _reservation.description ?? "Aucune description.",
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Photos Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Photos (Avant)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_isUploading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_reservation.status != 'completed' &&
                          _reservation.status != 'cancelled' &&
                          _reservation.status != 'declined')
                        TextButton.icon(
                          onPressed: () => _uploadPhotos('before'),
                          icon: const Icon(Icons.add_a_photo, size: 16),
                          label: const Text("Ajouter"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoList(_reservation.photosBefore),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Photos du résultat (Après)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_isUploading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_reservation.status == 'completed' ||
                          _reservation.status == 'in_progress')
                        TextButton.icon(
                          onPressed: () => _uploadPhotos('after'),
                          icon: const Icon(Icons.add_a_photo, size: 16),
                          label: const Text("Ajouter"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoList(
                    _reservation.photosAfter,
                    emptyText: "Aucune photo de réalisation",
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = "En attente";
        break;
      case 'accepted':
      case 'confirmed':
        color = AppTheme.primary;
        label = "Confirmée";
        break;
      case 'in_progress':
        color = Colors.blue;
        label = "En cours";
        break;
      case 'completed':
        color = Colors.green;
        label = "Terminée";
        break;
      case 'cancelled':
        color = Colors.red;
        label = "Annulée";
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoList(
    List<String> photos, {
    String emptyText = "Aucune photo",
  }) {
    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade200,
            style: BorderStyle.none,
          ), // plain
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(emptyText, style: TextStyle(color: Colors.grey.shade400)),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () {
                // Open full screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      body: Center(
                        child: Image.network(_getImageUrl(photos[index])),
                      ),
                    ),
                  ),
                );
              },
              child: Image.network(
                _getImageUrl(photos[index]),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
