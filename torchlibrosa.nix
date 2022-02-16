{ stdenv
, lib
, buildPythonPackage
, fetchPypi
, numpy
, librosa
}:

buildPythonPackage rec {
  pname = "torchlibrosa";
  version = "0.0.9";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-+LzejKvLlJIIwWm9rYPCWQDSueIwnG5gbkwNE+wbv0A=";
  };

  propagatedBuildInputs = [
    numpy
    librosa
  ];

  doCheck = false;

  meta = with lib; {
    description = "PyTorch implemention of part of librosa functions";
    homepage = "https://github.com/qiuqiangkong/torchlibrosa";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
