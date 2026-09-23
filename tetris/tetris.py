#!/usr/bin/env python3
import argparse
import math
import os
import select
import shutil
import subprocess
import sys
import tempfile
import termios
import time
import tty
import wave

W,H=10,20
SHAPES={
"I":[[[0,1],[1,1],[2,1],[3,1]],[[2,0],[2,1],[2,2],[2,3]],[[0,1],[1,1],[2,1],[3,1]],[[2,0],[2,1],[2,2],[2,3]]],
"O":[[[1,0],[2,0],[1,1],[2,1]]]*4,
"T":[[[1,0],[0,1],[1,1],[2,1]],[[1,0],[1,1],[2,1],[1,2]],[[0,1],[1,1],[2,1],[1,2]],[[1,0],[0,1],[1,1],[1,2]]],
"S":[[[1,0],[2,0],[0,1],[1,1]],[[1,0],[1,1],[2,1],[2,2]],[[1,0],[2,0],[0,1],[1,1]],[[1,0],[1,1],[2,1],[2,2]]],
"Z":[[[0,0],[1,0],[1,1],[2,1]],[[2,0],[1,1],[2,1],[1,2]],[[0,0],[1,0],[1,1],[2,1]],[[2,0],[1,1],[2,1],[1,2]]],
"J":[[[0,0],[0,1],[1,1],[2,1]],[[1,0],[2,0],[1,1],[1,2]],[[0,1],[1,1],[2,1],[2,2]],[[1,0],[1,1],[0,2],[1,2]]],
"L":[[[2,0],[0,1],[1,1],[2,1]],[[1,0],[1,1],[1,2],[2,2]],[[0,1],[1,1],[2,1],[0,2]],[[0,0],[1,0],[1,1],[1,2]]]}
ORDER=["I","O","T","S","Z","J","L"]
POINTS={1:100,2:300,3:500,4:800}
COLORS={"I":36,"O":93,"T":35,"S":32,"Z":31,"J":34,"L":33}
GHOST="\x1b[2m░░\x1b[0m"
TOP="┌"+"──"*W+"┐"
BOT="└"+"──"*W+"┘"
KEYS="keys: A/D move  S down  W rotate  SPACE drop  Q quit"
KEYMAP={b"a":"left",b"A":"left",b"\x1b[D":"left",b"d":"right",b"D":"right",b"\x1b[C":"right",b"s":"down",b"S":"down",b"\x1b[B":"down",b"w":"rotate",b"W":"rotate",b"\x1b[A":"rotate",b" ":"drop",b"p":"pause",b"P":"pause",b"q":"quit",b"Q":"quit"}
QUIT=(b"q",b"Q")
SOUNDS={"move":[(660,.03)],"rotate":[(520,.05)],"drop":[(240,.07)],"lock":[(180,.09)],"clear":[(523,.06),(659,.06),(784,.06),(1047,.09)],"tetris":[(523,.06),(659,.06),(784,.06),(1047,.06),(1319,.12)],"over":[(392,.12),(311,.12),(262,.14),(196,.22)]}

ABIN=None;AARGS=[];AFILES={};AOUT=None;APROCS=[];ADIR=""

class Game:
    def __init__(self,s):
        self.board=[[0]*W for _ in range(H)];self.cur=None;self.seed=s;self.score=0;self.lines=0;self.over=False
        spawn_with(self,self.board,s,0,0)
def lcg(s):return (s*1103515245+12345)%2147483648
def cells(t,r,x,y):return [[x+c[0],y+c[1]] for c in SHAPES[t][r%4]]
def hits(b,cs):
    for x,y in cs:
        if x<0 or x>=W or y>=H or(y>=0 and b[y][x]):return True
    return False
def spawn_with(g,b,s,sc,li):
    s2=lcg(s);t=ORDER[s2%7]
    g.board=b;g.seed=s2;g.score=sc;g.lines=li
    if hits(b,cells(t,0,3,0)):g.cur=None;g.over=True
    else:g.cur=[t,0,3,0];g.over=False
def lock_and_spawn(g):
    t,r,x,y=g.cur;p=ORDER.index(t)+1
    for cx,cy in cells(t,r,x,y):
        if cy>=0:g.board[cy][cx]=p
    k=[w for w in g.board if not all(w)];n=H-len(k)
    g.board=[[0]*W for _ in range(n)]+k
    sfx("tetris") if n==4 else sfx("clear") if n else sfx("lock")
    spawn_with(g,g.board,g.seed,g.score+POINTS.get(n,0),g.lines+n)
