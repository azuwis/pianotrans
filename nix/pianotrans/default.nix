{ stdenv
, lib
, buildPythonPackage
, piano-transcription-inference
, pytorch
, tkinter
, ffmpeg
}:

buildPythonPackage rec {
  pname = "pianotrans";
  version = "0.2.1";

  src = ./../../.;

  propagatedBuildInputs = [
    piano-transcription-inference
    pytorch
    tkinter
  ];

  doCheck = false;

  makeWrapperArgs =
    let
      packagesToBinPath = [ ffmpeg ];
    in
    [ ''--prefix PATH : "${lib.makeBinPath packagesToBinPath}"'' ];

  meta = with lib; {
    description = "Simple GUI for ByteDance's Piano Transcription with Pedals";
    homepage = "https://github.com/azuwis/pianotrans";
    maintainers = with maintainers; [ ];
  };
}
