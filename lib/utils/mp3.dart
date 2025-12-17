import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:fftea/fftea.dart';
import 'package:uuid/uuid.dart';

/// Represents a musical note or sound event within a specific frequency band.
class Note {
  final int startMs;
  int endMs;
  Note? next;

  Note({
    required this.startMs,
    required this.endMs,
    this.next,
  });
}

class MP3 {
  static const int headerSize = 10; // ID3v2 Header (10 bytes)
  late Uint8List bytes;

  /// Linked lists for notes in frequency bands.
  /// 32 bands covering the frequency spectrum.
  final List<Note?> bands = List.filled(32, null, growable: true);

  MP3() {
    // Default empty MP3 (just ID3v2 header, no audio frames)
    bytes = Uint8List(headerSize);
    _writeHeader(bytes.buffer.asByteData());
  }

  /// Writes a minimal ID3v2.3 header.
  static void _writeHeader(ByteData bd) {
    bd.setUint8(0, 0x49); // 'I'
    bd.setUint8(1, 0x44); // 'D'
    bd.setUint8(2, 0x33); // '3'
    bd.setUint8(3, 0x03); // Version 3 (ID3v2.3)
    bd.setUint8(4, 0x00); // Revision 0
    bd.setUint8(5, 0x00); // Flags
    bd.setUint8(6, 0);    // Size (synchsafe)
    bd.setUint8(7, 0);
    bd.setUint8(8, 0);
    bd.setUint8(9, 0);
  }

  /// Loads an MP3 from [filePath] in a background isolate.
  Future<void> loadFile(String filePath) async {
    final File file = File(filePath);
    final Uint8List fileBytes = await file.readAsBytes();
    await _processWithFfmpeg(fileBytes);
  }

  /// Loads an MP3 from Flutter assets from [assetPath].
  Future<void> loadAsset(String assetPath) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    final Uint8List bytes = byteData.buffer.asUint8List();
    await _processWithFfmpeg(bytes);
  }

  Future<void> _processWithFfmpeg(Uint8List sourceBytes) async {
    bytes = sourceBytes;

    final tempDir = await getTemporaryDirectory();
    final uuid = const Uuid().v4();
    final inputPath = '${tempDir.path}/$uuid.mp3';
    final outputPath = '${tempDir.path}/$uuid.pcm';

    final inputFile = File(inputPath);
    final outputFile = File(outputPath);

    try {
      await inputFile.writeAsBytes(sourceBytes);

      // Decode MP3 to raw PCM (16-bit LE, Mono, 44.1kHz)
      // -y: overwrite output
      // -f s16le: signed 16-bit little endian raw PCM
      // -ac 1: mono
      // -ar 44100: sample rate
      final command = '-y -i "$inputPath" -f s16le -ac 1 -ar 44100 "$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        if (await outputFile.exists()) {
          final pcmBytes = await outputFile.readAsBytes();
          
          // Perform FFT analysis in a separate isolate
          final analyzedBands = await compute(_analyzePcmData, pcmBytes);
          
          bands.clear();
          bands.addAll(analyzedBands);
        } else {
          debugPrint('MP3 Error: Output PCM file not found.');
        }
      } else {
        final logs = await session.getLogsAsString();
        debugPrint('MP3 FFmpeg Error: $logs');
      }
    } catch (e) {
      debugPrint('MP3 Processing Error: $e');
    } finally {
      // Cleanup temp files
      if (await inputFile.exists()) await inputFile.delete();
      if (await outputFile.exists()) await outputFile.delete();
    }
  }
}

