import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'firebase_options.dart';
import 'classifier.dart';

double _diffFromBytes(Map<String, dynamic> args) {
  final queryBytes = args["query"] as Uint8List?;
  final targetBytes = args["target"] as Uint8List?;
  final size = args["size"] as int? ?? 300;

  if (queryBytes == null || targetBytes == null) return 100;

  final queryImage = img.decodeImage(queryBytes);
  final targetImage = img.decodeImage(targetBytes);
  if (queryImage == null || targetImage == null) return 100;

  final queryResized = img.copyResize(queryImage, width: size, height: size);
  final targetResized = img.copyResize(targetImage, width: size, height: size);

  final width = min(queryResized.width, targetResized.width);
  final height = min(queryResized.height, targetResized.height);
  double diff = 0;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pixelA = queryResized.getPixel(x, y);
      final pixelB = targetResized.getPixel(x, y);
      diff += (pixelA.r - pixelB.r).abs();
      diff += (pixelA.g - pixelB.g).abs();
      diff += (pixelA.b - pixelB.b).abs();
    }
  }

  final maxDiff = width * height * 3 * 255;
  return (diff / maxDiff) * 100;
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>>? _outputs;
  File? _image;
  Uint8List? _imageBytes;
  bool _loading = false;
  String _collectionName = "images";
  Uint8List? _queryBytes;
  List<double>? _sortedDiffs;
  List<int>? _sortedIndices;
  QuerySnapshot<Map<String, dynamic>>? _snapshotData;
  bool _isSorting = false;
  double _sortProgress = 0.0;
  final LinkedHashMap<String, Uint8List> _imageCache = LinkedHashMap();
  static const int _imageCacheLimit = 30;
  late final ImageClassifier _classifier;

  late final AnimationController _animationController;
  late final Animation<double> _degOneTranslationAnimation;
  late final Animation<double> _degTwoTranslationAnimation;
  late final Animation<double> _degThreeTranslationAnimation;
  late final Animation<double> _rotationAnimation;

  double getRadiansFromDegree(double degree) {
    const unitRadian = 57.295779513;
    return degree / unitRadian;
  }

  @override
  void initState() {
    super.initState();

    _classifier = ImageClassifier();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _degOneTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.2), weight: 75.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.2, end: 1.0), weight: 25.0),
    ]).animate(_animationController);
    _degTwoTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.4), weight: 55.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.4, end: 1.0), weight: 45.0),
    ]).animate(_animationController);
    _degThreeTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.75), weight: 35.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.75, end: 1.0), weight: 65.0),
    ]).animate(_animationController);
    _rotationAnimation = Tween<double>(begin: 180.0, end: 0.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.addListener(() {
      setState(() {});
    });

    _loading = true;
    loadModel().then((_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('CBIR PROJECT'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height / 1.0,
                width: MediaQuery.of(context).size.width,
                child: ListView(children: [
                  const SizedBox(
                    height: 100,
                  ),
                  (_image == null && _imageBytes == null)
                      ? Container()
                      : kIsWeb
                          ? Image.memory(
                              _imageBytes!,
                              height: 200,
                            )
                          : Image.file(
                              _image!,
                              height: 200,
                            ),
                  const SizedBox(
                    height: 20,
                  ),
                  _outputs != null
                      ? Center(
                          child: Text(
                          "${'Flower type:' + ' ' + _outputs![0]["label"] + ' ' + '(' + (_outputs![0]["confidence"] * 100).toStringAsFixed(0) + '%)'}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                          ),
                        ))
                      : Container(),
                  const SizedBox(
                    height: 20,
                  ),
                  _outputs != null ? _textSection : Container(),
                  _isSorting
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: LinearProgressIndicator(
                            value: _sortProgress,
                          ),
                        )
                      : Container(),
                  FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: getImages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Text("No data");
                      }

                      _snapshotData = snapshot.data;
                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                          physics: const ScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: docs.length,
                          itemBuilder: (BuildContext context, int index) {
                            final docIndex = _sortedIndices != null
                                ? _sortedIndices![index]
                                : index;
                            final data = docs[docIndex].data();
                            final imageUrl = data["url"] as String?;
                            final name = data["name"] as String?;
                            final similarity = (_sortedDiffs != null &&
                                    index < _sortedDiffs!.length)
                                ? (100 - _sortedDiffs![index])
                                : null;

                            return Card(
                                color: Colors.grey[100],
                                semanticContainer: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 5,
                                margin: const EdgeInsets.all(10),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(25.0),
                                  leading: imageUrl == null
                                      ? const SizedBox.shrink()
                                      : Image.network(imageUrl,
                                          fit: BoxFit.fill),
                                  title: Text(
                                    name ?? "Unknown",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                    ),
                                  ),
                                  subtitle: similarity != null
                                      ? Text(
                                          'Similarity: ${similarity.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 20.0,
                                          ),
                                        )
                                      : Container(),
                                ));
                          });
                    },
                  ),
                ])),
        floatingActionButton: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(children: <Widget>[
              Positioned(
                  right: 10,
                  bottom: 10,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      IgnorePointer(
                        child: Container(
                          color: Colors.black.withOpacity(0.0),
                          height: 150.0,
                          width: 150.0,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset.fromDirection(getRadiansFromDegree(270),
                            _degOneTranslationAnimation.value * 100),
                        child: Transform(
                          transform: Matrix4.rotationZ(
                              getRadiansFromDegree(_rotationAnimation.value))
                            ..scale(_degOneTranslationAnimation.value),
                          alignment: Alignment.center,
                          child: CircularButton(
                            color: Colors.blue,
                            width: 50,
                            height: 50,
                            icon: const Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                            ),
                            onClick: pickImage,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset.fromDirection(getRadiansFromDegree(225),
                            _degTwoTranslationAnimation.value * 100),
                        child: Transform(
                          transform: Matrix4.rotationZ(
                              getRadiansFromDegree(_rotationAnimation.value))
                            ..scale(_degTwoTranslationAnimation.value),
                          alignment: Alignment.center,
                          child: CircularButton(
                            color: Colors.black,
                            width: 50,
                            height: 50,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onClick: takeImage,
                          ),
                        ),
                      ),
                      _outputs != null
                          ? Builder(
                              builder: (context) => Transform.translate(
                                    offset: Offset.fromDirection(
                                        getRadiansFromDegree(180),
                                        _degThreeTranslationAnimation.value *
                                            100),
                                    child: Transform(
                                      transform: Matrix4.rotationZ(
                                          getRadiansFromDegree(
                                              _rotationAnimation.value))
                                        ..scale(
                                            _degThreeTranslationAnimation.value),
                                      alignment: Alignment.center,
                                      child: CircularButton(
                                        color: Colors.purpleAccent,
                                        width: 50,
                                        height: 50,
                                        icon: const Icon(
                                          Icons.sort,
                                          color: Colors.white,
                                        ),
                                        onClick: () async {
                                          if (_isSorting) return;
                                          final snackBar = SnackBar(
                                              content:
                                                  Text('Wait a minute !!!'));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(snackBar);
                                          await _computeSimilarities();
                                        },
                                      ),
                                    ),
                                  ))
                          : Container(),
                      Transform(
                        transform: Matrix4.rotationZ(
                            getRadiansFromDegree(_rotationAnimation.value)),
                        alignment: Alignment.center,
                        child: CircularButton(
                          color: Colors.blue,
                          width: 60,
                          height: 60,
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                          ),
                          onClick: () {
                            if (_animationController.isCompleted) {
                              _animationController.reverse();
                            } else {
                              _animationController.forward();
                            }
                          },
                        ),
                      )
                    ],
                  ))
            ])));
  }

  Future<void> _computeSimilarities() async {
    final docs = _snapshotData?.docs;
    final queryBytes = _queryBytes;
    if (docs == null || queryBytes == null) return;

    setState(() {
      _isSorting = true;
      _sortProgress = 0.0;
    });

    final diffs = List<double>.filled(docs.length, 100);
    final queue = List<int>.generate(docs.length, (i) => i);
    final concurrency = docs.length < 3 ? docs.length : 3;
    var completed = 0;

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final i = queue.removeLast();
        final url = docs[i].data()["url"] as String?;
        if (url == null) {
          diffs[i] = 100;
        } else {
          try {
            final bytes = await _getImageBytes(url);
            if (bytes == null) {
              diffs[i] = 100;
            } else {
              final diff = await compute(_diffFromBytes, {
                "query": queryBytes,
                "target": bytes,
                "size": 300,
              });
              diffs[i] = diff;
            }
          } catch (_) {
            diffs[i] = 100;
          }
        }

        completed++;
        if (!mounted) return;
        setState(() {
          _sortProgress = completed / docs.length;
        });
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));

    final indices = List<int>.generate(diffs.length, (i) => i)
      ..sort((a, b) => diffs[a].compareTo(diffs[b]));
    final sortedDiffs = [for (final i in indices) diffs[i]];

    if (!mounted) return;
    setState(() {
      _sortedIndices = indices;
      _sortedDiffs = sortedDiffs;
      _isSorting = false;
      _sortProgress = 0.0;
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getImages() {
    return _firestore.collection(_collectionName).get();
  }

  final Widget _textSection = Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Text(
          'Results',
          softWrap: true,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
      ));

  Future<void> classifyImage(Uint8List bytes) async {
    final result = await _classifier.classify(bytes);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
      });
      if (_classifier.isSupported == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image classification is not supported on web.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _loading = false;
      _outputs = [
        {
          "label": result.label,
          "confidence": result.confidence,
        }
      ];
      _collectionName = result.label;
    });
  }

  Future<void> takeImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;

    try {
      setState(() {
        _loading = true;
      });
      final bytes = await picked.readAsBytes();
      _queryBytes = bytes;
      _imageBytes = bytes;
      if (!kIsWeb) {
        _image = File(picked.path);
      }
      await classifyImage(bytes);
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }

    _sortedDiffs = null;
    _sortedIndices = null;
  }

  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      setState(() {
        _loading = true;
      });
      final bytes = await picked.readAsBytes();
      _queryBytes = bytes;
      _imageBytes = bytes;
      if (!kIsWeb) {
        _image = File(picked.path);
      }
      await classifyImage(bytes);
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }

    _sortedDiffs = null;
    _sortedIndices = null;
  }

  Future<void> loadModel() async {
    await _classifier.load();
  }

  Future<Uint8List?> _getImageBytes(String url) async {
    final cached = _imageCache[url];
    if (cached != null) {
      _imageCache.remove(url);
      _imageCache[url] = cached;
      return cached;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final bytes = response.bodyBytes;
    _imageCache[url] = bytes;
    if (_imageCache.length > _imageCacheLimit) {
      _imageCache.remove(_imageCache.keys.first);
    }
    return bytes;
  }

  @override
  void dispose() {
    if (_classifier.isSupported) {
      _classifier.close();
    }
    _animationController.dispose();
    super.dispose();
  }
}

class CircularButton extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Icon icon;
  final VoidCallback onClick;

  const CircularButton(
      {super.key,
      required this.color,
      required this.width,
      required this.height,
      required this.icon,
      required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      width: width,
      height: height,
      child: IconButton(icon: icon, enableFeedback: true, onPressed: onClick),
    );
  }
}

