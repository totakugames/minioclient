import 'dart:convert';

class ConnectionProfile {
  final String id;
  final String name;
  final String endpoint;
  final int port;
  final bool useSSL;
  final String accessKey;
  final String secretKey;

  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.port,
    required this.useSSL,
    required this.accessKey,
    required this.secretKey,
  });

  ConnectionProfile copyWith({
    String? id,
    String? name,
    String? endpoint,
    int? port,
    bool? useSSL,
    String? accessKey,
    String? secretKey,
  }) {
    return ConnectionProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      port: port ?? this.port,
      useSSL: useSSL ?? this.useSSL,
      accessKey: accessKey ?? this.accessKey,
      secretKey: secretKey ?? this.secretKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'endpoint': endpoint,
        'port': port,
        'useSSL': useSSL,
        'accessKey': accessKey,
        'secretKey': secretKey,
      };

  factory ConnectionProfile.fromJson(Map<String, dynamic> json) {
    return ConnectionProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      endpoint: json['endpoint'] as String,
      port: json['port'] as int,
      useSSL: json['useSSL'] as bool,
      accessKey: json['accessKey'] as String,
      secretKey: json['secretKey'] as String,
    );
  }

  String encode() => jsonEncode(toJson());

  factory ConnectionProfile.decode(String source) =>
      ConnectionProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
