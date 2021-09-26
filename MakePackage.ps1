function MakeDir {
    param($Dir)
    if (-not (Test-Path $Dir)) {
        mkdir -Path $Dir | Out-Null
    }
}

function DownloadUrl {
    param($Url,$File)
    $WebClient = New-Object System.Net.WebClient
    try {
        $Task = $WebClient.DownloadFileTaskAsync($Url, "$PSScriptRoot\$File")
        Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged | Out-Null
        Start-Sleep -Seconds 1
        While (-Not $Task.IsCompleted) {
            Start-Sleep -Seconds 1
            $EventData = Get-Event -SourceIdentifier WebClient.DownloadProgressChanged | Select-Object -ExpandProperty "SourceEventArgs" -Last 1
            $TotalPercent = $EventData | Select-Object -ExpandProperty "ProgressPercentage"
            Write-Progress -Activity "Downloading $File from $Url" -Status "Percent Complete: $($TotalPercent)%" -PercentComplete $TotalPercent
        }
    }
    catch [System.Net.WebException] {
        Write-Host("Cannot download $Url")
        if ($_.Exception.InnerException) {
            Write-Error $_.Exception.InnerException.Message
        } else {
            Write-Error $_.Exception.Message
        }
    }
    finally {
        Write-Progress -Activity "Downloading $File from $Url" -Completed
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        $WebClient.Dispose()
    }
}

function UnpackUrl {
    param($Url,$File,$UnpackDir,$TestPath)
    if (-not $File) {
        $File = $Url.Substring($Url.LastIndexOf("/") + 1)
    }
    $Output = "dist\downloads\$File"
    if (-not $TestPath) {
        $TestPath = $UnpackDir
    }
    if (-not (Test-Path "$TestPath")) {
        Write-Host "UnpackUrl: $Url -> $UnpackDir"
        if (-not (Test-Path $Output)) {
            Import-Module BitsTransfer
            DownloadUrl -Url $Url -File $Output
        }
        switch ((Get-Item $Output).Extension) {
            '.zip' {
                $shell = New-Object -com shell.application
                $shell.Namespace([IO.Path]::Combine($pwd, $UnpackDir)).CopyHere($shell.Namespace([IO.Path]::Combine($pwd, $Output)).Items())
            }
            '.exe' {
                Start-Process $output -Wait -ArgumentList "-y -o$UnpackDir"
            }
        }
    }
}

MakeDir build\
MakeDir dist\downloads\

UnpackUrl -Url https://github.com/winpython/winpython/releases/download/2.3.20200530/Winpython64-3.7.7.1dot.exe `
    -UnpackDir build\ -TestPath build\python\
if (-not (Test-Path build\python\)) {
    mv build\WPy64-3771\ build\python\
}

$Python="build\python\scripts\python.bat"
$ScriptsDir="build\python\python-3.7.7.amd64\Scripts"
$LibsDir="build\python\python-3.7.7.amd64\Lib\site-packages"

MakeDir build\pip\
$PipCacheDir=Resolve-Path build\pip\ | select -ExpandProperty Path

MakeDir build\temp\
$TempDir=Resolve-Path build\temp\ | select -ExpandProperty Path
$env:TEMP=$TempDir

if (-not (Test-Path $LibsDir\torch)) {
    & $Python -m pip --cache-dir "$PipCacheDir" install torch -f https://download.pytorch.org/whl/torch_stable.html
}

if (-not (Test-Path $LibsDir\piano_transcription_inference)) {
    & $Python -m pip --cache-dir "$PipCacheDir" install numpy==1.20.0 piano_transcription_inference
}

if (-not (Test-Path $ScriptsDir\pyinstaller.exe)) {
    & $Python -m pip --cache-dir "$PipCacheDir" install pyinstaller
}

& $Python -m pip freeze | Out-File -encoding UTF8 pip.txt

if (-not (Test-Path build\dist\PianoTrans\)) {
    cp PianoTrans.py, PianoTrans.spec build\
    & $Python $ScriptsDir\pyinstaller.exe `
    --noconfirm `
    --distpath build\dist\ `
    --workpath build\build\ `
    --specpath build\ `
    build\PianoTrans.spec
}

MakeDir build\dist\PianoTrans\piano_transcription_inference_data\
UnpackUrl -Url 'https://zenodo.org/record/4034264/files/CRNN_note_F1%3D0.9677_pedal_F1%3D0.9186.pth?download=1' `
    -File 'note_F1=0.9677_pedal_F1=0.9186.pth' -TestPath 'dist\downloads\note_F1=0.9677_pedal_F1=0.9186.pth'
if (-not (Test-Path 'build\dist\PianoTrans\piano_transcription_inference_data\note_F1=0.9677_pedal_F1=0.9186.pth')) {
    cp dist\downloads\note_F1=0.9677_pedal_F1=0.9186.pth 'build\dist\PianoTrans\piano_transcription_inference_data\note_F1=0.9677_pedal_F1=0.9186.pth'
}

$ffmpeg_version='ffmpeg-n4.3.1-30-g666d2fc6e2-win64-gpl-4.3'
MakeDir build\dist\PianoTrans\ffmpeg\
UnpackUrl -Url https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2021-02-01-12-44/$ffmpeg_version.zip `
    -UnpackDir build\ -TestPath build\dist\PianoTrans\ffmpeg\ffmpeg.exe
if (Test-Path build\$ffmpeg_version\) {
    mv build\$ffmpeg_version\bin\ffmpeg.exe build\dist\PianoTrans\ffmpeg\
    rm -r build\$ffmpeg_version\
}

MakeDir build\dist\PianoTrans\reg\
cp README.md build\dist\PianoTrans\README.txt
cp RightClickMenuRegister.bat, RightClickMenuUnregister.bat build\dist\PianoTrans\
cp RightClickMenuRegister.reg.in, RightClickMenuUnregister.reg build\dist\PianoTrans\reg\

if (-not (Test-Path dist\PianoTrans.zip)) {
    Add-Type -assembly "system.io.compression.filesystem"
    [IO.Compression.ZipFile]::CreateFromDirectory([IO.Path]::Combine($pwd, "build\dist\"), [IO.Path]::Combine($pwd, "dist\PianoTrans.zip"))
}

Write-Host
Read-Host "Done, press enter to exit"
