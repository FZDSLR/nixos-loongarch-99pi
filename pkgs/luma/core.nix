{ lib
, buildPythonPackage
, fetchFromGitHub
, pillow
, smbus2
, pyftdi
, cbor2
, spidev
, setuptools
}:

buildPythonPackage rec {
  pname = "luma.core";
  version = "2.4.2";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "rm-hull";
    repo = "luma.core";
    rev = "${version}"; # 6b69584e41a286ef09bab4a371b407120fb27f9b
    sha256 = "sha256-ykI7T2Qv6oEEqC/nnCmFisyJhQz70UZxozpOWYCu7RU=";
  };

  postPatch = ''
    rm -rf tests
  '';

#  nativeBuildInputs = [
#    setuptools-scm
#  ];

  propagatedBuildInputs = [
    pillow
    smbus2
    pyftdi
    cbor2
    spidev
    setuptools
  ];

}
