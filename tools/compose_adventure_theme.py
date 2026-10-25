#!/usr/bin/env python3
"""Original 48-bar Dorian adventure / light rock score, 112 BPM.
Render with FluidSynth, player.timing-source=sample, then encode Vorbis.
"""
from pathlib import Path
import mido,random
R=random.Random(91);mid=mido.MidiFile(ticks_per_beat=480);bpm=112
meta=mido.MidiTrack();mid.tracks.append(meta);meta.append(mido.MetaMessage('set_tempo',tempo=mido.bpm2tempo(bpm)))
length=48*4*480
parts=[('Flute',73,0,82),('Steel guitar',25,1,66),('Clean guitar',27,2,62),('Bass',33,3,88),('Strings',48,4,49),('Horns',60,5,53),('Drums',0,9,68)]
tracks={}
for name,program,ch,vol in parts:
 events=[(0,mido.Message('program_change',program=program,channel=ch)),(0,mido.Message('control_change',control=7,value=vol,channel=ch))];tracks[name]=(events,ch)
def note(part,pitch,beat,dur,vel):
 events,ch=tracks[part];t=round(beat*480);end=min(length,round((beat+dur)*480));events.extend([(t,mido.Message('note_on',note=pitch,velocity=vel,channel=ch)),(end,mido.Message('note_off',note=pitch,velocity=0,channel=ch))])
chords=[(50,[62,65,69]),(53,[60,65,69]),(48,[60,64,67]),(55,[62,67,71])]
# A lyrical 8-bar motif, answered one octave lower in the bridge.
melodies=[[74,77,81,79,77,74,72,74],[77,81,84,81,79,77,76,74],[72,76,79,81,79,76,74,72],[74,79,83,81,79,77,76,74],
[74,77,79,81,84,81,79,77],[77,79,81,79,77,74,72,74],[76,79,81,84,83,81,79,76],[79,77,76,74,72,74,74,74]]
for bar in range(48):
 beat=bar*4;root,chord=chords[bar%4];section=bar//16
 for j,p in enumerate(chord):note('Strings',p,beat,3.9,48)
 for j in range(8):
  note('Steel guitar',chord[j%3]+(12 if j%4==3 else 0),beat+j*.5,.42,58+R.randrange(10))
  if bar>=4:note('Clean guitar',root+12+(7 if j%2 else 0),beat+j*.5,.23,50+R.randrange(8))
 for j in range(4):note('Bass',root-12+(7 if j==3 else 0),beat+j,.82,82)
 melody=melodies[bar%8]
 for j,p in enumerate(melody):
  if j==7 and bar%8==7:continue
  note('Flute',p-(12 if section==1 else 0),beat+j*.5,.88 if j==6 and bar%8==7 else .42,74+R.randrange(9))
 if bar>=16 and bar%2==0:
  for p in chord:note('Horns',p,beat,1.7,48)
 for j in range(8):note('Drums',42,beat+j*.5,.12,42+8*(j%2))
 for j in [0,2]:note('Drums',36,beat+j,.18,82)
 for j in [1,3]:note('Drums',38,beat+j,.18,64)
 if bar%8==0:note('Drums',49,beat,.7,49)
 if bar%8==7:
  for j in range(4):note('Drums',45+j%3,beat+3+j*.25,.13,55+j*5)
for name,(events,ch) in tracks.items():
 track=mido.MidiTrack();mid.tracks.append(track);track.append(mido.MetaMessage('track_name',name=name));last=0
 for t,event in sorted(events,key=lambda e:(e[0],e[1].type=='note_on')):
  track.append(event.copy(time=t-last));last=t
 track.append(mido.MetaMessage('end_of_track',time=length-last))
out=Path(__file__).resolve().parents[1]/'assets/audio/adventure_theme.mid';mid.save(out);print(out)