def try_shift(g,dx,dy):
    if g.over or not g.cur:return False
    t,r,x,y=g.cur
    if hits(g.board,cells(t,r,x+dx,y+dy)):return False
    g.cur=[t,r,x+dx,y+dy];return True
def left(g):return try_shift(g,-1,0)
def right(g):return try_shift(g,1,0)
def tick(g):
    if g.over or not g.cur:return g
    t,r,x,y=g.cur
    if hits(g.board,cells(t,r,x,y+1)):lock_and_spawn(g)
    else:g.cur=[t,r,x,y+1]
    return g
def rotate(g):
    if g.over or not g.cur:return False
    t,r,x,y=g.cur;R=(r+1)%4
    for dx,dy in((0,0),(-1,0),(1,0),(0,-1)):
        if not hits(g.board,cells(t,R,x+dx,y+dy)):g.cur=[t,R,x+dx,y+dy];return True
    return False
def hard_drop(g):
    if g.over or not g.cur:return g
    while True:
        t,r,x,y=g.cur
        if hits(g.board,cells(t,r,x,y+1)):lock_and_spawn(g);return g
        g.cur=[t,r,x,y+1]
def apply(g,a):return {"left":left,"right":right,"rotate":rotate,"down":tick,"tick":tick,"drop":hard_drop}.get(a,lambda g:g)(g)
def apply_seq(g,ax):
    for a in ax:apply(g,a)
    return g
def auto_step(g):
    g.seed=lcg(g.seed)
    for _ in range(g.seed%4):rotate(g)
    r2=lcg(g.seed);dx=r2%7-3
    for _ in range(-dx if dx<0 else dx):left(g) if dx<0 else right(g)
    g.seed=r2;hard_drop(g);return g
def auto_play(s,n):
    g=Game(s);o=[g]
    for _ in range(n):auto_step(g);o.append(g)
    return o
def paint(t):return "\x1b["+str(COLORS[t])+"m██\x1b[0m"
def ghost(g):
    t,r,x,y=g.cur
    while not hits(g.board,cells(t,r,x,y+1)):y+=1
    return cells(t,r,x,y)
