import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NFCService {
  bool _isScanning = false;
  
  bool get isScanning => _isScanning;

  Future<bool> isNFCAvailable() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability != NFCAvailability.not_supported;
    } catch (e) {
      return false;
    }
  }

  Future<String?> scanTag() async {
    if (_isScanning) {
      throw Exception('Already scanning for NFC tag');
    }

    _isScanning = true;
    
    try {
      // Start polling for NFC tags
      final tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 30),
        iosMultipleTagMessage: 'Multiple tags found!',
        iosAlertMessage: 'Scan your NFC tag',
      );

      // Get the tag ID
      final tagId = tag.id;
      
      // End the session
      await FlutterNfcKit.finish();
      
      return tagId;
    } catch (e) {
      await FlutterNfcKit.finish();
      rethrow;
    } finally {
      _isScanning = false;
    }
  }

  void stopScanning() {
    _isScanning = false;
    FlutterNfcKit.finish();
  }
}
