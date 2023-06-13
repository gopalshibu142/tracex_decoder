import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart';
import 'assets/util.dart';
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
  String imei = 'select file';

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
  String binaryToString(List<int> binaryMessage) {
    String message = '';
    String binaryByte = '';
    for (int i = 0; i < binaryMessage.length; i++) {
      binaryByte += binaryMessage[i].toString();
      if (binaryByte.length == 8) {
        int charCode = int.parse(binaryByte, radix: 2);
        String char = String.fromCharCode(charCode);
        message += char;
        binaryByte = '';
      }
    }
    setState(() {});
    return message;
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

  Future<String> decodeMessageFromVideo(
      File videoFile, int messageLength) async {
    final videoBytes = await videoFile.readAsBytes();
    final flutterFFmpeg = FlutterFFmpeg();
    final Directory? extDir = await getExternalStorageDirectory();
    final testDir = await Directory(
            '${extDir?.path}/img/${DateTime.now().millisecondsSinceEpoch}')
        .create(recursive: true);

    await flutterFFmpeg
        .execute('-i ${videoFile.path} ${testDir.path}/frame-%04d.jpg');

    final frameFiles = Directory(testDir.path)
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.jpg'))
        .map((entity) => entity.path)
        .toList();

    List<File> files = [];
    int totalHiddenBits = 0;
   
    for (final frameFile in frameFiles) {
      final frameBytes = File(frameFile).readAsBytesSync();
      files.add(File(frameFile));
      totalHiddenBits += frameBytes.length;

      if (totalHiddenBits >= messageLength * 8) {
        final decodedMessage = decodeMessage(frameBytes, messageLength);
        if (decodedMessage.isNotEmpty) {
           if (!videoFile.path.contains('VID'))
            imei = imeino;
            else
             imei = 'not found';
          print(decodedMessage);
          return decodedMessage;
        }
      }
    }

    throw Exception('No hidden message found in the video.');
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
    decodeMessageFromVideo(file, 16);
    List<int> encodedBytes = await file.readAsBytes();
    int key = 42; // Same key used for encryption

    //decryptBytes(encodedBytes, key);
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
        title: Text('Decrypt App'),
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
            Text('Imei :${imei}'),
            IconButton(
                onPressed: () {
                  setState(() {
                    imei = 'select file';
                  });
                },
                icon: Icon(Icons.replay)),
          ],
        ),
      )),
    );
  }
}
