class SplitShare {
  final String userId;
  final String userName;
  final double percent; // 0 a 100

  const SplitShare({
    required this.userId,
    required this.userName,
    required this.percent,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'percent': percent,
      };

  factory SplitShare.fromMap(Map<String, dynamic> m) => SplitShare(
        userId: m['userId'] ?? '',
        userName: m['userName'] ?? '',
        percent: (m['percent'] ?? 0).toDouble(),
      );
}

class Balance {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amount;

  const Balance({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });
}
