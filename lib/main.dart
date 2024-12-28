import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  runApp(WallpaperApp());
}

Future<void> _requestPermissions() async {
  final storageStatus = await Permission.storage.request();
  final manageExternalStorageStatus = await Permission.manageExternalStorage.request();
  if (storageStatus.isGranted && manageExternalStorageStatus.isGranted) {
    print('Permissions granted');
  } else if (storageStatus.isDenied || manageExternalStorageStatus.isDenied) {
    print('Permission denied');
    openAppSettings();
  } else if (storageStatus.isPermanentlyDenied || manageExternalStorageStatus.isPermanentlyDenied) {
    print('Permission permanently denied');
    openAppSettings();
  }
}

class WallpaperApp extends StatefulWidget {
  @override
  _WallpaperAppState createState() => _WallpaperAppState();
}

class _WallpaperAppState extends State<WallpaperApp> {
  bool _isDarkMode = true;
  Locale _locale = Locale('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper Design',
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.purple,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          color: Colors.purple,
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: _locale,
      supportedLocales: [
        const Locale('en', ''),
        const Locale('tr', ''),
      ],
      home: HomePage(
        isDarkMode: _isDarkMode,
        locale: _locale,
        onThemeChanged: (bool value) {
          setState(() {
            _isDarkMode = value;
          });
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final bool isDarkMode;
  final Locale locale;
  final ValueChanged<bool> onThemeChanged;

  HomePage({
    required this.isDarkMode,
    required this.locale,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wallpaper Design',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(
                        isDarkMode: isDarkMode,
                        onThemeChanged: onThemeChanged,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text('Donate'),
                onTap: () {
                  _launchURL('https://buymeacoffee.com/nothingnessn');
                },
              ),
              ListTile(
                title: Text('Telegram'),
                onTap: () {
                  _launchURL('https://t.me/wallpaperdesing');
                },
              ),
              ListTile(
                title: Text('Visit My Main Instagram'),
                subtitle: Text('Follow My on Instagram'),
                onTap: () {
                  _launchURL('https://www.instagram.com/nothingnessn3/');
                },
              ),
              ListTile(
                title: Text('Visit My Developer Instagram'),
                subtitle: Text('Follow My developer page on Instagram'),
                onTap: () {
                  _launchURL('https://www.instagram.com/akn_d3s1gn/');
                },
              ),
            ],
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 67,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageDetailPage(
                    imageIndex: index,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.purple.shade700,
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: AssetImage('assets/images/${index}.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $url';
    }
  }
}

class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  SettingsPage({
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          ListTile(
            title: Text('Theme'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (bool value) {
                onThemeChanged(value);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ImageDetailPage extends StatelessWidget {
  final int imageIndex;

  ImageDetailPage({required this.imageIndex});

  Future<void> _createDirectoryIfNotExists() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('External storage directory not found');
      }
      final dirPath = '${directory.path}/wallpaperdesign';
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print('Directory created: $dirPath');
      }
    } catch (e) {
      print('Error creating directory: $e');
    }
  }

  Future<void> _copyImageToLocal() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('External storage directory not found');
      }
      final filePath = '${directory.path}/wallpaperdesign/${imageIndex}.jpg';
      final file = File(filePath);

      if (!await file.exists()) {
        final ByteData data = await rootBundle.load('assets/images/${imageIndex}.jpg');
        final buffer = data.buffer.asUint8List();
        await file.writeAsBytes(buffer);
        print('Image copied: $filePath');
      } else {
        print('Image already exists: $filePath');
      }
    } catch (e) {
      print('Error copying image: $e');
    }
  }

  Future<void> _setWallpaper() async {
    try {
      await _createDirectoryIfNotExists();
      await _copyImageToLocal();

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('External storage directory not found');
      }
      final filePath = '${directory.path}/wallpaperdesign/${imageIndex}.jpg';

      await MethodChannel('com.nothingnessn.wallpaperdesing').invokeMethod('setWallpaper', {'filePath': filePath});
      print('Wallpaper set successfully');
    } on PlatformException catch (e) {
      print("Failed to set wallpaper: '\${e.message}'.");
    } catch (e) {
      print('Error setting wallpaper: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image $imageIndex'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                'assets/images/${imageIndex}.jpg',
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _copyImageToLocal();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Image saved to "Android/data/com.nothingnessn.wallpaper/files/wallpaperdesign" folder')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving image: $e')),
                  );
                }
              },
              child: Text('Save Image'),
            ),
            ElevatedButton(
              onPressed: _setWallpaper,
              child: Text('Set as Wallpaper'),
            ),
          ],
        ),
      ),
    );
  }
}
