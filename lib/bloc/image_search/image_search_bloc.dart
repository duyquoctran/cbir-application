import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../data/classifier_repository.dart';
import '../../data/image_picker_service.dart';
import '../../data/image_repository.dart';
import '../../data/similarity_service.dart';
import '../../domain/models/app_image.dart';
import 'image_search_event.dart';
import 'image_search_state.dart';

class ImageSearchBloc extends Bloc<ImageSearchEvent, ImageSearchState> {
  final ImageRepository _imageRepository;
  final ImagePickerService _imagePickerService;
  final ClassifierRepository _classifierRepository;
  final SimilarityService _similarityService;

  ImageSearchBloc({
    required ImageRepository imageRepository,
    required ImagePickerService imagePickerService,
    required ClassifierRepository classifierRepository,
    required SimilarityService similarityService,
  })  : _imageRepository = imageRepository,
        _imagePickerService = imagePickerService,
        _classifierRepository = classifierRepository,
        _similarityService = similarityService,
        super(ImageSearchState.initial()) {
    on<AppStarted>(_onAppStarted);
    on<PickImageRequested>(_onPickImageRequested);
    on<SortRequested>(_onSortRequested);
    on<ClearError>(_onClearError);
  }

  Future<void> _onAppStarted(
      AppStarted event, Emitter<ImageSearchState> emit) async {
    try {
      await _classifierRepository.load();
      emit(state.copyWith(
        isModelLoading: false,
        isClassifierSupported: _classifierRepository.isSupported,
      ));
    } catch (_) {
      emit(state.copyWith(
        isModelLoading: false,
        errorMessage: 'Failed to load model.',
        isClassifierSupported: _classifierRepository.isSupported,
      ));
    }
  }

  Future<void> _onPickImageRequested(
      PickImageRequested event, Emitter<ImageSearchState> emit) async {
    emit(state.copyWith(
      isImageLoading: true,
      errorMessage: null,
      similarities: null,
      sortedIndices: null,
      images: const [],
      classification: null,
    ));
    try {
      _similarityService.clearCache();
      final picked = await _imagePickerService.pick(event.source);
      if (picked == null) {
        emit(state.copyWith(isImageLoading: false));
        return;
      }

      final classification =
          await _classifierRepository.classify(picked.bytes);

      if (classification == null) {
        emit(state.copyWith(
          isImageLoading: false,
          imageBytes: picked.bytes,
          imageFile: picked.file,
          queryBytes: picked.bytes,
          similarities: null,
          sortedIndices: null,
          errorMessage: _classifierRepository.isSupported
              ? 'Failed to classify image.'
              : 'Image classification is not supported on web.',
        ));
        return;
      }

      final rawLabel = classification.label.trim();
      var collectionName = rawLabel.isEmpty ? classification.label : rawLabel;
      var images = await _imageRepository.fetchImages(collectionName);
      if (images.isEmpty) {
        final normalized = collectionName.toLowerCase();
        if (normalized != collectionName) {
          images = await _imageRepository.fetchImages(normalized);
          if (images.isNotEmpty) {
            collectionName = normalized;
          }
        }
      }

      emit(state.copyWith(
        isImageLoading: false,
        imageBytes: picked.bytes,
        imageFile: picked.file,
        queryBytes: picked.bytes,
        classification: classification,
        collectionName: collectionName,
        images: images,
        similarities: null,
        sortedIndices: null,
        errorMessage: images.isEmpty
            ? 'No images found for collection: ${classification.label}'
            : null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isImageLoading: false,
        similarities: null,
        sortedIndices: null,
        errorMessage: _formatErrorMessage(e),
      ));
    }
  }

  Future<void> _onSortRequested(
      SortRequested event, Emitter<ImageSearchState> emit) async {
    if (state.isSorting || state.queryBytes == null || state.images.isEmpty) {
      return;
    }

    emit(state.copyWith(isSorting: true, sortProgress: 0.0));

    try {
      final diffs = await _similarityService.computeSimilarities(
        queryBytes: state.queryBytes!,
        images: state.images,
        onProgress: (completed, total) {
          emit(state.copyWith(sortProgress: completed / total));
        },
      );

      final indices = List<int>.generate(diffs.length, (i) => i)
        ..sort((a, b) => diffs[a].compareTo(diffs[b]));
      final sortedDiffs = [for (final i in indices) diffs[i]];

      emit(state.copyWith(
        isSorting: false,
        sortProgress: 0.0,
        similarities: sortedDiffs,
        sortedIndices: indices,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSorting: false,
        errorMessage: _formatErrorMessage(e, fallback: 'Failed to sort images.'),
      ));
    }
  }

  void _onClearError(ClearError event, Emitter<ImageSearchState> emit) {
    emit(state.copyWith(errorMessage: null));
  }

  @override
  Future<void> close() {
    _classifierRepository.close();
    return super.close();
  }

  String _formatErrorMessage(Object error,
      {String fallback = 'Failed to process image.'}) {
    if (error is FirebaseException) {
      final message = error.message;
      return message == null || message.isEmpty
          ? 'Firebase error: ${error.code}'
          : 'Firebase error: ${error.code} - $message';
    }
    return '$fallback (${error.runtimeType})';
  }
}
