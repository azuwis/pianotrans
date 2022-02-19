#!/usr/bin/env python3

import os
import sys


class Transcribe:

    checkpoint_path = None
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        # running in a PyInstaller bundle
        script_dir = os.path.dirname(sys.argv[0])
        os.environ['PATH'] += os.pathsep + os.path.abspath(os.path.join(script_dir, 'ffmpeg'))
        checkpoint_path = os.path.abspath(os.path.join(script_dir, 'piano_transcription_inference_data', 'note_F1=0.9677_pedal_F1=0.9186.pth'))

    def __init__(self):
        from queue import Queue
        from threading import Thread
        self.transcriptor = None
        self.queue = Queue()
        Thread(target=self.worker, daemon=True).start()

    def hr(self):
        print('------------------------------------------------------------')

    def enqueue(self, file):
        if not self.transcriptor:
            import torch
            from piano_transcription_inference import PianoTranscription
            device = 'cuda' if torch.cuda.is_available() else 'cpu'
            self.transcriptor = PianoTranscription(device=device, checkpoint_path=self.checkpoint_path)
            self.hr()

        print('Queue: {}'.format(file))
        self.queue.put(file)

    def worker(self):
        while True:
            file = self.queue.get()
            try:
                self.inference(file)
            except Exception:
                from traceback import print_exc
                print_exc()
            self.queue.task_done()
            if self.queue.empty():
                print("\nAll done.")

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

def main():
    transcribe = Transcribe()
    files = tuple(sys.argv)[1:]
    if len(files) == 0:
        import platform
        import tkinter as tk
        from tkinter import filedialog, scrolledtext

        ctrl = '⌘' if platform.system() == 'Darwin' else 'CTRL'

        root = tk.Tk()
        root.title('PianoTrans')
        root.config(menu=tk.Menu(root))

        textbox = scrolledtext.ScrolledText(root)
        def output(str):
            textbox.insert('end', str)
            textbox.see('end')
        sys.stdout.write = sys.stderr.write = output

        def open():
            files = filedialog.askopenfilenames(
                    title='Hold {} to select multiple files'.format(ctrl),
                    filetypes = [('audio files', '*')])
            files = root.tk.splitlist(files)
            for file in files:
                transcribe.enqueue(file)
        button = tk.Button(root, text="Add files to queue", command=open)

        button.pack()
        textbox.pack(expand=tk.YES, fill=tk.BOTH)

        root.after(0, open)
        root.mainloop()
    else:
        for file in files:
            transcribe.enqueue(file)
        transcribe.queue.join()


if __name__ == '__main__':
    main()
