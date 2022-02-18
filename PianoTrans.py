#!/usr/bin/env python3

import argparse
import os
import sys
import time
import torch


class Args:
    def __init__(self, **entries):
        self.__dict__.update(entries)

def inference(args):
    """Inference template.

    Args:
      model_type: str
      audio_path: str
      cuda: bool
    """

    from piano_transcription_inference import PianoTranscription, sample_rate, load_audio

    # Arugments & parameters
    audio_path = args.audio_path
    output_midi_path = args.output_midi_path
    checkpoint_path = args.checkpoint_path
    device = 'cuda' if args.cuda and torch.cuda.is_available() else 'cpu'

    # Load audio
    (audio, _) = load_audio(audio_path, sr=sample_rate, mono=True)

    # Transcriptor
    transcriptor = PianoTranscription(device=device, checkpoint_path=checkpoint_path)
    """device: 'cuda' | 'cpu'
    checkpoint_path: None for default path, or str for downloaded checkpoint path.
    """

    # Transcribe and write out to MIDI file
    transcribe_time = time.time()
    transcribed_dict = transcriptor.transcribe(audio, output_midi_path)
    print('Transcribe time: {:.3f} s'.format(time.time() - transcribe_time))

def inference_files(files, checkpoint_path):
    if files:
        for file in files:
            args = Args(**{
                'audio_path': file,
                'output_midi_path': '{}.mid'.format(file),
                'cuda': True,
                'checkpoint_path': checkpoint_path
            })
            print('Transcribe {}, please wait...'.format(file))
            inference(args)
        print("\nAll finished.")

def main():
    checkpoint_path = None
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        # running in a PyInstaller bundle
        script_dir = os.path.dirname(sys.argv[0])
        os.environ['PATH'] += os.pathsep + os.path.abspath(os.path.join(script_dir, 'ffmpeg'))
        checkpoint_path = os.path.abspath(os.path.join(script_dir, 'piano_transcription_inference_data', 'note_F1=0.9677_pedal_F1=0.9186.pth'))

    files = tuple(sys.argv)[1:]
    if len(files) == 0:
        import threading
        import tkinter as tk
        from tkinter import filedialog
        root = tk.Tk()
        root.title('PianoTrans')
        root.config(menu=tk.Menu(root))
        textbox = tk.Text(root)
        textbox.pack(expand=tk.YES, fill=tk.BOTH)
        sys.stdout.write = sys.stderr.write = lambda str: textbox.insert(tk.INSERT, str)
        def open():
          files = filedialog.askopenfilenames(filetypes = [('audio files', '*')])
          files = root.tk.splitlist(files)
          threading.Thread(target=inference_files, args=(files, checkpoint_path)).start()
        button = tk.Button(root, text="Open", command=open)
        button.pack()
        root.after(0, open)
        root.mainloop()
    else:
        inference_files(files, checkpoint_path)

if __name__ == '__main__':
    main()
