import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import './pitch.dart';

class MusicalNotation extends StatefulWidget {
  @override
  _MusicalNotationState createState() => _MusicalNotationState();
}

class _MusicalNotationState extends State<MusicalNotation> {
  ui.Image? trebleClef, bassClef, sharp, flat, wholeNote;

  @override
  void initState() {
    super.initState();

    loadImage('assets/treble-clef.png').then((img) => setState(() {
          trebleClef = img;
        }));
    loadImage('assets/bass-clef.png').then((img) => setState(() {
          bassClef = img;
        }));
    loadImage('assets/sharp.png').then((img) => setState(() {
          sharp = img;
        }));
    loadImage('assets/flat.png').then((img) => setState(() {
          flat = img;
        }));
    loadImage('assets/whole-note.png').then((img) => setState(() {
          wholeNote = img;
        }));
  }

  Future<ui.Image> loadImage(String path) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    return await decodeImageFromList(bytes);
  }

  Widget build(BuildContext context) {
    if (trebleClef == null ||
        bassClef == null ||
        sharp == null ||
        flat == null ||
        wholeNote == null) {
      return CircularProgressIndicator();
    }
    return CustomPaint(
      painter: StaffPainter(
          trebleClef: trebleClef!,
          bassClef: bassClef!,
          sharp: sharp!,
          flat: flat!,
          wholeNote: wholeNote!),
      child: Container(),
    );
  }
}

// enum Clef { TREBLE, BASS }

abstract class Clef {
  abstract final int referenceOctave;
  abstract final Map<String, int> pitchLocations;
  abstract final Iterable<int> sharpPositions;
  abstract final Iterable<int> flatPositions;

  static final TREBLE = TrebleClef();
  static final BASS = BassClef();
}

class TrebleClef implements Clef {
  final referenceOctave = 4;
  final pitchLocations = {
    'C': -2,
    'D': -1,
    'E': 0,
    'F': 1,
    'G': 2,
    'A': 3,
    'B': 4
  };
  final sharpPositions = [8, 5, 9, 6, 3, 7];
  final flatPositions = [4, 7, 3, 6, 2, 5];
}

class BassClef implements Clef {
  final referenceOctave = 3;
  final pitchLocations = {
    'C': 3,
    'D': 4,
    'E': 5,
    'F': 6,
    'G': 7,
    'A': 8,
    'B': 9
  };
  final sharpPositions = [6, 3, 7, 4, 1, 5];
  final flatPositions = [2, 5, 1, 4, 0, 3];
}

class Staff {
  static const lineGap = 12;
  static const thickness = 1.5;

  double startY;
  Clef clef;
  int keySignature;

  Staff(this.startY, this.clef, [this.keySignature = 0]);

  Iterable<double> linesY() {
    return [0, 1, 2, 3, 4].map((i) => startY - i * lineGap);
  }

  int notePosition(Pitch pitch) {
    final noteName = pitch.name(keySignature < 0).substring(0, 1);
    final notePosition = clef.pitchLocations[noteName] ?? 0;
    final octaveDifference = pitch.octave() - clef.referenceOctave;
    return notePosition + 7 * octaveDifference;
  }

  double noteY(Pitch pitch) {
    return startY - Staff.lineGap * (notePosition(pitch) / 2);
  }

  Iterable<double> ledgerLinesY(Pitch pitch) {
    final position = notePosition(pitch);
    final List<double> ys = [];
    if (position <= -2) {
      for (var i = -2; i >= position; i -= 2) {
        ys.add(startY + (i / -2) * lineGap);
      }
    } else if (position >= 10) {
      for (var i = 10; i <= position; i += 2) {
        ys.add(startY - (i / 2) * lineGap);
      }
    }

    return ys;
  }
}

class StaffPainter extends CustomPainter {
  final linePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 0.9
    ..style = PaintingStyle.stroke;

  final notePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final symbolPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 4
    ..style = PaintingStyle.fill
    ..strokeCap = StrokeCap.round;

  ui.Image trebleClef, bassClef, sharp, flat, wholeNote;

  StaffPainter(
      {required this.trebleClef,
      required this.bassClef,
      required this.sharp,
      required this.flat,
      required this.wholeNote});

  @override
  void paint(Canvas canvas, Size size) {
    final keySignature = 2;
    final trebleStaff = Staff(150, Clef.TREBLE, keySignature);
    final bassStaff = Staff(250, Clef.BASS, keySignature);

    drawStaff(canvas, trebleStaff, size);
    drawStaff(canvas, bassStaff, size);

    final double x = 200;
    drawNote(canvas, trebleStaff, x, Pitch.from('A4'));
    drawNote(canvas, trebleStaff, x, Pitch.from('F#4'));
    drawNote(canvas, bassStaff, x, Pitch.from('A3'));
    drawNote(canvas, bassStaff, x, Pitch.from('D3'));
  }

  void drawStaff(Canvas canvas, Staff staff, Size size) {
    staff.linesY().forEach((y) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    });

    if (staff.clef == Clef.TREBLE) {
      drawTrebleClef(canvas, staff);
    } else if (staff.clef == Clef.BASS) {
      drawBassClef(canvas, staff);
    }

    drawKeySignature(canvas, staff);
  }

  void drawTrebleClef(Canvas canvas, Staff staff) {
    drawSymbol(canvas, staff, trebleClef, 7, 5.5, 15, 0);
  }

  void drawBassClef(Canvas canvas, Staff staff) {
    drawSymbol(canvas, staff, bassClef, 4, 4.2, 15, 0);
  }

  void drawKeySignature(canvas, staff) {
    if (staff.keySignature > 0) {
      for (var i = 0; i < staff.keySignature; i++) {
        final position = staff.clef.sharpPositions[i];
        drawSharp(canvas, staff, 60.0 + i * 12, position);
      }
    } else if (staff.keySignature < 0) {
      for (var i = 0; i < staff.keySignature.abs(); i++) {
        final position = staff.clef.flatPositions[i];
        drawFlat(canvas, staff, 60.0 + i * 12, position);
      }
    }
  }

  void drawSharp(Canvas canvas, Staff staff, double x, int position) {
    drawSymbol(canvas, staff, sharp, 2.5, 1.2, x, position);
  }

  void drawFlat(Canvas canvas, Staff staff, double x, int position) {
    drawSymbol(canvas, staff, flat, 2.5, 1.7, x, position);
  }

  Size drawSymbol(Canvas canvas, Staff staff, ui.Image image,
      double relativeHeight, double yAdjustment, double x, int position) {
    final imWidth = image.width * 1.0;
    final imHeight = image.height * 1.0;

    final height = relativeHeight * Staff.lineGap;
    final width = height * (imWidth / imHeight);

    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, imWidth, imHeight),
        Rect.fromLTWH(
            x,
            staff.startY - (yAdjustment + position / 2) * Staff.lineGap,
            width,
            height),
        symbolPaint);

    return Size(width, height);
  }

  void drawNote(Canvas canvas, Staff staff, double x, Pitch pitch) {
    final noteSize = drawSymbol(
        canvas, staff, wholeNote, 1, 0.5, x, staff.notePosition(pitch));
    final xCenter = x + 0.5 * noteSize.width;

    staff.ledgerLinesY(pitch).forEach((y) {
      canvas.drawLine(
          Offset(xCenter - 15, y), Offset(xCenter + 15, y), linePaint);
    });
  }

  @override
  bool shouldRepaint(StaffPainter oldDelegate) => false;
}
