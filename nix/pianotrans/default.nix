{
  lib,
  python3,
  ffmpeg,
}:

python3.pkgs.buildPythonApplication {
  pname = "pianotrans";
  version = "1.0.1";
  format = "setuptools";

  src =
    with lib.fileset;
    toSource {
      root = ../../.;
      fileset = unions [
        ../../PianoTrans.py
        ../../setup.py
      ];
    };

  propagatedBuildInputs = with python3.pkgs; [
    piano-transcription-inference
    resampy
    tkinter
    torch
  ];

  # Project has no tests
  doCheck = false;

  makeWrapperArgs = [ ''--prefix PATH : "${lib.makeBinPath [ ffmpeg ]}"'' ];

  meta = with lib; {
    description = "Simple GUI for ByteDance's Piano Transcription with Pedals";
    homepage = "https://github.com/azuwis/pianotrans";
    license = licenses.mit;
    maintainers = with maintainers; [ azuwis ];
  };
}
