import 'package:firebase_cached_image/firebase_cached_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Cached Image',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Cached Image Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image(
          image: FirebaseImageProvider(
            FirebaseUrl("gs://bucket_f233/logo.jpg"),
            options: const CacheOptions(
              source: Source.server,
            ),
          ),
          frameBuilder: (_, child, frame, __) {
            if (frame == null) return child;

            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
