"""Rebuild original cues and synthetic, nonverbal princess calls.
Effects use only stdlib synthesis. Calls need espeak-ng + ffmpeg (no voice samples).
ESPEAK_BIN / ESPEAK_DATA_PATH may point to a locally extracted distribution.
"""
from pathlib import Path
import array, math, os, random, shutil, subprocess, tempfile, wave
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'assets/audio'
RATE = 22050
rng = random.Random(471)

def write(name, values):
    peak = max(max(map(abs, values)), 0.001)
    pcm = array.array('h', (int(max(-1,min(1,x/peak*.83))*32767) for x in values))
    with wave.open(str(OUT/f'{name}.wav'), 'wb') as target:
        target.setparams((1,2,RATE,len(values),'NONE','not compressed'))
        target.writeframes(pcm.tobytes())

def explosion():
    filtered = 0
    result = []
    for i in range(int(RATE*.55)):
        t=i/RATE
        noise=rng.uniform(-1,1)
        filtered += .13*(noise-filtered)
        v=(filtered*1.6+math.sin(2*math.pi*(92*t-48*t*t))*.52)*math.exp(-t*9)
        v+=noise*.23*math.exp(-t*35)
        result.append(v*min(1,t/.003)*min(1,(.55-t)/.025))
    write('explosion',result)

def jingle(name, notes):
    length=max(start+duration for start,_,duration in notes)+.25
    values=[0.0]*int(RATE*length)
    for start,midi,duration in notes:
        frequency=440*2**((midi-69)/12)
        for i in range(int(RATE*duration)):
            t=i/RATE
            env=min(1,t/.008)*math.exp(-t*3.0)*min(1,(duration-t)/.08)
            sound=math.sin(2*math.pi*frequency*t)+.2*math.sin(2*math.pi*frequency*2*t)
            values[int(start*RATE)+i]+=sound*env*.3
    write(name,values)

def calls():
    espeak=os.environ.get('ESPEAK_BIN') or shutil.which('espeak-ng')
    if not espeak:
        raise SystemExit('Install espeak-ng, or set ESPEAK_BIN, to rebuild the calls.')
    settings=[('scarlet','Hah!', 'f2',76,280),('rapunzel','Hyah!', 'f3',81,260),
              ('snow_white','Hup!', 'f4',84,290),('mulan','Hee yah!', 'f1',65,330),
              ('ariel','Hah!', 'f5',88,250)]
    with tempfile.TemporaryDirectory() as folder:
        for hero,text,voice,pitch,speed in settings:
            raw=Path(folder)/f'{hero}.wav'
            subprocess.run([espeak,'-v',f'en+{voice}','-p',str(pitch),'-s',str(speed),'-w',str(raw),text],check=True)
            subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(raw),'-af',
                'silenceremove=start_periods=1:start_threshold=-40dB:stop_periods=1:stop_duration=0.08:stop_threshold=-40dB,highpass=f=160,lowpass=f=7000,loudnorm=I=-20:TP=-3:LRA=7,afade=t=in:d=0.008,apad=pad_dur=0.025',
                '-ar',str(RATE),'-ac','1','-c:a','pcm_s16le',str(OUT/f'attack_{hero}.wav')],check=True)

if __name__=='__main__':
    explosion()
    jingle('victory',[(0,72,.2),(.15,76,.2),(.3,79,.25),(.52,84,.6),(.52,76,.6),(.52,79,.6)])
    jingle('achievement',[(0,79,.16),(.13,84,.18),(.28,88,.2),(.46,91,.3),(.72,84,.65),(.72,88,.65),(.72,91,.65)])
    calls()
    for path in sorted(OUT.glob('*.wav')):
        with wave.open(str(path)) as stream:
            print(path.name,round(stream.getnframes()/stream.getframerate(),3),'s')
