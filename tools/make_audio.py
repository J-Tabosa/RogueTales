"""Reproduce the original short ambient loop. No external samples are used."""
from pathlib import Path
import math, wave, array
rate=22050
duration=16.0
samples=array.array('h',[0])*int(rate*duration)
chords=[(57,60,64),(53,57,60),(48,52,55),(55,59,62)]
notes=[]
for bar,chord in enumerate(chords):
 for beat in range(8):
  note=chord[beat%3]+(12 if beat in (3,7) else 0)
  notes.append((bar*4+beat*.5,note,.17))
 for note in chord:notes.append((bar*4,note-12,.065))
for start,note,gain in notes:
 frequency=440*2**((note-69)/12)
 start_sample=int(start*rate)
 for k in range(min(int(rate*3.8),len(samples)-start_sample)):
  t=k/rate
  envelope=(1-math.exp(-t*55))*math.exp(-t*1.7)
  signal=math.sin(2*math.pi*frequency*t)+.25*math.sin(2*math.pi*frequency*2*t)+.07*math.sin(2*math.pi*frequency*3*t)
  value=samples[start_sample+k]+int(signal*envelope*gain*16000)
  samples[start_sample+k]=max(-32767,min(32767,value))
for i in range(len(samples)):
 fade=min(1,i/(rate*.03),(len(samples)-1-i)/(rate*.03))
 samples[i]=int(samples[i]*fade)
path=Path(__file__).resolve().parents[1]/'assets/audio/camp_theme.wav'
with wave.open(str(path),'wb') as output:
 output.setnchannels(1);output.setsampwidth(2);output.setframerate(rate);output.writeframes(samples.tobytes())
print(path.name, path.stat().st_size)
