import 'package:equatable/equatable.dart';
import 'provider.dart';

class Booking extends Equatable {
  final String id;
  final String clientId;
  final String providerId;
  final Provider provider;
  final BookingDetails details;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final BookingPayment payment;
  final List<BookingMessage> messages;
  final BookingLocation location;

  const Booking({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.provider,
    required this.details,
    required this.status,
    required this.createdAt,
    required this.scheduledAt,
    this.completedAt,
    required this.payment,
    required this.messages,
    required this.location,
  });

  @override
  List<Object?> get props => [
        id,
        clientId,
        providerId,
        provider,
        details,
        status,
        createdAt,
        scheduledAt,
        completedAt,
        payment,
        messages,
        location,
      ];
}

class BookingDetails extends Equatable {
  final String serviceType;
  final String title;
  final String description;
  final List<String> requirements;
  final int estimatedDuration; // in minutes
  final List<String> images;
  final Map<String, dynamic> additionalInfo;

  const BookingDetails({
    required this.serviceType,
    required this.title,
    required this.description,
    required this.requirements,
    required this.estimatedDuration,
    required this.images,
    required this.additionalInfo,
  });

  @override
  List<Object?> get props => [
        serviceType,
        title,
        description,
        requirements,
        estimatedDuration,
        images,
        additionalInfo,
      ];
}

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  disputed,
}

class BookingPayment extends Equatable {
  final double amount;
  final double serviceFee;
  final double totalAmount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime? paidAt;

  const BookingPayment({
    required this.amount,
    required this.serviceFee,
    required this.totalAmount,
    required this.currency,
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
  });

  @override
  List<Object?> get props => [
        amount,
        serviceFee,
        totalAmount,
        currency,
        method,
        status,
        transactionId,
        paidAt,
      ];
}

enum PaymentMethod {
  card,
  paypal,
  bankTransfer,
  cash,
  pse,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

class BookingLocation extends Equatable {
  final String address;
  final double latitude;
  final double longitude;
  final String? apartmentNumber;
  final String? additionalInstructions;
  final String city;
  final String zipCode;

  const BookingLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.apartmentNumber,
    this.additionalInstructions,
    required this.city,
    required this.zipCode,
  });

  @override
  List<Object?> get props => [
        address,
        latitude,
        longitude,
        apartmentNumber,
        additionalInstructions,
        city,
        zipCode,
      ];
}

class BookingMessage extends Equatable {
  final String id;
  final String senderId;
  final String message;
  final DateTime sentAt;
  final bool isFromClient;
  final MessageType type;
  final List<String>? attachments;

  const BookingMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.sentAt,
    required this.isFromClient,
    required this.type,
    this.attachments,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        message,
        sentAt,
        isFromClient,
        type,
        attachments,
      ];
}

enum MessageType {
  text,
  image,
  system,
  payment,
}

class TimeSlotSelection extends Equatable {
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final double? priceModifier; // surge pricing

  const TimeSlotSelection({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.priceModifier,
  });

  @override
  List<Object?> get props => [
        date,
        startTime,
        endTime,
        isAvailable,
        priceModifier,
      ];
} 