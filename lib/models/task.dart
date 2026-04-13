class Task {
  final int? id;
  final String title;
  final String description;
  final String status; // 'pending', 'done'
  final int timestamp;
  bool synced;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'timestamp': timestamp,
      'synced': synced ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      status: map['status'] as String,
      timestamp: map['timestamp'] as int,
      synced: (map['synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'timestamp': timestamp,
      'synced': synced,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      timestamp: json['timestamp'] as int,
      synced: json['synced'] as bool? ?? false,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    int? timestamp,
    bool? synced,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
    );
  }
}
