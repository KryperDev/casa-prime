class NotificationSettings {
  final bool memberJoined;
  final bool inviteAccepted;
  final bool transactionAdded;
  final bool transactionUpdated;
  final bool transactionDeleted;
  final bool reportReady;

  const NotificationSettings({
    this.memberJoined = true,
    this.inviteAccepted = true,
    this.transactionAdded = true,
    this.transactionUpdated = true,
    this.transactionDeleted = true,
    this.reportReady = true,
  });

  Map<String, dynamic> toMap() => {
        'memberJoined': memberJoined,
        'inviteAccepted': inviteAccepted,
        'transactionAdded': transactionAdded,
        'transactionUpdated': transactionUpdated,
        'transactionDeleted': transactionDeleted,
        'reportReady': reportReady,
      };

  factory NotificationSettings.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const NotificationSettings();
    return NotificationSettings(
      memberJoined: m['memberJoined'] ?? true,
      inviteAccepted: m['inviteAccepted'] ?? true,
      transactionAdded: m['transactionAdded'] ?? true,
      transactionUpdated: m['transactionUpdated'] ?? true,
      transactionDeleted: m['transactionDeleted'] ?? true,
      reportReady: m['reportReady'] ?? true,
    );
  }

  NotificationSettings copyWith({
    bool? memberJoined,
    bool? inviteAccepted,
    bool? transactionAdded,
    bool? transactionUpdated,
    bool? transactionDeleted,
    bool? reportReady,
  }) =>
      NotificationSettings(
        memberJoined: memberJoined ?? this.memberJoined,
        inviteAccepted: inviteAccepted ?? this.inviteAccepted,
        transactionAdded: transactionAdded ?? this.transactionAdded,
        transactionUpdated: transactionUpdated ?? this.transactionUpdated,
        transactionDeleted: transactionDeleted ?? this.transactionDeleted,
        reportReady: reportReady ?? this.reportReady,
      );
}
