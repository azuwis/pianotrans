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
  version = "1.0";

  src = ./../../.;

  propagatedBuildInputs = [
    piano-transcription-inference
    pytorch
    tkinter
  ];

  # Project has no tests
  doCheck = false;

  makeWrapperArgs =
    let
      packagesToBinPath = [ ffmpeg ];
    in
    [ ''--prefix PATH : "${lib.makeBinPath packagesToBinPath}"'' ];

  meta = with lib; {
    description = "Simple GUI for ByteDance's Piano Transcription with Pedals";
    homepage = "https://github.com/azuwis/pianotrans";
    maintainers = with maintainers; [ azuwis ];
  };
}
