enum NotificationType { overBudget, warning, info, success }

class NotificationModel {
  final String           id;
  final String           title;
  final String           message;
  final NotificationType type;
  final DateTime         time;
  bool                   isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.time,
    this.isRead = false,
  });
}