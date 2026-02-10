import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class ImageSearchEvent extends Equatable {
  const ImageSearchEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends ImageSearchEvent {
  const AppStarted();
}

class PickImageRequested extends ImageSearchEvent {
  final ImageSource source;

  const PickImageRequested(this.source);

  @override
  List<Object?> get props => [source];
}

class SortRequested extends ImageSearchEvent {
  const SortRequested();
}

class ClearError extends ImageSearchEvent {
  const ClearError();
}
