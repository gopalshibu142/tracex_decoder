import 'package:flutter/material.dart';

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart';

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

class _DecryptBodyState extends State<DecryptBody> {
  String msg = 'Imei';

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
// }
  void decodeMessage({required File media}) async {
    String tempFilePath = Directory.systemTemp.path;
    String videoPath = media.path; // Replace with the actual path to your video
    String outputPath =
        tempFilePath; // Replace with the desired path to save the frames
    int frameRate = 30; // Number of frames per second (adjust as needed)

    final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

    String command = '-i $videoPath -vf "fps=$frameRate" $outputPath%04d.jpg';

    int returnCode = await _flutterFFmpeg.execute(command);
    if (returnCode == 0) {
      print('Video frames extracted successfully');
    } else {
      print('Failed to extract video frames');
    }
    String framesPath =
        outputPath; // Replace with the path to the directory containing the extracted frames

    Directory framesDirectory = Directory(framesPath);
    List<File> frameFiles =
        framesDirectory.listSync().whereType<File>().toList();

    for (var i = 0; i < frameFiles.length; i++) {
      File frameFile = frameFiles[i];
      var frameImage = decodeImage(frameFile.readAsBytesSync());

      // Process the frame image as needed
      // ...

      // Example: Display frame dimensions
      print(
          'Frame $i dimensions: ${frameImage!.width} x ${frameImage!.height}');
      // Save the modified video to a file
    }
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
            Text('Imei :')
          ],
        ),
      )),
    );
  }
}
