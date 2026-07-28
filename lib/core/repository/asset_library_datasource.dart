import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/artwork_model.dart';

class AssetLibraryDataSource {
  AssetLibraryDataSource._();

  static const String _jsonPath = 'assets/mock_data/library.json';

  static Future<List<ArtworkModel>> loadArtworks() async {
    final jsonString = await rootBundle.loadString(_jsonPath);
    final List<dynamic> jsonList = json.decode(jsonString);

    print("==============================");
    print("JSON COUNT = ${jsonList.length}");

    final artworks = jsonList.map((e) => ArtworkModel.fromJson(e)).toList();
    print("ARTWORK COUNT = ${artworks.length}");

    for (final a in artworks.take(10)) {
      print("${a.category} | ${a.subCategory}");
    }
    print("==============================");
    
    return artworks;
  }
}
