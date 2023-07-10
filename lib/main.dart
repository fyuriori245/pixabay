import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PixabayPage(),
    );
  }
}

class PixabayPage extends StatefulWidget {
  const PixabayPage({super.key});

  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {
  //初めはkらのリストを入れておく
  List<PixabayImage> pixabayImages = [];

//webAPIを通して画像を取得する
  Future<void> fetchImages(String text) async {
    final response = await Dio().get(
      'https://pixabay.com/api',
      queryParameters: {
        'key': '_ここには各々のkeyが入ります_',
        'q': text,
        'image_type': 'photo',
        'per_page': 100,
      },
    );
    final List hits = response.data['hits'];
    pixabayImages = hits.map(
      (e) {
        return PixabayImage.fromMap(e);
      },
    ).toList();
    setState(() {});
  }

//画像をシェアする
  Future<void> shareImage(String url) async {
    final dir = await getTemporaryDirectory();
    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final imageFile =
        await File('${dir.path}/image.png').writeAsBytes(response.data);
    await Share.shareXFiles([XFile(imageFile.path)]);
  }

  @override
  void initState() {
    super.initState();
    fetchImages('花');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          initialValue: '花',
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
          ),
          onFieldSubmitted: (text) {
            // print(text);
            fetchImages(text);
          },
        ),
      ),
      body: GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: pixabayImages.length,
        itemBuilder: (context, index) {
          final pixabayImage = pixabayImages[index];
          return InkWell(
            onTap: () async {
              shareImage(pixabayImage.webformatURL);
            },
            child: Stack(fit: StackFit.expand, children: [
              Image.network(
                pixabayImage.previewURL,
                fit: BoxFit.cover,
              ),
              Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                      color: Colors.white,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 14,
                          ),
                          Text('${pixabayImage.likes}'),
                        ],
                      ))),
            ]),
          );
        },
      ),
    );
  }
}

class PixabayImage {
  final String webformatURL;
  final String previewURL;
  final int likes;

  PixabayImage(
      {required this.webformatURL,
      required this.previewURL,
      required this.likes});

  factory PixabayImage.fromMap(Map<String, dynamic> map) {
    return PixabayImage(
      previewURL: map['previewURL'],
      likes: map['likes'],
      webformatURL: map['webformatURL'],
    );
  }
}
