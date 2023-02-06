#!/usr/bin/env python3

import os
import sys


class Transcribe:

    def __init__(self, checkpoint=None):
        from queue import Queue
        from threading import Thread
        self.checkpoint = checkpoint
        self.transcriptor = None
        self.queue = Queue()
        Thread(target=self.worker, daemon=True).start()

    def hr(self):
        print('-'*80)

    def enqueue(self, files):
        for file in files:
            print('Queue: {}'.format(file))
            self.queue.put(file)

    def worker(self):
        import torch
        from piano_transcription_inference import PianoTranscription
        device = 'cuda' if torch.cuda.is_available() else 'cpu'
        self.hr()
        self.transcriptor = PianoTranscription(device=device, checkpoint_path=self.checkpoint)

        while True:
            file = self.queue.get()
            try:
                self.inference(file)
            except Exception:
                from traceback import print_exc
                print_exc()
            self.queue.task_done()
            if self.queue.empty():
                self.hr()
                print("Queue finished.")
                self.hr()

    def inference(self, file):
        from piano_transcription_inference import sample_rate, load_audio
        from time import time

        self.hr()
        print('Transcribe: {}'.format(file))

        audio_path = file
        output_midi_path = '{}.mid'.format(file)

        # Load audio
        (audio, _) = load_audio(audio_path, sr=sample_rate, mono=True)

        # Transcribe and write out to MIDI file
        transcribe_time = time()
        transcribed_dict = self.transcriptor.transcribe(audio, output_midi_path)
        print('Transcribe time: {:.3f} s'.format(time() - transcribe_time))


class Gui:

    def __init__(self, transcribe, files=None):
        from platform import system
        from tkinter import Button, Menu, Tk, scrolledtext

        self.transcribe = transcribe
        self.ctrl = '⌘' if system() == 'Darwin' else 'CTRL'

        self.root = Tk()
        self.root.title('PianoTrans')
        self.root.config(menu=Menu(self.root))

        self.textbox = scrolledtext.ScrolledText(self.root)
        sys.stdout.write = sys.stderr.write = self.output

        button = Button(self.root, text="Add files to queue", command=self.open)

        button.pack()
        self.textbox.pack(expand='yes', fill='both')

        if files:
            self.transcribe.enqueue(files)
        else:
            self.root.after(0, self.open)
        self.root.mainloop()

    def open(self):
        from tkinter import filedialog
        files = filedialog.askopenfilenames(
                title='Hold {} to select multiple files'.format(self.ctrl),
                filetypes = [('audio/video files', '*')])
        files = self.root.tk.splitlist(files)
        self.transcribe.enqueue(files)

    def output(self, str):
        self.textbox.insert('end', str)
        self.textbox.see('end')

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--cli', action='store_true', help='Disable GUI')
    parser.add_argument('file', nargs='*', help='File to transcribe')
    args = parser.parse_args()

    checkpoint = None
    is_bundle = getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS')
    if is_bundle:
        # running in a PyInstaller bundle
        script_dir = os.path.dirname(sys.argv[0])
        os.environ['PATH'] += os.pathsep + os.path.abspath(os.path.join(script_dir, 'ffmpeg'))
        checkpoint = os.path.abspath(os.path.join(script_dir, 'piano_transcription_inference_data', 'note_F1=0.9677_pedal_F1=0.9186.pth'))

    transcribe = Transcribe(checkpoint=checkpoint)
    files = args.file
    if (not is_bundle and os.isatty(0) and len(files)) or args.cli > 0:
        transcribe.enqueue(files)
        transcribe.queue.join()
    else:
        from tkinter import TclError
        try:
            Gui(transcribe, files=files)
        except TclError as e:
            print ('Error open GUI: {}'.format(e))
            parser.print_help()


if __name__ == '__main__':
    main()
