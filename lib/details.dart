class Details {
  String roomId;
  String role;
  String userId;
  String username;

  Details(this.roomId, this.role, this.userId, this.username);

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'role': role,
    'userId': userId,
    'username': username,
  };
}
