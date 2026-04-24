class WebDavBackupConfig {
  const WebDavBackupConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.remotePath,
  });

  final String serverUrl;
  final String username;
  final String password;
  final String remotePath;

  bool get isValid =>
      serverUrl.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      password.trim().isNotEmpty &&
      remotePath.trim().isNotEmpty;
}
