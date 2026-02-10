import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/image_search/image_search_bloc.dart';
import '../bloc/image_search/image_search_event.dart';
import '../data/classifier_repository.dart';
import '../data/image_picker_service.dart';
import '../data/image_repository.dart';
import '../data/similarity_service.dart';
import '../ui/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ImageRepository>(
          create: (_) => ImageRepository(),
        ),
        RepositoryProvider<ImagePickerService>(
          create: (_) => ImagePickerService(),
        ),
        RepositoryProvider<ClassifierRepository>(
          create: (_) => ClassifierRepository(),
        ),
        RepositoryProvider<SimilarityService>(
          create: (_) => SimilarityService(),
        ),
      ],
      child: BlocProvider<ImageSearchBloc>(
        create: (context) => ImageSearchBloc(
          imageRepository: context.read<ImageRepository>(),
          imagePickerService: context.read<ImagePickerService>(),
          classifierRepository: context.read<ClassifierRepository>(),
          similarityService: context.read<SimilarityService>(),
        )..add(AppStarted()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF70C6A7),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.comfortaaTextTheme(),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
