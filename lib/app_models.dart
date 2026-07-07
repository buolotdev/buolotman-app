import 'dart:convert';
import 'package:flutter/material.dart';

class AppUser {
  const AppUser({
    required this.name,
    required this.role,
    required this.tagline,
    required this.avatar,
    this.id = 0,
    this.location = 'Lagos, Nigeria',
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.country = '',
    this.bio = '',
    this.hourlyRate = 0.0,
    this.skills = const [],
    this.certifications = const [],
    this.availabilityStatus = 'available',
    this.experience = '',
  });

  final String name;
  final String role;
  final String tagline;
  final String avatar;
  final int id;
  final String location;
  final String firstName;
  final String lastName;
  final String phone;
  final String country;
  final String bio;
  final double hourlyRate;
  final List<String> skills;
  final List<String> certifications;
  final String availabilityStatus;
  final String experience;

  AppUser copyWith({
    String? name,
    String? role,
    String? tagline,
    String? avatar,
    int? id,
    String? location,
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? bio,
    double? hourlyRate,
    List<String>? skills,
    List<String>? certifications,
    String? availabilityStatus,
    String? experience,
  }) {
    return AppUser(
      name: name ?? this.name,
      role: role ?? this.role,
      tagline: tagline ?? this.tagline,
      avatar: avatar ?? this.avatar,
      id: id ?? this.id,
      location: location ?? this.location,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      experience: experience ?? this.experience,
    );
  }
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.locationType,
    required this.location,
    required this.timeline,
    required this.urgency,
    required this.paymentMethod,
    required this.budget,
    required this.budgetMin,
    required this.budgetMax,
    required this.budgetMode,
    required this.city,
    required this.country,
    required this.duration,
    required this.isRecurring,
    this.deadline,
  });

  final String title;
  final String description;
  final String category;
  final String locationType;
  final String location;
  final String timeline;
  final String urgency;
  final String paymentMethod;
  final double budget;
  final double budgetMin;
  final double budgetMax;
  final String budgetMode;
  final String city;
  final String country;
  final String duration;
  final bool isRecurring;
  final String? deadline;

  TaskDraft copyWith({
    String? title,
    String? description,
    String? category,
    String? locationType,
    String? location,
    String? timeline,
    String? urgency,
    String? paymentMethod,
    double? budget,
    double? budgetMin,
    double? budgetMax,
    String? budgetMode,
    String? city,
    String? country,
    String? duration,
    bool? isRecurring,
    String? deadline,
  }) {
    return TaskDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      locationType: locationType ?? this.locationType,
      location: location ?? this.location,
      timeline: timeline ?? this.timeline,
      urgency: urgency ?? this.urgency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      budget: budget ?? this.budget,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      budgetMode: budgetMode ?? this.budgetMode,
      city: city ?? this.city,
      country: country ?? this.country,
      duration: duration ?? this.duration,
      isRecurring: isRecurring ?? this.isRecurring,
      deadline: deadline ?? this.deadline,
    );
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.clientName,
    required this.clientAvatar,
    required this.clientRating,
    required this.budget,
    required this.status,
    required this.createdLabel,
    required this.schedule,
    required this.urgency,
    required this.paymentMethod,
    required this.tags,
    this.bidsCount = 0,
    this.acceptedBidId,
    this.assignedToId,
    this.assignedToName,
    this.assignedToAvatar,
    this.deadline,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String clientName;
  final String clientAvatar;
  final double clientRating;
  final double budget;
  final String status;
  final String createdLabel;
  final String schedule;
  final String urgency;
  final String paymentMethod;
  final List<String> tags;
  final int bidsCount;
  final String? acceptedBidId;
  final String? assignedToId;
  final String? assignedToName;
  final String? assignedToAvatar;
  final String? deadline;

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    String? clientName,
    String? clientAvatar,
    double? clientRating,
    double? budget,
    String? status,
    String? createdLabel,
    String? schedule,
    String? urgency,
    String? paymentMethod,
    List<String>? tags,
    int? bidsCount,
    String? acceptedBidId,
    String? assignedToId,
    String? assignedToName,
    String? assignedToAvatar,
    String? deadline,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      clientName: clientName ?? this.clientName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      clientRating: clientRating ?? this.clientRating,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      createdLabel: createdLabel ?? this.createdLabel,
      schedule: schedule ?? this.schedule,
      urgency: urgency ?? this.urgency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tags: tags ?? this.tags,
      bidsCount: bidsCount ?? this.bidsCount,
      acceptedBidId: acceptedBidId ?? this.acceptedBidId,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToAvatar: assignedToAvatar ?? this.assignedToAvatar,
      deadline: deadline ?? this.deadline,
    );
  }
}

