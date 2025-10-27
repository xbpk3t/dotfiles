{
  rustPlatform,
  fetchFromGitHub,
}:
# https://github.com/danimelchor/todui
rustPlatform.buildRustPackage {
  pname = "todui";
  version = "1642e4e";

  src = fetchFromGitHub {
    owner = "danimelchor";
    repo = "todui";
    rev = "1642e4e";
    hash = "sha256-FxnBSatb+Z7EyD00nMBlYIsh09Rvhk56F1+/6S7JtcU=";
  };

  cargoHash = "sha256-+BmbYoWjpdgviszoYV5jlMa0f91vG63FNfhHxKIvdbc=";

  nativeBuildInputs = [
    rustPlatform.bindgenHook
  ];

  buildInputs = [
  ];

  buildFeatures = [
  ];

  meta = {
  };
}