def render(g):
    d=[w[:] for w in g.board]
    if g.cur and not g.over:
        for x,y in ghost(g):
            if 0<=y<H and 0<=x<W and d[y][x]==0:d[y][x]=-1
        t,r,X,Y=g.cur;p=ORDER.index(t)+1
        for x,y in cells(t,r,X,Y):
            if 0<=y<H and 0<=x<W and d[y][x]<=0:d[y][x]=p
    b=["│"+"".join("  " if v==0 else GHOST if v==-1 else paint(ORDER[v-1]) for v in w)+"│" for w in d]
    s="GAME OVER" if g.over else "EMPTY" if not g.cur else "piece "+g.cur[0]+" rot="+str(g.cur[1]%4)+" x="+str(g.cur[2])+" y="+str(g.cur[3])
    return TOP+"\n"+"\n".join(b)+"\n"+BOT+"\nScore "+str(g.score)+"  Lines "+str(g.lines)+"  Level "+str(g.lines//10+1)+"\n"+s+"  seed="+str(g.seed)
def tone(f,d,r=11025):return bytes(int(128+100*math.sin(6.2832*f*i/r)) for i in range(int(r*d)))
def mkwav(p,s):
    with wave.open(p,"wb") as w:
        w.setnchannels(1);w.setsampwidth(1);w.setframerate(11025)
        for f,d in s:w.writeframes(tone(f,d))
def audio_init(o,nosound):
    global ABIN,AARGS,AFILES,AOUT,ADIR
    AOUT=o
    if nosound:return
    c={"pw-play":[],"paplay":[],"aplay":["-q"],"ffplay":["-nodisp","-autoexit","-loglevel","quiet"]}
    for k,v in c.items():
        b=shutil.which(k)
        if b:ABIN=b;AARGS=v;break
    else:return
    d=tempfile.mkdtemp(prefix="tetris");ADIR=d
    for k,v in SOUNDS.items():
        p=d+"/s_"+k+".wav";mkwav(p,v);AFILES[k]=p
    try:r=subprocess.run([ABIN]+AARGS+[AFILES["move"]],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=3,check=False).returncode
    except (OSError,subprocess.TimeoutExpired):r=1
    if r!=0:ABIN=None;AFILES={}
def sfx(n):
    if ABIN is None:
        if AOUT is not None and n in("clear","tetris","over"):AOUT.write("\a");AOUT.flush()
        return
    APROCS[:]=[p for p in APROCS if p.poll() is None]
    try:APROCS.append(subprocess.Popen([ABIN]+AARGS+[AFILES[n]],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL))
    except OSError:pass
def draw(o,t,f,r):
    if r:t=t.replace("\n","\r\n")
    o.write("\x1b[2J\x1b[H" if f else "\x1b[H");o.write(t);o.write("\x1b[J");o.flush()
def get_key(f,t):
    r,_,_=select.select([f],[],[],t)
    if not r:return None
    c=os.read(f,1)
    if not c:return False
    if c!=b"\x1b":return c
    q=c
    while len(q)<3:
        r,_,_=select.select([f],[],[],0.05)
        if not r:break
        m=os.read(f,1)
        if not m:break
        q+=m
        if q[1:2]!=b"[" and len(q)>=2:break
    return q
def do_act(g,a):
    if a=="left":
        if left(g):sfx("move")
    elif a=="right":
        if right(g):sfx("move")
    elif a=="rotate":
        if rotate(g):sfx("rotate")
    elif a=="down":tick(g)
    elif a=="drop":sfx("drop");hard_drop(g)
def demo(f,w,g,r,iv):
    draw(w,render(g)+"\nautoplay — Ctrl+C quits",True,r)
    while True:
        auto_step(g)
        if g.over:draw(w,render(g)+"\nGAME OVER",False,r);return
        draw(w,render(g)+"\nautoplay — Ctrl+C quits",False,r)
        k=get_key(f,iv)
        if k is False or k in QUIT:return
def play(f,w,g,r,iv):
    draw(w,render(g)+"\n"+KEYS+"  (gravity "+str(iv)+"s)",True,r);nx=time.monotonic()+iv;paused=False
    while True:
        to=None if paused else max(0.0,nx-time.monotonic())
        k=get_key(f,to);n=time.monotonic()
        if k is False:return
        m=KEYMAP.get(k) if isinstance(k,bytes) else None
        if m=="quit":return
        if m=="pause":
            paused=not paused
            if paused:draw(w,render(g)+"\nPAUSED - press P",False,r)
            else:nx=n+iv;draw(w,render(g)+"\n"+KEYS,False,r)
            continue
        if paused:continue
        if not m:
            tick(g);nx=n+iv
            if g.over:sfx("over");draw(w,render(g)+"\nGAME OVER — ./tetris.py to restart",False,r);return
            draw(w,render(g)+"\n"+KEYS,False,r);continue
        do_act(g,m)
        if m=="down" or m=="drop":nx=n+iv
        if g.over:sfx("over");draw(w,render(g)+"\nGAME OVER — ./tetris.py to restart",False,r);return
        draw(w,render(g)+"\n"+KEYS,False,r)
def main():
    a=argparse.ArgumentParser();a.add_argument("--seed",type=int,default=12345);a.add_argument("--demo",action="store_true");a.add_argument("--interval",type=float,default=0.6);a.add_argument("--no-sound",action="store_true");o=a.parse_args()
    f=sys.stdin.fileno();z=None
    if sys.stdin.isatty():z=termios.tcgetattr(f);tty.setraw(f)
    w=sys.stdout;w.write("\x1b[?25l");w.flush()
    try:
        e=sys.stderr
        audio_init(w,o.no_sound)
        if ABIN is None and o.no_sound:e.write("audio: off\n")
        elif ABIN is None:e.write("audio: bell\n")
        else:e.write("audio: "+ABIN+"\n")
        g=Game(o.seed);r=z is not None
        demo(f,w,g,r,o.interval) if o.demo else play(f,w,g,r,o.interval)
    except KeyboardInterrupt:pass
    finally:
        for p in APROCS:
            try:p.terminate()
            except OSError:pass
        if ADIR:shutil.rmtree(ADIR,ignore_errors=True)
        if z is not None:termios.tcsetattr(f,termios.TCSADRAIN,z)
        w.write("\x1b[?25h\n");w.flush()
if __name__=="__main__":main()
