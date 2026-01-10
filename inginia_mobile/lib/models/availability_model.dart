class Availability {
  final String day;
  final String startTime;
  final String endTime;
  final bool isActive;

  Availability({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      day: json['day'],
      startTime: _formatTime(json['start_time']),
      endTime: _formatTime(json['end_time']),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'start_time': startTime, 'end_time': endTime};
  }

  // Helper pour s'assurer qu'on a HH:mm
  static String _formatTime(String time) {
    // Si format "14:00:00", on garde "14:00"
    if (time.length > 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}
