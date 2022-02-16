{ stdenv
, lib
, buildPythonPackage
, fetchPypi
, matplotlib
, mido
, librosa
, torchlibrosa
}:

buildPythonPackage rec {
  pname = "piano-transcription-inference";
  version = "0.0.5";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-nbhuSkXuWrekFxwdNHaspuag+3K1cKwq90IpATBpWPY=";
  };

  propagatedBuildInputs = [
    matplotlib
    mido
    librosa
    torchlibrosa
  ];

  doCheck = false;

  meta = with lib; {
    description = "PyTorch implemention of part of librosa functions";
    homepage = "https://github.com/qiuqiangkong/torchlibrosa";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
