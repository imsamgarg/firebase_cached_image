import 'dart:async';
import 'dart:typed_data';

/// An abstract class representing an encryption manager.
///
/// This class provides methods for encrypting and decrypting data.
/// The return type of the methods can be either synchronous (`Uint8List`) or asynchronous (`Future<Uint8List>`).
///
/// Example
/// ```dart
/// class MyEncryptionManager extends EncryptionManager {
///   @override
///   Future<Uint8List> encrypt(Uint8List data) async {
///     // Encrypt the data
///     return data;
///   }
///
///   @override
///   Future<Uint8List> decrypt(Uint8List encryptedData) async {
///     // Decrypt the data
///     return encryptedData;
///   }
/// }
/// ```
abstract class EncryptionManager {
  /// Encrypts the given data.
  ///
  /// Returns the encrypted data as a `Uint8List`.
  FutureOr<Uint8List> encrypt(Uint8List data);

  /// Decrypts the given encrypted data.
  ///
  /// Returns the decrypted data as a `Uint8List`.
  FutureOr<Uint8List> decrypt(Uint8List encryptedData);
}
