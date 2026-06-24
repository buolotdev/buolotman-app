import 'package:flutter/material.dart';

class AppUser {
  const AppUser({
    required this.name,
    required this.role,
    required this.tagline,
    required this.avatar,
    this.location = 'Lagos, Nigeria',
  });

  final String name;
  final String role;
  final String tagline;
  final String avatar;
  final String location;

  AppUser copyWith({
    String? name,
    String? role,
    String? tagline,
    String? avatar,
    String? location,
  }) {
    return AppUser(
      name: name ?? this.name,
      role: role ?? this.role,
      tagline: tagline ?? this.tagline,
      avatar: avatar ?? this.avatar,
      location: location ?? this.location,
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
    required this.duration,
    required this.isRecurring,
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
  final String duration;
  final bool isRecurring;

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
    String? duration,
    bool? isRecurring,
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
      duration: duration ?? this.duration,
      isRecurring: isRecurring ?? this.isRecurring,
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
  });

  final String id;
  final String name;
  final String image;
  final bool online;
  final List<ChatMessage> messages;

  String get lastMessage => messages.isEmpty ? '' : messages.last.text;
  String get lastTime => messages.isEmpty ? '' : messages.last.time;

  ChatThread copyWith({
    String? id,
    String? name,
    String? image,
    bool? online,
    List<ChatMessage>? messages,
  }) {
    return ChatThread(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      online: online ?? this.online,
      messages: messages ?? this.messages,
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
}

ImageProvider getAvatarImageProvider(String avatarUrl) {
  if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
    return NetworkImage(avatarUrl);
  }
  return AssetImage(avatarUrl);
}

Widget buildAvatarImage(String avatarUrl, {double? width, double? height, BoxFit fit = BoxFit.cover, Widget? fallback}) {
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
