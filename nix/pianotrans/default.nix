{ lib
, fetchFromGitHub
, python3Packages
, ffmpeg
}:

python3Packages.buildPythonApplication rec {
  pname = "pianotrans";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "azuwis";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-6Otup1Yat1dBZdSoR4lDfpytUQ2RbDXC6ieo835Nw+U=";
  };

  propagatedBuildInputs = with python3Packages; [
    piano-transcription-inference
    torch
    tkinter
  ];

  # Project has no tests
  doCheck = false;

  makeWrapperArgs = [
    ''--prefix PATH : "${lib.makeBinPath [ ffmpeg ]}"''
  ];

  meta = with lib; {
    description = "Simple GUI for ByteDance's Piano Transcription with Pedals";
    homepage = "https://github.com/azuwis/pianotrans";
    license = licenses.mit;
    maintainers = with maintainers; [ azuwis ];
  };
}