class BidItem {
  const BidItem({
    required this.id,
    required this.taskId,
    required this.bidderName,
    required this.skill,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.timeline,
    required this.message,
    required this.avatar,
    required this.role,
    this.isBestValue = false,
    this.isAccepted = false,
    this.technicianId,
  });

  final String id;
  final String taskId;
  final String bidderName;
  final String skill;
  final double rating;
  final int reviews;
  final double price;
  final String timeline;
  final String message;
  final String avatar;
  final String role;
  final bool isBestValue;
  final bool isAccepted;
  final String? technicianId;

  BidItem copyWith({
    String? id,
    String? taskId,
    String? bidderName,
    String? skill,
    double? rating,
    int? reviews,
    double? price,
    String? timeline,
    String? message,
    String? avatar,
    String? role,
    bool? isBestValue,
    bool? isAccepted,
    String? technicianId,
  }) {
    return BidItem(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      bidderName: bidderName ?? this.bidderName,
      skill: skill ?? this.skill,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      price: price ?? this.price,
      timeline: timeline ?? this.timeline,
      message: message ?? this.message,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isBestValue: isBestValue ?? this.isBestValue,
      isAccepted: isAccepted ?? this.isAccepted,
      technicianId: technicianId ?? this.technicianId,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });

  final String text;
  final String time;
  final bool isMe;
}

class ChatThread {
  const ChatThread({
    required this.id,
    required this.name,
    required this.image,
    required this.online,
    required this.messages,
    this.lastSeen = 'Offline',
  });

  final String id;
  final String name;
  final String image;
  final bool online;
  final List<ChatMessage> messages;
  final String lastSeen;

  String get lastMessage => messages.isEmpty ? '' : messages.last.text;
  String get lastTime => messages.isEmpty ? '' : messages.last.time;

  ChatThread copyWith({
    String? id,
    String? name,
    String? image,
    bool? online,
    List<ChatMessage>? messages,
    String? lastSeen,
  }) {
    return ChatThread(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      online: online ?? this.online,
      messages: messages ?? this.messages,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.isIncome,
  });

  final String title;
  final String date;
  final String amount;
  final String status;
  final bool isIncome;
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.priceLabel,
    required this.providerName,
    required this.providerAvatar,
    required this.providerRole,
    required this.serviceType,
    required this.coverageArea,
    required this.availability,
    required this.pricingModel,
    required this.providerId,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String priceLabel;
  final String providerName;
  final String providerAvatar;
  final String providerRole;
  final String serviceType;
  final String coverageArea;
  final String availability;
  final String pricingModel;
  final String providerId;
}

ImageProvider getAvatarImageProvider(String avatarUrl) {
  if (avatarUrl.startsWith('data:image/')) {
    final base64Content = avatarUrl.split(',').last;
    return MemoryImage(base64Decode(base64Content));
  }
  if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
    return NetworkImage(avatarUrl);
  }
  return AssetImage(avatarUrl);
}

Widget buildAvatarImage(String avatarUrl, {double? width, double? height, BoxFit fit = BoxFit.cover, Widget? fallback}) {
  if (avatarUrl.startsWith('data:image/')) {
    final base64Content = avatarUrl.split(',').last;
    return Image.memory(
      base64Decode(base64Content),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback ?? Image.asset('assets/images/onboard1.jpg', width: width, height: height, fit: fit),
    );
  }
  if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
    return Image.network(
      avatarUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallback ?? Image.asset('assets/images/onboard1.jpg', width: width, height: height, fit: fit),
    );
  }
  return Image.asset(
    avatarUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => fallback ?? Image.asset('assets/images/onboard1.jpg', width: width, height: height, fit: fit),
  );
}
