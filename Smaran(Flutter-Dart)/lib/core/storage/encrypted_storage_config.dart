class EncryptedStorageConfig {
  final String databaseName;
  final String keyAlias;

  const EncryptedStorageConfig({
    this.databaseName = 'smaran.db',
    this.keyAlias = 'smaran_sqlcipher_key',
  });

  String get sqlCipherDescription =>
      'SQLCipher database: $databaseName; key stored via platform keystore alias $keyAlias';
}