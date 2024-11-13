{ lib
, buildPythonPackage
, fetchFromGitHub
, luma-core
, setuptools
}:

buildPythonPackage rec {
  pname = "luma.oled";
  version = "3.13.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "rm-hull";
    repo = "luma.oled";
    rev = "${version}"; # 8dc4569c1d04b9933c5d534e004e35360929068d
    sha256 = "sha256-QsTalbyPrhBsM95TuSVzJyWoh7KTZGXBXktrNRV8Tl0=";
  };

  postPatch = ''
    rm -rf tests
  '';

  propagatedBuildInputs = [
    luma-core
    setuptools
  ];

}
