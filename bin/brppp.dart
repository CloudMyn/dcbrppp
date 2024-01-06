// ignore_for_file: non_constant_identifier_names, prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:csv/csv.dart';

void main() {
  // Read values from the configuration file
  Map<String, dynamic> config = readConfigFile('dcbrppp.conf');

  // Extract values from the config map
  int indexLookup = int.tryParse(config['INDEX_LOOKUP']) ?? 3;
  int indexValue = int.tryParse(config['INDEX_VALUE']) ?? 6;

  String delimiter = config['DELIMITER'];
  String keys = config['KEYS'];
  String directoryPath = config['DIRECTORY'];
  String resultDirectory = config['RESULT_DIRECTORY'];

  // Map the keys and values from the config to target map
  Map<String, int> target = Map.fromEntries(
    keys.split('|').map((entry) {
      var parts = entry.split(',');
      return MapEntry(
          parts[0].toString(), int.tryParse(parts[1]) ?? 9999999999999);
    }),
  );

  removeFilesInDirectory(resultDirectory);

  // List all files in the directory
  var directory = Directory(directoryPath);
  var files = directory.listSync();

  // Iterate through each file in the directory
  for (var file in files) {
    if (file is File && file.path.endsWith('.csv')) {
      // Read and parse the CSV file
      List<List<dynamic>> csvData =
          readCsvFile(file.path, delimiter: delimiter);

      // Process the CSV data (replace this with your own logic)
      print('Processing ${file.path}:');

      // Specify the file path for the new CSV file
      String filePath = resultDirectory + file.path.split("/").last;

      // Create a new File object
      File newFile = File(filePath);

      newFile.createSync(recursive: true);

      List<dynamic> data = [];

      for (var row in csvData) {
        String plu = row[indexLookup].toString();

        if (target.containsKey(plu)) {
          int qty_old = row[indexValue];

          if (qty_old >= target[plu]!) {
            row[indexValue] = target[plu];
          }
        }

        data.add(row.join(delimiter));
      }

      // Write content to the new file
      newFile.writeAsString(data.join("\n")).then((_) {}).catchError((error) {
        print('Error creating new file: $error');
      });
    }
  }
}

List<List<dynamic>> readCsvFile(String filePath, {required String delimiter}) {
  // Open the CSV file
  var file = File(filePath);
  var contents = file.readAsStringSync();

  // Parse the CSV data
  List<List<dynamic>> csvData =
      CsvToListConverter(fieldDelimiter: delimiter).convert(contents);

  return csvData;
}

void removeFilesInDirectory(String directoryPath) {
  // Create a Directory object
  Directory directory = Directory(directoryPath);

  directory.createSync(recursive: true);

  // List all files in the directory
  List<FileSystemEntity> files = directory.listSync();

  // Remove each file in the directory
  files.forEach((file) {
    if (file is File) {
      file.deleteSync();
      print('File removed: ${file.path}');
    }
  });
}

Map<String, dynamic> readConfigFile(String filePath) {
  // Open the config file
  var file = File(filePath);
  var contents = file.readAsStringSync();

  // Parse the config data
  Map<String, dynamic> config = Map.fromEntries(
    contents.split('\n').where((line) => line.isNotEmpty).map((line) {
      var parts = line.split('=');
      return MapEntry(parts[0], parts[1].trim());
    }),
  );

  return config;
}
