{ stdenv
, lib
, buildPythonPackage
, fetchPypi
, fetchurl
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

  checkpoint = fetchurl {
    name = "note_F1=0.9677_pedal_F1=0.9186.pth";
    url = "https://zenodo.org/record/4034264/files/CRNN_note_F1%3D0.9677_pedal_F1%3D0.9186.pth?download=1";
    sha256 = "sha256-w/qXMHJb9Kdi8cFLyAzVmG6s2gGwJvWkolJc1geHYUE=";
  };

  propagatedBuildInputs = [
    matplotlib
    mido
    librosa
    torchlibrosa
  ];

  postPatch = ''
    substituteInPlace piano_transcription_inference/inference.py --replace \
      "checkpoint_path='{}/piano_transcription_inference_data/note_F1=0.9677_pedal_F1=0.9186.pth'.format(str(Path.home()))" \
      "checkpoint_path='${checkpoint}'"
  '';

  doCheck = false;

  meta = with lib; {
    description = "PyTorch implemention of part of librosa functions";
    homepage = "https://github.com/qiuqiangkong/torchlibrosa";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
