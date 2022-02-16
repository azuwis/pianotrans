{ stdenv
, lib
, buildPythonPackage
, piano-transcription-inference
, pytorch
, tkinter
}:

buildPythonPackage rec {
  pname = "pianotrans";
  version = "0.2.1";

  src = ./.;

  propagatedBuildInputs = [
    piano-transcription-inference
    pytorch
    tkinter
  ];

  postPatch = ''
    substituteInPlace PianoTrans.py --replace \
      "'checkpoint_path': checkpoint_path" \
      "'checkpoint_path': None"
    sed -i PianoTrans.py \
      -e '/ffmpeg/d' \
      -e '/piano_transcription_inference_data/d'
  '';

  doCheck = false;

  meta = with lib; {
    description = "Simple GUI for ByteDance's Piano Transcription with Pedals";
    homepage = "https://github.com/azuwis/pianotrans";
    maintainers = with maintainers; [ ];
  };
}
