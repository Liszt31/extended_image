import 'dart:typed_data';

import 'package:example/common/image_picker/image_picker.dart';
import 'package:example/common/utils/crop_editor_helper.dart';
import 'package:example/common/utils/crop_editor_helper_canvas.dart';
import 'package:extended_image/extended_image.dart';
import 'package:ff_annotation_route_core/ff_annotation_route_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

@FFRoute(
  name: 'fluttercandies://simpleimageeditor',
  routeName: 'ImageEditor',
  description: 'Crop with image editor.',
  exts: <String, dynamic>{
    'group': 'Simple',
    'order': 6,
  },
)
class SimpleImageEditor extends StatefulWidget {
  @override
  _SimpleImageEditorState createState() => _SimpleImageEditorState();
}

class _SimpleImageEditorState extends State<SimpleImageEditor> {
  final GlobalKey<ExtendedImageEditorState> editorKey =
      GlobalKey<ExtendedImageEditorState>();
  bool _cropping = false;
  Uint8List? resultImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ImageEditor'),
      ),
      body: Row(
        children: [
          ExtendedImage.asset(
            // 'assets/image.jpg',
            // 'assets/sample_crop_image.jpg',
            // 'assets/solar_system.jpg',
            'assets/bg_111.jpg',
            //     "https://firebasestorage.googleapis.com/v0/b/timwork-834b6.appspot.com/o/test%2F%E1%84%90%E1%85%A2%E1%84%8B%E1%85%A7%E1%86%BC%E1%84%80%E1%85%A5%E1%86%AB%E1%84%89%E1%85%A5%E1%86%AF%20%E1%84%8C%E1%85%B5%E1%84%92%E1%85%A11%E1%84%8E%E1%85%B3%E1%86%BC%20%E1%84%8C%E1%85%A5%E1%86%AB%E1%84%8E%E1%85%A6%E1%84%91%E1%85%A7%E1%86%BC%E1%84%86%E1%85%A7%E1%86%AB%E1%84%83%E1%85%A9.png?alt=media&token=ffd14738-dda8-4840-9841-3ab2a2906a85",
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 2,
            fit: BoxFit.contain,
            mode: ExtendedImageMode.editor,
            enableLoadState: true,
            extendedImageEditorKey: editorKey,
            cacheRawData: true,
            initEditorConfigHandler: (ExtendedImageState? state) {
              return EditorConfig(
                  maxScale: 8.0,
                  cropRectPadding: const EdgeInsets.all(20.0),
                  hitTestSize: 20.0,
                  initCropRectType: InitCropRectType.imageRect,
                  cropAspectRatio: CropAspectRatios.ratio4_3,
                  editActionDetailsIsChanged: (EditActionDetails? details) {
                    //print(details?.totalScale);
                  });
            },
          ),
          const SizedBox(width: 20),
          if (resultImage != null)
            ExtendedImage.memory(
              resultImage!,
              width: 400,
              fit: BoxFit.fitWidth,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.crop),
          onPressed: () {
            cropImage();
          }),
    );
  }

  Future<void> cropImage() async {
    if (_cropping) {
      return;
    }
    // final Uint8List fileData = Uint8List.fromList(kIsWeb
    //     ? (await cropImageDataWithDartLibrary(state: editorKey.currentState!))!
    //     : (await cropImageDataWithNativeLibrary(
    //         state: editorKey.currentState!))!);

    final Uint8List fileData = Uint8List.fromList(
        (await cropImageDataWithHtmlCanvas(state: editorKey.currentState!))!);

    setState(() {
      resultImage = fileData;
    });

    // final String? fileFath =
    //     await ImageSaver.save('extended_image_cropped_image.jpg', fileData);
    //
    // showToast('save image : $fileFath');
    _cropping = false;
  }
}
