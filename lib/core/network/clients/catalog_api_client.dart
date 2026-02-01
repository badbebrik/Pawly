import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/catalog_models.dart';

class CatalogApiClient {
  CatalogApiClient(this._apiClient);

  final ApiClient _apiClient;

  static const _options = ApiRequestOptions(
    includeLocale: true,
    includeAcceptLanguage: true,
  );

  Future<CatalogVersionResponse> getVersion() {
    return _apiClient.get<CatalogVersionResponse>(
      ApiEndpoints.catalogVersion,
      requestOptions: _options,
      decoder: CatalogVersionResponse.fromJson,
    );
  }

  Future<List<SpeciesItem>> listSpecies({bool activeOnly = true}) {
    return _apiClient.get<List<SpeciesItem>>(
      ApiEndpoints.catalogSpecies,
      queryParameters: <String, dynamic>{'active': activeOnly ? 1 : 0},
      requestOptions: _options,
      decoder: (Object? data) {
        if (data is! List) {
          return const <SpeciesItem>[];
        }

        return data.map(SpeciesItem.fromJson).toList(growable: false);
      },
    );
  }

  Future<List<ColorItem>> listColors({bool activeOnly = true}) {
    return _apiClient.get<List<ColorItem>>(
      ApiEndpoints.catalogColors,
      queryParameters: <String, dynamic>{'active': activeOnly ? 1 : 0},
      requestOptions: _options,
      decoder: (Object? data) {
        if (data is! List) {
          return const <ColorItem>[];
        }

        return data.map(ColorItem.fromJson).toList(growable: false);
      },
    );
  }

  Future<List<PatternItem>> listPatterns({bool activeOnly = true}) {
    return _apiClient.get<List<PatternItem>>(
      ApiEndpoints.catalogPatterns,
      queryParameters: <String, dynamic>{'active': activeOnly ? 1 : 0},
      requestOptions: _options,
      decoder: (Object? data) {
        if (data is! List) {
          return const <PatternItem>[];
        }

        return data.map(PatternItem.fromJson).toList(growable: false);
      },
    );
  }
}
