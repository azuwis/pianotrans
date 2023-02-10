import setuptools

setuptools.setup(
    name="pianotrans",
    version="1.0.1",
    author="Zhong Jianxin",
    author_email="azuwis@gmail.com",
    description="Simple GUI for ByteDance's Piano Transcription with Pedals",
    py_modules=["PianoTrans"],
    install_requires=[
        'piano_transcription_inference',
    ],
    entry_points={
        'console_scripts':[
            'pianotrans = PianoTrans:main',
        ],
    },
)
