{ stdenv
, lib
, buildPythonPackage
, fetchPypi
, fetchpatch
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

  patches = [
    # Fix run against librosa 0.9.0, https://github.com/qiuqiangkong/torchlibrosa/pull/8
    (fetchpatch {
      url = "https://github.com/qiuqiangkong/torchlibrosa/commit/eec7e7559a47d0ef0017322aee29a31dad0572d5.patch";
      sha256 = "sha256-c1x3MA14Plm7+lVuqiuLWgSY6FW615qnKbcWAfbrcas=";
    })
  ];

  # Project has no tests
  doCheck = false;

  meta = with lib; {
    description = "PyTorch implemention of part of librosa functions";
    homepage = "https://github.com/qiuqiangkong/torchlibrosa";
    license = licenses.mit;
    maintainers = with maintainers; [ azuwis ];
  };
}
