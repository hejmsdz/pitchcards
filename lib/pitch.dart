class Pitch {
  int midi;

  Pitch(this.midi);
  static from(String name) {
    final pattern = RegExp(r"([A-G])([b#]?)(\d)");
    final match = pattern.firstMatch(name);
    if (match == null) {
      return null;
    }
    final note = match.group(1);
    final accidental = match.group(2);
    final octave = int.parse(match.group(3)!);

    final noteValues = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };

    final accidentalValues = {
      '#': 1,
      'b': -1,
    };

    final midi = (12 * (octave + 1)) +
        (noteValues[note] ?? 0) +
        (accidentalValues[accidental] ?? 0);
    return new Pitch(midi);
  }

  int octave() {
    return midi ~/ 12 - 1;
  }

  String name([bool useFlat = false]) {
    final pitch = midi % 12;

    const notesSharp = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B'
    ];
    const notesFlat = [
      'C',
      'Db',
      'D',
      'Eb',
      'E',
      'F',
      'Gb',
      'G',
      'Ab',
      'A',
      'Bb',
      'B'
    ];

    return (useFlat ? notesFlat : notesSharp)[pitch];
  }

  @override
  String toString() {
    return "${name()}${octave()}";
  }
}

class Voicing {
  int keySignature;
  Pitch soprano;
  Pitch alto;
  Pitch tenor;
  Pitch bass;

  Voicing(this.keySignature, this.soprano, this.alto, this.tenor, this.bass);
}
