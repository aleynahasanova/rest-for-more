enum BlockingMode {
  focus,
  reading;

  String get title => this == focus ? 'Focus' : 'Reading';
  String get activity => this == focus ? 'focus' : 'read';
}
