import 'dart:io';

void main() {
  final file = File('assets/logo.png');
  if (file.existsSync()) {
    print('Size: \ bytes');
  } else {
    print('File not found');
  }
}
