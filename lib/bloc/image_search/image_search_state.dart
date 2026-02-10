import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/models/classification_result.dart';
import '../../domain/models/app_image.dart';

class ImageSearchState extends Equatable {
  final bool isModelLoading;
  final bool isImageLoading;
  final bool isSorting;
  final double sortProgress;
  final String collectionName;
  final Uint8List? imageBytes;
  final File? imageFile;
  final Uint8List? queryBytes;
  final ClassificationResult? classification;
  final List<AppImage> images;
  final List<double>? similarities;
  final List<int>? sortedIndices;
  final String? errorMessage;
  final bool isClassifierSupported;

  const ImageSearchState({
    required this.isModelLoading,
    required this.isImageLoading,
    required this.isSorting,
    required this.sortProgress,
    required this.collectionName,
    required this.imageBytes,
    required this.imageFile,
    required this.queryBytes,
    required this.classification,
    required this.images,
    required this.similarities,
    required this.sortedIndices,
    required this.errorMessage,
    required this.isClassifierSupported,
  });

  factory ImageSearchState.initial() {
    return const ImageSearchState(
      isModelLoading: true,
      isImageLoading: false,
      isSorting: false,
      sortProgress: 0.0,
      collectionName: 'images',
      imageBytes: null,
      imageFile: null,
      queryBytes: null,
      classification: null,
      images: [],
      similarities: null,
      sortedIndices: null,
      errorMessage: null,
      isClassifierSupported: true,
    );
  }

  ImageSearchState copyWith({
    bool? isModelLoading,
    bool? isImageLoading,
    bool? isSorting,
    double? sortProgress,
    String? collectionName,
    Uint8List? imageBytes,
    File? imageFile,
    Uint8List? queryBytes,
    ClassificationResult? classification,
    List<AppImage>? images,
    List<double>? similarities,
    List<int>? sortedIndices,
    String? errorMessage,
    bool? isClassifierSupported,
  }) {
    return ImageSearchState(
      isModelLoading: isModelLoading ?? this.isModelLoading,
      isImageLoading: isImageLoading ?? this.isImageLoading,
      isSorting: isSorting ?? this.isSorting,
      sortProgress: sortProgress ?? this.sortProgress,
      collectionName: collectionName ?? this.collectionName,
      imageBytes: imageBytes ?? this.imageBytes,
      imageFile: imageFile ?? this.imageFile,
      queryBytes: queryBytes ?? this.queryBytes,
      classification: classification ?? this.classification,
      images: images ?? this.images,
      similarities: similarities,
      sortedIndices: sortedIndices,
      errorMessage: errorMessage,
      isClassifierSupported:
          isClassifierSupported ?? this.isClassifierSupported,
    );
  }

  @override
  List<Object?> get props => [
        isModelLoading,
        isImageLoading,
        isSorting,
        sortProgress,
        collectionName,
        imageBytes,
        imageFile,
        queryBytes,
        classification,
        images,
        similarities,
        sortedIndices,
        errorMessage,
        isClassifierSupported,
      ];
}
