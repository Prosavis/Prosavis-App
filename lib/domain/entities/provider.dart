import 'package:equatable/equatable.dart';

class Provider extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String description;
  final List<String> services;
  final List<String> coverPhotos;
  final List<WorkSample> workSamples;
  final ProviderVerification verification;
  final ProviderRating rating;
  final ProviderAvailability availability;
  final Location location;
  final List<String> certifications;
  final int experienceYears;
  final double hourlyRate;
  final bool isOnline;
  final bool isVerified;
  final DateTime joinedAt;
  final int completedJobs;
  final String responseTime;

  const Provider({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.description,
    required this.services,
    required this.coverPhotos,
    required this.workSamples,
    required this.verification,
    required this.rating,
    required this.availability,
    required this.location,
    required this.certifications,
    required this.experienceYears,
    required this.hourlyRate,
    required this.isOnline,
    required this.isVerified,
    required this.joinedAt,
    required this.completedJobs,
    required this.responseTime,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        profileImage,
        description,
        services,
        coverPhotos,
        workSamples,
        verification,
        rating,
        availability,
        location,
        certifications,
        experienceYears,
        hourlyRate,
        isOnline,
        isVerified,
        joinedAt,
        completedJobs,
        responseTime,
      ];
}

class WorkSample extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String category;
  final DateTime completedAt;
  final double rating;

  const WorkSample({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.category,
    required this.completedAt,
    required this.rating,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        images,
        category,
        completedAt,
        rating,
      ];
}

class ProviderVerification extends Equatable {
  final bool identityVerified;
  final bool phoneVerified;
  final bool emailVerified;
  final bool backgroundCheckVerified;
  final List<String> documents;
  final DateTime? verifiedAt;
  final String verificationLevel; // basic, standard, premium

  const ProviderVerification({
    required this.identityVerified,
    required this.phoneVerified,
    required this.emailVerified,
    required this.backgroundCheckVerified,
    required this.documents,
    this.verifiedAt,
    required this.verificationLevel,
  });

  @override
  List<Object?> get props => [
        identityVerified,
        phoneVerified,
        emailVerified,
        backgroundCheckVerified,
        documents,
        verifiedAt,
        verificationLevel,
      ];
}

class ProviderRating extends Equatable {
  final double overall;
  final int totalReviews;
  final Map<int, int> starDistribution; // 1-5 stars -> count
  final double quality;
  final double punctuality;
  final double communication;
  final double value;
  final List<Review> recentReviews;

  const ProviderRating({
    required this.overall,
    required this.totalReviews,
    required this.starDistribution,
    required this.quality,
    required this.punctuality,
    required this.communication,
    required this.value,
    required this.recentReviews,
  });

  @override
  List<Object?> get props => [
        overall,
        totalReviews,
        starDistribution,
        quality,
        punctuality,
        communication,
        value,
        recentReviews,
      ];
}

class ProviderAvailability extends Equatable {
  final Map<String, List<TimeSlot>> weeklySchedule; // day -> time slots
  final List<DateTime> unavailableDates;
  final bool instantBooking;
  final int advanceBookingDays;

  const ProviderAvailability({
    required this.weeklySchedule,
    required this.unavailableDates,
    required this.instantBooking,
    required this.advanceBookingDays,
  });

  @override
  List<Object?> get props => [
        weeklySchedule,
        unavailableDates,
        instantBooking,
        advanceBookingDays,
      ];
}

class TimeSlot extends Equatable {
  final String startTime;
  final String endTime;
  final bool isAvailable;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [startTime, endTime, isAvailable];
}

class Location extends Equatable {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double serviceRadius; // km

  const Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.serviceRadius,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        city,
        state,
        zipCode,
        serviceRadius,
      ];
}

class Review extends Equatable {
  final String id;
  final String clientName;
  final String clientImage;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String serviceType;
  final List<String> images;
  final Map<String, double> ratings; // quality, punctuality, etc.

  const Review({
    required this.id,
    required this.clientName,
    required this.clientImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.serviceType,
    required this.images,
    required this.ratings,
  });

  @override
  List<Object?> get props => [
        id,
        clientName,
        clientImage,
        rating,
        comment,
        createdAt,
        serviceType,
        images,
        ratings,
      ];
} 