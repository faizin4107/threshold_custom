import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:lzstring_custom/lzstring_custom.dart';

String compressNoopEncode({String? compress, String? decompress}) =>
    decompress != null
        ? String.fromCharCodes(base64Decode(decompress))
        : "#${base64UrlEncode(compress?.codeUnits ?? "error".codeUnits)}";

String compressLzstring({String? compress, String? decompress}) =>
    decompress != null
        ? LZString.decompressFromBase64Sync(decompress)!
        : "!${LZString.compressToBase64Sync(compress ?? "error")!}";

String compressBzip2({String? compress, String? decompress}) => decompress !=
        null
    ? String.fromCharCodes(BZip2Decoder().decodeBytes(base64Decode(decompress)))
    : "@${base64UrlEncode(BZip2Encoder().encode((compress ?? "error").codeUnits))}";

String compressGzip({String? compress, String? decompress}) => decompress !=
        null
    ? String.fromCharCodes(GZipDecoder().decodeBytes(base64Decode(decompress)))
    : "*${base64UrlEncode(GZipEncoder().encode((compress ?? "error").codeUnits, level: 9))}";

String compressZLib({String? compress, String? decompress}) => decompress !=
        null
    ? String.fromCharCodes(
        const ZLibDecoder().decodeBytes(base64Decode(decompress)))
    : "^${base64UrlEncode(const ZLibEncoder().encode((compress ?? "error").codeUnits, level: 9))}";

String debugCompress(String data) {
  Map<String, String?> all = {
    "RAW": data,
    "NOP": _attempt(() => compressNoopEncode(compress: data)),
    "LZS": _attempt(() => compressLzstring(compress: data)),
    "BZ2": _attempt(() => compressBzip2(compress: data)),
    "GZI": _attempt(() => compressGzip(compress: data)),
    "ZLI": _attempt(() => compressZLib(compress: data)),
  };

  for (String key in all.keys) {
    print("$key: ${all[key]?.length ?? "-1"}: ${all[key] ?? "ERRORED"}");
  }

  print("   ");

  return compress(data);
}

String? _attempt(String Function() f) {
  try {
    return f();
  } catch (ignored) {
    return null;
  }
}

String compress(String data,
        {bool forceEncode = false,
        bool allowLZString = true,
        bool allowBZip2 = true,
        bool allowGZip = true,
        bool allowZLib = true}) =>
    [
      forceEncode ? _attempt(() => compressNoopEncode(compress: data)) : data,
      if (allowLZString) _attempt(() => compressLzstring(compress: data)),
      if (allowBZip2) _attempt(() => compressBzip2(compress: data)),
      if (allowGZip) _attempt(() => compressGzip(compress: data)),
      if (allowZLib) _attempt(() => compressZLib(compress: data)),
    ]
        .where((element) => element != null)
        .reduce((a, b) => a!.length < b!.length ? a : b) ??
    "ERROR";

String decompress(String data) {
  if (data.substring(0, 1) == "!") {
    return compressLzstring(decompress: data.substring(1));
  } else if (data.substring(0, 1) == "@") {
    return compressBzip2(decompress: data.substring(1));
  } else if (data.substring(0, 1) == "*") {
    return compressGzip(decompress: data.substring(1));
  } else if (data.substring(0, 1) == "^") {
    return compressZLib(decompress: data.substring(1));
  } else if (data.substring(0, 1) == "#") {
    return compressNoopEncode(decompress: data.substring(1));
  } else {
    return data;
  }
}
