import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:image/image.dart';
import 'package:mime/mime.dart';

Future<Uint8List?> cropImageDataWithHtmlCanvas(
    {required ExtendedImageEditorState state}) async {
  ///crop rect base on raw image
  final Rect? cropRect = state.getCropRect();

  final Uint8List image = state.rawImageData;

  final EditActionDetails editAction = state.editAction!;

  String? mimeType = lookupMimeType('', headerBytes: image);

  String img64 = base64Encode(image);
  html.ImageElement myImageElement = html.ImageElement();
  myImageElement.src = 'data:$mimeType;base64,$img64';

  await myImageElement.onLoad.first; // allow time for browser to render

  html.CanvasElement myCanvas;
  html.CanvasRenderingContext2D ctx;

  ///If cropping is needed create a canvas of the size of the cropped image
  ///else create a canvas of the size of the original image
  if (editAction.needCrop)
    myCanvas = html.CanvasElement(
        width: cropRect!.width.toInt(), height: cropRect.height.toInt());
  else
    myCanvas = html.CanvasElement(
        width: myImageElement.width, height: myImageElement.height);

  ctx = myCanvas.context2D;

  int drawWidth = myCanvas.width!, drawHeight = myCanvas.height!;

  ///This invert flag will be true if the image has been rotated 90 or 270 degrees
  ///if that happens draWidth and drawHeight will have to be inverted
  ///and Flip.vertical and Flip.horizontal will have to be swapped
  bool invert = false;
  if (editAction.hasRotateAngle) {
    if (editAction.rotateAngle == 90 || editAction.rotateAngle == 270) {
      int tmp = myCanvas.width!;
      myCanvas.width = myCanvas.height;
      myCanvas.height = tmp;

      drawWidth = myCanvas.height!;
      drawHeight = myCanvas.width!;
      invert = true;
    }

    ctx.translate(myCanvas.width! / 2, myCanvas.height! / 2);
    ctx.rotate(editAction.rotateAngle * pi / 180);
  } else {
    ctx.translate(myCanvas.width! / 2, myCanvas.height! / 2);
  }

  ///By default extended_image associates
  ///editAction.flipY == true => Flip.horizontal and
  ///editAction.flipX == true => Flip.vertical
  if (editAction.needFlip) {
    late Flip mode;
    if (editAction.flipY && editAction.flipX) {
      mode = Flip.both;
    } else if (editAction.flipY) {
      if (invert)
        mode = Flip.vertical;
      else
        mode = Flip.horizontal;
    } else if (editAction.flipX) {
      if (invert)
        mode = Flip.horizontal;
      else
        mode = Flip.vertical;
    }

    ///ctx.scale() multiplicates its values to the drawWidth and drawHeight
    ///in ctx.drawImageScaledFromSource
    ///so applying ctx.scale(-1, 1) is like saying -drawWidth which means
    ///flip horizontal
    switch (mode) {
      case Flip.horizontal:
        if (invert)
          ctx.scale(1, -1);
        else
          ctx.scale(-1, 1);
        break;
      case Flip.vertical:
        if (invert)
          ctx.scale(-1, 1);
        else
          ctx.scale(1, -1);
        break;
      case Flip.both:
        ctx.scale(-1, -1);
        break;
    }
  }

  ctx.drawImageScaledFromSource(
    myImageElement,
    cropRect!.left,
    cropRect.top,
    cropRect.width,
    cropRect.height,
    -drawWidth / 2,
    -drawHeight / 2,
    drawWidth,
    drawHeight,
  );

  return await getBlobData(await myCanvas.toBlob(mimeType ?? 'image/jpeg'));
}

Future<Uint8List> getBlobData(html.Blob blob) {
  final completer = Completer<Uint8List>();
  final reader = html.FileReader();
  reader.readAsArrayBuffer(blob);
  reader.onLoad.listen((_) => completer.complete(reader.result as Uint8List));
  return completer.future;
}
