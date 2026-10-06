import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentParseResult {
  final String fileName;
  final String rawText;
  final int fileSizeBytes;
  final String extension;
  final Uint8List? rawBytes;

  DocumentParseResult({
    required this.fileName,
    required this.rawText,
    required this.fileSizeBytes,
    required this.extension,
    this.rawBytes,
  });
}

class DocumentParserService {
  /// Prompts the user to pick a document (PDF, DOCX, TXT, MD, JSON, etc.) and extracts its text.
  Future<DocumentParseResult?> pickAndExtractDocument() async {
    final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'json', 'text', 'doc', 'docx'],
      );
    } catch (e) {
      throw Exception('File picker could not be opened: $e');
    }

    if (files.isEmpty) {
      // User cancelled document selection
      return null;
    }

    final PlatformFile file = files.first;
    Uint8List? bytes;

    // 1. Try reading bytes from PlatformFile directly
    try {
      bytes = await file.readAsBytes();
    } catch (_) {}

    // 2. Fallback to reading from local file path on desktop/mobile
    if ((bytes == null || bytes.isEmpty) && !kIsWeb && file.path != null && file.path!.isNotEmpty) {
      try {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          bytes = await ioFile.readAsBytes();
        }
      } catch (_) {}
    }

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Could not read file data. Please ensure the file is accessible and not empty.');
    }

    final String ext = (file.extension ?? '').toLowerCase();
    final String extractedText = extractTextFromBytes(bytes, ext);
    
    int size = bytes.length;
    try {
      size = await file.length();
    } catch (_) {}

    return DocumentParseResult(
      fileName: file.name,
      rawText: extractedText,
      fileSizeBytes: size,
      extension: ext,
      rawBytes: bytes,
    );
  }

  /// Extracts text from in-memory byte buffer based on file extension.
  String extractTextFromBytes(Uint8List bytes, String extension) {
    final cleanExt = extension.replaceAll('.', '').toLowerCase();

    if (cleanExt == 'pdf') {
      return _extractPdfText(bytes);
    } else if (cleanExt == 'docx') {
      return _extractDocxText(bytes);
    } else {
      try {
        return utf8.decode(bytes);
      } catch (_) {
        return latin1.decode(bytes);
      }
    }
  }

  /// 100% offline PDF text extraction using Syncfusion PDF engine
  /// Accurately handles multi-page PDFs as well as "2 pages on 1 sheet" (2-up side-by-side landscape spreads)
  String _extractPdfText(Uint8List bytes) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final buffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final isLandscape = page.size.width > page.size.height;

        try {
          final lines = extractor.extractTextLines(startPageIndex: i, endPageIndex: i);

          if (lines.isNotEmpty) {
            if (isLandscape) {
              // "2 pages on 1 sheet" (2-up layout / side-by-side spread):
              // Left half is Page 1, Right half is Page 2.
              // Extract all left-column lines first (top to bottom), then all right-column lines.
              final midX = page.size.width / 2;
              final leftLines = lines.where((l) => l.bounds.left < midX).toList()
                ..sort((a, b) => a.bounds.top.compareTo(b.bounds.top));
              final rightLines = lines.where((l) => l.bounds.left >= midX).toList()
                ..sort((a, b) => a.bounds.top.compareTo(b.bounds.top));

              for (final line in leftLines) {
                final t = line.text.trim();
                if (t.isNotEmpty) buffer.writeln(t);
              }
              buffer.writeln(); // Clear page break between the two pages on this sheet
              for (final line in rightLines) {
                final t = line.text.trim();
                if (t.isNotEmpty) buffer.writeln(t);
              }
            } else {
              // Standard portrait page: extract all lines in vertical order
              for (final line in lines) {
                final t = line.text.trim();
                if (t.isNotEmpty) buffer.writeln(t);
              }
            }
          } else {
            // Fallback for this page
            final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
            if (pageText.trim().isNotEmpty) {
              buffer.writeln(pageText.trim());
            }
          }
        } catch (_) {
          // Fallback to basic text extraction for this page
          final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
          if (pageText.trim().isNotEmpty) {
            buffer.writeln(pageText.trim());
          }
        }
        buffer.writeln(); // Separation between document pages
      }

      final result = buffer.toString().trim();
      if (result.isNotEmpty) {
        return _healSingleCharNewlines(result);
      }

      // Final fallback to global extractText
      final String extractedText = extractor.extractText();
      return _healSingleCharNewlines(extractedText.trim());
    } catch (e) {
      final buffer = StringBuffer();
      for (final b in bytes) {
        if ((b >= 32 && b <= 126) || b == 10 || b == 13) {
          buffer.writeCharCode(b);
        }
      }
      return _healSingleCharNewlines(buffer.toString().trim());
    } finally {
      document?.dispose();
    }
  }

  /// Extracts text from Microsoft Word (.docx) XML contents
  String _extractDocxText(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final file = archive.findFile('word/document.xml');
      if (file != null) {
        final content = utf8.decode(file.content as List<int>);
        // Replace paragraph tags with newlines and strip remaining XML tags
        final withNewlines = content.replaceAll(RegExp(r'</w:p>'), '\n');
        final cleanText = withNewlines.replaceAll(RegExp(r'<[^>]*>'), '');
        return cleanText.trim();
      }
    } catch (_) {}
    return '';
  }

  /// Automatically heals texts where single characters are split onto separate newlines
  String _healSingleCharNewlines(String input) {
    if (input.isEmpty) return input;
    final lines = input.split(RegExp(r'\r?\n'));
    if (lines.length < 5) return input;

    // Detect if > 60% of lines are 1-2 characters
    int shortCount = 0;
    for (final l in lines) {
      if (l.trim().length <= 2) shortCount++;
    }

    if (shortCount / lines.length > 0.6) {
      final buffer = StringBuffer();
      for (final l in lines) {
        final t = l.trim();
        if (t.isEmpty) {
          buffer.writeln();
        } else if (t.length == 1) {
          buffer.write(t);
        } else {
          buffer.write(' $t');
        }
      }
      return buffer.toString();
    }

    return input;
  }
}

