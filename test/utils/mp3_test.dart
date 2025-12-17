import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:bassknight/utils/mp3.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    
    // Mock FFmpegKit MethodChannel
    const channel = MethodChannel('flutter.arthenica.com/ffmpeg_kit');
    
    List<dynamic>? pendingArgs;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        // print('MOCK CALL: ${methodCall.method} args: ${methodCall.arguments}');

        if (methodCall.method == 'ffmpegSession') {
           // Called when creating the session
           final argsMap = methodCall.arguments as Map;
           pendingArgs = argsMap['arguments'] as List;
           
           // Return a Session map
           return {
             'sessionId': 100,
             'state': 0, // CREATED
             'returnCode': null,
             'command': pendingArgs?.join(' '),
             'startTime': DateTime.now().millisecondsSinceEpoch,
           };
        }
        
        if (methodCall.method == 'ffmpegSessionExecute') {
           // Simulate execution
           if (pendingArgs != null) {
               final pcmPath = pendingArgs!.firstWhere(
                 (e) => e.toString().endsWith('.pcm'), 
                 orElse: () => null
               );
               
               if (pcmPath != null) {
                   // Generate Mock PCM
                   final file = File(pcmPath);
                   final bytes = _generateSineWave(1.0, 440.0);
                   await file.writeAsBytes(bytes);
               }
           }
           return null;
        }

        if (methodCall.method == 'abstractSessionGetReturnCode') {
           // Return success code. 
           return 0;
        }
        
        if (methodCall.method == 'abstractSessionGetLogs') {
           return [];
        }

        // Default handlers for configuration calls
        if (methodCall.method == 'getLogLevel') return 0;
        if (methodCall.method == 'getPlatform') return 'macos';
        if (methodCall.method == 'getPackageName') return 'bassknight';

        return null;
      },
    );
  });
  
  tearDown(() {
     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.arthenica.com/ffmpeg_kit'),
      null,
    );
  });

  test('MP3 analysis loads asset and generates notes from audio', () async {
    final mp3 = MP3();
    
    // Use the requested asset.
    await mp3.loadAsset('assets/music/sample-15s.mp3');
    
    // Assertions
    bool foundNotes = false;
    int noteCount = 0;

    for (int i = 0; i < mp3.bands.length; i++) {
      final head = mp3.bands[i];
      if (head != null) {
        foundNotes = true;
        Note? current = head;
        while(current != null) {
          noteCount++;
          expect(current.startMs, greaterThanOrEqualTo(0));
          expect(current.endMs, greaterThan(current.startMs));
          current = current.next;
        }
      }
    }
    
    print('Found $noteCount notes across ${mp3.bands.length} bands.');
    expect(foundNotes, isTrue, reason: "Analysis should find notes in the generated sine wave.");
  });
}

Uint8List _generateSineWave(double duration, double freq) {
  const int sampleRate = 44100;
  final int samples = (duration * sampleRate).toInt();
  final ByteData bd = ByteData(samples * 2);
  
  for(int i=0; i<samples; i++) {
    double t = i / sampleRate;
    double val = math.sin(2 * math.pi * freq * t);
    int intVal = (val * 32000).toInt();
    bd.setInt16(i*2, intVal, Endian.little);
  }
  return bd.buffer.asUint8List();
}