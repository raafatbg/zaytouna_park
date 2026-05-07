class FacilityBooking {
  final int id;
  final int customerId;
  final int facilityId;
  final DateTime bookingDate;
  final String checkInTime;
  final String checkOutTime;
  final String? status;
  final double? totalCost;
  final DateTime createdAt;

  FacilityBooking({
    required this.id,
    required this.customerId,
    required this.facilityId,
    required this.bookingDate,
    required this.checkInTime,
    required this.checkOutTime,
    this.status,
    this.totalCost,
    required this.createdAt,
  });

  factory FacilityBooking.fromJson(Map<String, dynamic> json) {
    return FacilityBooking(
      id: json['id'],
      customerId: json['customer_id'],
      facilityId: json['facility_id'],
      bookingDate: DateTime.parse(json['booking_date']),
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      status: json['status'],
      totalCost: json['total_cost']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'facility_id': facilityId,
      'booking_date': bookingDate.toIso8601String().split('T')[0], // Date only
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'status': status,
      'total_cost': totalCost,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
