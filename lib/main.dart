import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/services.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'utils/utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Create shared service instances
  final s3Service = S3Service();
  final profileStorage = ProfileStorageService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConnectionProvider(
            s3Service: s3Service,
            profileStorage: profileStorage,
          )..loadProfiles(),
        ),
        ChangeNotifierProvider(
          create: (_) => FileBrowserProvider(s3Service: s3Service),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferProvider(s3Service: s3Service),
        ),
      ],
      child: const TotakuAssetManagerApp(),
    ),
  );
}

class TotakuAssetManagerApp extends StatelessWidget {
  const TotakuAssetManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MinIO Desktop Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ConnectionScreen(),
    );
  }
}
