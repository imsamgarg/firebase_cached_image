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
      appBar: AppBar(
        title: const Text('Firebase Image Example'),
      ),
      body: Center(
        child: Image(
          image: FirebaseImageProvider(
            FirebaseUrl("gs://your_bucket/your_image.jpg"),
            // Specify CacheOptions to control file fetching and caching behavior.
            options: const CacheOptions(
              // Always fetch the latest file from the server and do not cache the file.
              // default is Source.cacheServer which will fetch try to fetch the image from the cache and then hit server if the image not found in the cache.
              source: Source.server,
              // Check if the image is updated on the server or not, if updated then download the latest image otherwise use the cached image.
              // Will only be used if the options.source is Source.cacheServer
              checkIfFileUpdatedOnServer: true,
            ),
            // Use this to save files in desired directory in system's temporary directory
            // Optional. default is "flutter_cached_image"
            subDir: "custom_cache_directory",
          ),
          errorBuilder: (context, error, stackTrace) {
            // [ImageNotFoundException] will be thrown if image does not exist on server.
            if (error is ImageNotFoundException) {
              return const Text('Image not found on Cloud Storage.');
            } else {
              return Text('Error loading image: $error');
            }
          },
          // The loading progress may not be accurate as Firebase Storage API
          // does not provide a stream of bytes downloaded. The progress updates only at the start and end of the loading process.
          loadingBuilder: (_, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              // Show the loaded image if loading is complete.
              return child;
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