/// Top-level function to run in the isolate.
/// Analyzes raw PCM data using FFT to populate frequency bands.
List<Note?> _analyzePcmData(Uint8List pcmBytes) {
  const int sampleRate = 44100;
  const int chunkSize = 2048; // FFT Size
  const int hopSize = 1024;   // 50% overlap
  
  // Create bands list
  final List<Note?> bands = List.filled(32, null);
  final List<Note?> tails = List.filled(32, null); // Keep track of tails for O(1) append

  // Convert bytes to Float64List samples (-1.0 to 1.0)
  // 16-bit LE = 2 bytes per sample
  final int numSamples = pcmBytes.length ~/ 2;
  final Float64List samples = Float64List(numSamples);
  final ByteData byteData = pcmBytes.buffer.asByteData();

  for (int i = 0; i < numSamples; i++) {
    // Read Int16
    final int sampleInt = byteData.getInt16(i * 2, Endian.little);
    // Normalize to -1.0 .. 1.0
    samples[i] = sampleInt / 32768.0;
  }


  // Processing loop
  // We'll process in chunks
  int currentSampleIndex = 0;
  
  // Frequency resolution = SampleRate / ChunkSize = 44100 / 2048 ≈ 21.5 Hz per bin
  // Max Frequency = 22050 Hz (Nyquist)
  
  // Define 32 logarithmic bands (simplified Mel-like mapping)
  // We'll map FFT bins to these bands.
  
  while (currentSampleIndex + chunkSize < numSamples) {
    // Extract chunk
    // STFT run implementation in fftea usually handles stream or chunk list.
    // Here we'll manually run FFT on the windowed chunk for simplicity with the indices.
    
    final chunk = samples.sublist(currentSampleIndex, currentSampleIndex + chunkSize);
    
    // Apply window (manually if STFT class not used for streaming, 
    // but fftea's STFT.run takes a stream. Let's use direct FFT for control).
    // Actually, let's use the stft helper directly if possible, but manual is safer for timestamping.
    
    final windowedChunk = Float64List(chunkSize);
    final window = Window.hanning(chunkSize);
    for(int i=0; i<chunkSize; i++) {
        windowedChunk[i] = chunk[i] * window[i];
    }
    
    final fft = FFT(chunkSize);
    final freqData = fft.realFft(windowedChunk); // Returns complex magnitudes? No, realFft returns Complex array?
    // fftea 1.5.0: realFft returns Float64x2List (complex numbers)
    
    final magnitudes = freqData.discardConjugates().magnitudes(); 
    // discardConjugates gives us the first N/2 + 1 bins (positive frequencies)
    
    final double currentTimeMs = (currentSampleIndex / sampleRate) * 1000;
    final double durationMs = (hopSize / sampleRate) * 1000;
    
    // Analyze bands
    _processFrame(magnitudes, bands, tails, currentTimeMs, durationMs);
    
    currentSampleIndex += hopSize;
  }

  return bands;
}

void _processFrame(Float64List magnitudes, List<Note?> bands, List<Note?> tails, double startMs, double durationMs) {
  // Map 1025 bins (0 to Nyquist) to 32 bands
  // Simple linear mapping for now, or log? Log is better for music.
  // Bin 0 is DC. Bin 1 is ~21.5Hz.
  
  const int numBands = 32;
  // We'll skip DC (bin 0)
  
  // Logarithmic grouping could be:
  // Band i covers frequency range [f_min * 2^(i/N), ...]
  
  // Simplified: Linear grouping of bins for this prototype to ensure coverage
  // 1024 bins. 32 bands. ~32 bins per band.
  // 32 bins * 21.5 Hz = ~688 Hz width per band (Linear).
  // This packs lows into Band 0. Not ideal for "BassKnight" but functional.
  
  // Better: Custom Mapping for "Notes"
  // We'll use a pre-calculated mapping or just loop.
  
  // Threshold for "Note On"
  const double threshold = 5.0; // Magnitude threshold (experimentally determined)

  for (int i = 0; i < numBands; i++) {
    // Aggregate energy in this band
    // Using a simple log scale approximation
    // Low bands get fewer bins, high bands get more.
    
    // Start bin for band i
    int startBin = math.pow(2, i * (math.log(magnitudes.length) / math.log(2)) / numBands).floor();
    if (startBin < 1) startBin = 1;
    
    // End bin
    int endBin = math.pow(2, (i + 1) * (math.log(magnitudes.length) / math.log(2)) / numBands).floor();
    if (endBin > magnitudes.length) endBin = magnitudes.length;
    if (endBin <= startBin) endBin = startBin + 1;

    double energy = 0;
    for (int b = startBin; b < endBin; b++) {
      if (b < magnitudes.length) {
        energy += magnitudes[b];
      }
    }
    energy /= (endBin - startBin); // Average energy

    // Note Logic
    if (energy > threshold) {
      // Note is Active
      _extendOrAddNote(bands, tails, i, startMs, durationMs);
    }
  }
}

void _extendOrAddNote(List<Note?> bands, List<Note?> tails, int bandIndex, double startMs, double durationMs) {
  final int start = startMs.toInt();
  final int end = (startMs + durationMs).toInt();
  
  final tail = tails[bandIndex];
  
  if (tail != null) {
    // Check if contiguous (allow small gap for hop overlap usually, but here strict)
    if (tail.endMs >= start - 10) { // 10ms tolerance
      tail.endMs = end;
      return;
    }
  }
  
  final newNote = Note(startMs: start, endMs: end);
  if (bands[bandIndex] == null) {
    bands[bandIndex] = newNote;
    tails[bandIndex] = newNote;
  } else {
    tails[bandIndex]!.next = newNote;
    tails[bandIndex] = newNote;
  }
}