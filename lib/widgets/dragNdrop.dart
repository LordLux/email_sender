import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';

class Dragndrop extends StatefulWidget {
  final Function(XFile) save;

  const Dragndrop({super.key, required this.save});
  @override
  State<Dragndrop> createState() => _DragndropState();
}

class _DragndropState extends State<Dragndrop> {
  bool _dragging = false;
  bool _isShiftPressed = false;
  Timer? _keyPressTimer;
  String? _originalFilePath;
  bool _isLoadingFile = false;
  XFile? file;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: Colors.white,
      strokeWidth: 1,
      radius: const Radius.circular(10),
      borderType: BorderType.RRect,
      child: SizedBox(
        height: 200,
        child: MouseRegion(
          cursor: file == null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: (details) async {
              if (!_isShiftPressed && file == null) {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  withData: true,
                  lockParentWindow: true,
                  allowMultiple: true,
                  dialogTitle: "Scegliere gli Allegati da Aggiungere alla Email",
                  //allowedExtensions: ['txt', 'excel', 'csv', 'pdf', 'word', 'png', 'jpeg', 'jpg', 'svg'],
                );
                if (result != null && result.files.single.path != null) {
                  XFile pickedFile = XFile(result.files.single.path!); // Convert to XFile
                  file = pickedFile;
                  _originalFilePath = pickedFile.path; // Save the original path
                  if (mounted) setState(() {});
                  await widget.save(pickedFile);
                }
              }
            },
            child: DropTarget(
              onDragDone: (details) async {
                XFile droppedFile = details.files.first;
                file = droppedFile;
                _originalFilePath = droppedFile.path; // Save the original path
                if (mounted) setState(() {});
                await widget.save(droppedFile);
              },
              onDragEntered: (detail) {
                _dragging = true;
                if (mounted) setState(() {});
              },
              onDragExited: (detail) {
                _dragging = false;
                if (mounted) setState(() {});
              },
              child: _isLoadingFile
                  ? Center(child: mat.CircularProgressIndicator(color: FluentTheme.of(context).accentColor))
                  : file == null
                      ? Center(
                          child: Stack(
                            children: [
                              /*Center(child: Transform.translate(offset: const Offset(0, -40), child: const Icon(Icons.description_outlined, size: 45))),
                                                                            Center(child: Transform.translate(offset: const Offset(10, -25), child: const Icon(Icons.add_link_sharp, size: 30))),*/
                              Center(
                                child: Transform.translate(
                                  offset: const Offset(0, -30),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 50),
                                    child: mat.Icon(mat.Icons.file_upload, size: 50, color: Colors.white.withOpacity(.7)),
                                  ),
                                ),
                              ),
                              Center(
                                child: Transform.translate(
                                  offset: const Offset(0, 12.5),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    child: FittedBox(
                                      child: Text(
                                        "Trascina il file qui",
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w100),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Transform.translate(
                                  offset: const Offset(0, 35),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: FittedBox(
                                      child: Text(
                                        "o sfoglia per scegliere un file",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w100,
                                          color: Colors.white.withOpacity(.7),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("File: ${file!.name}"),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: _isShiftPressed ? 170 : 140,
                              child: FilledButton(
                                onPressed: () => _isShiftPressed ? null : null,
                                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(_isShiftPressed ? Colors.red : Colors.green)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_isShiftPressed ? mat.Icons.link_off : mat.Icons.open_in_new_outlined),
                                    const SizedBox(width: 10),
                                    Text(_isShiftPressed ? "Scollega File" : "Apri File"),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
