
// String api = "http://103.208.183.253:5000/api/v1";

// String api = "http://103.208.183.248:5000/api/v1";

/// Base API URL – normalized to never end with a trailing slash so that
/// "$api/some/path" never produces double-slashes like ".../v1//some/path".
final String _rawApi = "http://103.208.181.235:5000/api/v1";
final String api = _rawApi.endsWith('/') ? _rawApi.substring(0, _rawApi.length - 1) : _rawApi;


// String api = "http://103.208.183.248:5000/api/v1";

