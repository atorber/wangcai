class GithubSyncConfig {
  const GithubSyncConfig({
    required this.token,
    required this.owner,
    required this.repo,
    required this.path,
    this.branch = 'main',
  });

  final String token;
  final String owner;
  final String repo;
  final String path;
  final String branch;

  bool get isValid =>
      token.trim().isNotEmpty &&
      owner.trim().isNotEmpty &&
      repo.trim().isNotEmpty &&
      path.trim().isNotEmpty;
}
