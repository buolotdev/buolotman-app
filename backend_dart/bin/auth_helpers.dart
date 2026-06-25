import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

Uint8List pbkdf2Sha256(String password, String salt, int iterations, int keyLength) {
  final passwordBytes = utf8.encode(password);
  final saltBytes = utf8.encode(salt);
  
  final hmac = Hmac(sha256, passwordBytes);
  final key = Uint8List(keyLength);
  int offset = 0;
  int blockIndex = 1;
  
  while (offset < keyLength) {
    final blockBuffer = BytesBuilder();
    blockBuffer.add(saltBytes);
    final blockIdxBytes = ByteData(4)..setInt32(0, blockIndex, Endian.big);
    blockBuffer.add(blockIdxBytes.buffer.asUint8List());
    
    final blockBytes = blockBuffer.toBytes();
    var u = hmac.convert(blockBytes).bytes;
    final blockXor = Uint8List.fromList(u);
    
    for (int j = 2; j <= iterations; j++) {
      u = hmac.convert(u).bytes;
      for (int k = 0; k < blockXor.length; k++) {
        blockXor[k] ^= u[k];
      }
    }
    
    final bytesToCopy = (keyLength - offset < blockXor.length) ? (keyLength - offset) : blockXor.length;
    key.setRange(offset, offset + bytesToCopy, blockXor, 0);
    offset += bytesToCopy;
    blockIndex++;
  }
  
  return key;
}

bool verifyPassword(String password, String djangoHash) {
  final parts = djangoHash.split('\$');
  if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') {
    return false;
  }
  final iterations = int.parse(parts[1]);
  final salt = parts[2];
  final hash = parts[3];
  
  final derived = pbkdf2Sha256(password, salt, iterations, 32);
  final derivedB64 = base64.encode(derived);
  return derivedB64 == hash;
}

String generateSalt([int length = 22]) {
  final rand = Random.secure();
  final values = List<int>.generate(length, (i) => rand.nextInt(256));
  return base64Url.encode(values).replaceAll('=', '').replaceAll('-', 'a').replaceAll('_', 'b').substring(0, length);
}

String hashPassword(String password, {int iterations = 100000}) {
  final salt = generateSalt(22);
  final derived = pbkdf2Sha256(password, salt, iterations, 32);
  final hash = base64.encode(derived);
  return 'pbkdf2_sha256\$$iterations\$$salt\$$hash';
}

String base64UrlNoPadding(Uint8List bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

Uint8List base64UrlNoPaddingDecode(String str) {
  var normalized = str;
  while (normalized.length % 4 != 0) {
    normalized += '=';
  }
  return base64Url.decode(normalized);
}

String generateJwt({
  required Map<String, dynamic> payload,
  required String secret,
}) {
  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final headerStr = base64UrlNoPadding(utf8.encode(jsonEncode(header)));
  final payloadStr = base64UrlNoPadding(utf8.encode(jsonEncode(payload)));
  
  final dataToSign = '$headerStr.$payloadStr';
  final hmac = Hmac(sha256, utf8.encode(secret));
  final signature = base64UrlNoPadding(Uint8List.fromList(hmac.convert(utf8.encode(dataToSign)).bytes));
  
  return '$dataToSign.$signature';
}

Map<String, dynamic>? verifyJwt(String token, String secret) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    
    final headerStr = parts[0];
    final payloadStr = parts[1];
    final signatureStr = parts[2];
    
    final dataToSign = '$headerStr.$payloadStr';
    final hmac = Hmac(sha256, utf8.encode(secret));
    final expectedSignature = base64UrlNoPadding(Uint8List.fromList(hmac.convert(utf8.encode(dataToSign)).bytes));
    
    if (signatureStr != expectedSignature) return null;
    
    final payloadJson = utf8.decode(base64UrlNoPaddingDecode(payloadStr));
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    
    if (payload.containsKey('exp')) {
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (now > exp) return null;
    }
    
    return payload;
  } catch (_) {
    return null;
  }
}
