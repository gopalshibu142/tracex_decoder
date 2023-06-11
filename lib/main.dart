import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart';
import 'dart:typed_data';

void main() {
  runApp(Decrypt());
}

class Decrypt extends StatelessWidget {
  const Decrypt({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: DecryptBody(),
    );
  }
}

class DecryptBody extends StatefulWidget {
  const DecryptBody({super.key});

  @override
  State<DecryptBody> createState() => _DecryptBodyState();
}

String darrDecrypt(String encryptedText, String key) {
  String decryptedText = '';
  int keyLength = key.length;
  for (int i = 0; i < encryptedText.length; i++) {
    int keyIndex = i % keyLength;
    int keyChar = key.codeUnitAt(keyIndex);
    int decryptedChar = (encryptedText.codeUnitAt(i) - keyChar) % 256;
    decryptedText += String.fromCharCode(decryptedChar);
  }
  print(decryptedText);
  return decryptedText;
}

class _DecryptBodyState extends State<DecryptBody> {
  String imei = 'Imei';

  // String decodeMessage(var frameImage) {
  // String decodedMessage = '';

  // for (var y = 0; y < frameImage.height; y++) {
  //   for (var x = 0; x < frameImage.width; x++) {
  //     int pixel = frameImage.getPixel(x, y);
  //     int messageBit = pixel & 0x01;
  //     decodedMessage += messageBit.toString();
  //   }
  // }

//   return decodedMessage;
//

  List<int> extractSteganography(List<int> frameBytes) {
    List<int> extractedBytes = [];

    int messageLength = _extractLength(frameBytes);
    if (messageLength == 0) {
      return extractedBytes;
    }

    int byteIndex = 4; // Skip the length header
    int bitIndex = 0;
    int currentByte = 0;

    while (extractedBytes.length < messageLength) {
      if (byteIndex >= frameBytes.length) {
        break;
      }

      int bit = _getBit(frameBytes[byteIndex], bitIndex);
      currentByte = _setBit(currentByte, 7, bit);

      bitIndex++;
      if (bitIndex >= 8) {
        extractedBytes.add(currentByte);
        currentByte = 0;
        bitIndex = 0;
      }

      byteIndex++;
    }

    return extractedBytes;
  }

  int _extractLength(List<int> frameBytes) {
    int length = 0;

    for (int i = 0; i < 4; i++) {
      int bit = _getBit(frameBytes[i], 0);
      length = _setBit(length, (i * 8) + 7, bit);
    }

    return length;
  }

  int _getBit(int byte, int index) {
    return (byte >> (7 - index)) & 1;
  }

  int _setBit(int byte, int index, int bit) {
    if (bit == 1) {
      return byte | (1 << (7 - index));
    } else {
      return byte & ~(1 << (7 - index));
    }
  }

  String binaryToString(List<int> binaryMessage) {
    String result = "";

    String binaryByte = "";
    for (int i = 0; i < binaryMessage.length; i += 8) {
      int endIndex = i + 8;
      if (endIndex > binaryMessage.length) {
        endIndex = binaryMessage.length;
      }
      for (int j = 0; j < endIndex - i; j++) {
        binaryByte += binaryMessage[i + j].toString();
      }
    }

    // Remove spaces from the binaryByte string
    binaryByte = binaryByte.replaceAll(' ', '');

    for (int i = 0; i < binaryByte.length; i += 8) {
      int endIndex = i + 8;
      if (endIndex > binaryByte.length) {
        endIndex = binaryByte.length;
      }
      String byteSubstring = binaryByte.substring(i, endIndex);
      int charCode = int.parse(byteSubstring, radix: 2);
      String char = String.fromCharCode(charCode);
      result += char;
    }
    
    print(binaryToStringmsg(binaryMessage));
    //darrDecrypt(result, '43');
    return binaryToStringmsg(binaryMessage);
  }

  String binaryToStringmsg(List<int> binaryMessage) {
  String result = "";

  for (int i = 0; i < binaryMessage.length; i += 8) {
    int endIndex = i + 8;
    if (endIndex > binaryMessage.length) {
      endIndex = binaryMessage.length;
    }
    List<int> byteBinary = binaryMessage.sublist(i, endIndex);
    int charCode = int.parse(byteBinary.join(), radix: 2);
    result += String.fromCharCode(charCode);
  }

  return result;
}

  String decodeMessage(Uint8List videoBytes, int messageLength) {
    List<int> binaryMessage = [];

    for (int i = 0; i < videoBytes.length; i++) {
      int videoByte = videoBytes[i];
      int messageBit = videoByte & 0x01;
      binaryMessage.add(messageBit);
    }

    return binaryToString(binaryMessage).substring(0, messageLength);
  }

  Future<String> decodeMessageFromVideo(File media) async {
    var messageLength = 15;
    final videoBytes = media.readAsBytesSync();
    final flutterFFmpeg = FlutterFFmpeg();
    final Directory? extDir = await getExternalStorageDirectory();
    final testDir = await Directory(
            '${extDir?.path}/img/${DateTime.now().millisecondsSinceEpoch}')
        .create(recursive: true);

    await flutterFFmpeg
        .execute('-i ${media.path} ${testDir.path}/frame-%04d.jpg');

    final frameFiles = Directory(testDir.path)
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.jpg'))
        .map((entity) => entity.path)
        .toList();

    List<File> files = [];
    for (final frameFile in frameFiles) {
      final frameBytes = File(frameFile).readAsBytesSync();
      files.add(File(frameFile));
      final decodedMessage = decodeMessage(frameBytes, messageLength);
      if (decodedMessage.isNotEmpty) {
        print(decodedMessage.toString());
        return decodedMessage;
      }
    }

    throw Exception('No hidden message found in the video.');
  }

  Future<File> getImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    late File file;
    if (result != null) {
      File file = File(result.files.single.path ?? '');
      return file;
    } else {
      return File('');
    }
  }

  void filePick() async {
    File file = await getImage();
    //final file = File(vdo.path);
    decodeMessageFromVideo(file);
    List<int> encodedBytes = await file.readAsBytes();
    int key = 42; // Same key used for encryption

    decryptBytes(encodedBytes, key);
  }

  void decryptBytes(List<int> encodedBytes, int key) {
    List<int> decryptedBytes = [];
    print('decrypting');
    // Decrypt the bytes by XOR operation

    // Convert the decrypted bytes to a string
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ikkaas App'),
      ),
      body: Scaffold(
          body: Container(
        alignment: Alignment.center,
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  filePick();
                },
                child: Text("Upload file")),
            Text('Imei :${imei}')
          ],
        ),
      )),
    );
  }
}
