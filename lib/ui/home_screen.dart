import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/image_search/image_search_bloc.dart';
import '../bloc/image_search/image_search_event.dart';
import '../bloc/image_search/image_search_state.dart';
import 'widgets/circular_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _degOneTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 75.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 25.0,
      ),
    ]).animate(_animationController);
    _degTwoTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.4),
        weight: 55.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.4, end: 1.0),
        weight: 45.0,
      ),
    ]).animate(_animationController);
    _degThreeTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.75),
        weight: 35.0,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.75, end: 1.0),
        weight: 65.0,
      ),
    ]).animate(_animationController);
    _rotationAnimation = Tween<double>(begin: 180.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImageSearchBloc, ImageSearchState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        context.read<ImageSearchBloc>().add(const ClearError());
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF4F7F1),
                      Color(0xFFF8EFE7),
                      Color(0xFFF4F7F1),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  _HeaderBar(),
                  Expanded(
                    child: state.isModelLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _PreviewCard(state: state),
                                const SizedBox(height: 18),
                                if (state.classification != null)
                                  _ResultChip(state: state),
                                const SizedBox(height: 16),
                                if (state.classification != null)
                                  Text(
                                    'Results',
                                    style: GoogleFonts.comfortaa(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF8F7BB3),
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                if (state.isSorting)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: state.sortProgress,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                if (state.isImageLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                _ResultsGrid(state: state),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: <Widget>[
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
                        offset: Offset.fromDirection(
                          getRadiansFromDegree(270),
                          _degOneTranslationAnimation.value * 100,
                        ),
                        child: Transform(
                          transform: Matrix4.rotationZ(
                            getRadiansFromDegree(_rotationAnimation.value),
                          )..scale(_degOneTranslationAnimation.value),
                          alignment: Alignment.center,
                          child: CircularButton(
                            color: const Color(0xFFE9A7B5),
                            width: 50,
                            height: 50,
                            icon: const Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                            ),
                            onClick: () {
                              context.read<ImageSearchBloc>().add(
                                const PickImageRequested(ImageSource.gallery),
                              );
                            },
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset.fromDirection(
                          getRadiansFromDegree(225),
                          _degTwoTranslationAnimation.value * 100,
                        ),
                        child: Transform(
                          transform: Matrix4.rotationZ(
                            getRadiansFromDegree(_rotationAnimation.value),
                          )..scale(_degTwoTranslationAnimation.value),
                          alignment: Alignment.center,
                          child: CircularButton(
                            color: const Color(0xFFD990A4),
                            width: 50,
                            height: 50,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onClick: () {
                              context.read<ImageSearchBloc>().add(
                                const PickImageRequested(ImageSource.camera),
                              );
                            },
                          ),
                        ),
                      ),
                      state.classification != null
                          ? Transform.translate(
                              offset: Offset.fromDirection(
                                getRadiansFromDegree(180),
                                _degThreeTranslationAnimation.value * 100,
                              ),
                              child: Transform(
                                transform: Matrix4.rotationZ(
                                  getRadiansFromDegree(
                                    _rotationAnimation.value,
                                  ),
                                )..scale(_degThreeTranslationAnimation.value),
                                alignment: Alignment.center,
                                child: CircularButton(
                                  color: const Color(0xFFC97C93),
                                  width: 50,
                                  height: 50,
                                  icon: const Icon(
                                    Icons.sort,
                                    color: Colors.white,
                                  ),
                                  onClick: () {
                                    context.read<ImageSearchBloc>().add(
                                      const SortRequested(),
                                    );
                                  },
                                ),
                              ),
                            )
                          : Container(),
                      Transform(
                        transform: Matrix4.rotationZ(
                          getRadiansFromDegree(_rotationAnimation.value),
                        ),
                        alignment: Alignment.center,
                        child: CircularButton(
                          color: const Color(0xFFE9A7B5),
                          width: 60,
                          height: 60,
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onClick: () {
                            if (_animationController.isCompleted) {
                              _animationController.reverse();
                            } else {
                              _animationController.forward();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9A7B5), Color(0xFFF3C1CB)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_florist, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            'CBIR Flower',
            style: GoogleFonts.pacifico(fontSize: 26, color: Colors.white),
          ),
          const Spacer(),
          const CircleAvatar(
            backgroundColor: Color(0xFFF6F1E6),
            child: Icon(Icons.person, color: Color(0xFF6D6D6D)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final ImageSearchState state;

  const _PreviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8D7DA),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: (state.imageFile == null && state.imageBytes == null)
            ? Container(
                color: const Color(0xFFF1F1F1),
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Color(0xFFBDBDBD)),
                ),
              )
            : kIsWeb
            ? Image.memory(state.imageBytes!, fit: BoxFit.cover)
            : Image.file(state.imageFile ?? File(''), fit: BoxFit.cover),
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final ImageSearchState state;

  const _ResultChip({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.classification == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0B7BF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        'Flower type: ${state.classification!.label} (${(state.classification!.confidence * 100).toStringAsFixed(0)}%)',
        style: GoogleFonts.comfortaa(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ResultsGrid extends StatelessWidget {
  final ImageSearchState state;

  const _ResultsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.images.isEmpty) {
      return Text(
        'Upload a flower image to see results.',
        style: GoogleFonts.comfortaa(color: const Color(0xFF9E9E9E)),
      );
    }

    final crossAxisCount = MediaQuery.of(context).size.width > 900
        ? 4
        : MediaQuery.of(context).size.width > 600
        ? 3
        : 2;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: state.images.length,
      itemBuilder: (context, index) {
        final docIndex = state.sortedIndices != null
            ? state.sortedIndices![index]
            : index;
        final image = state.images[docIndex];
        final similarity =
            (state.similarities != null && index < state.similarities!.length)
            ? (100 - state.similarities![index])
            : null;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    image.url,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF9DD6C1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  similarity == null
                      ? image.name
                      : '${similarity.toStringAsFixed(0)}% Match',
                  style: GoogleFonts.comfortaa(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D5248),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
