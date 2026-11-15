"""Generates the menu-bar logos (logo-dark/light[@Kx].png) from the stacked high-res logo.
Layout matches the original 171x15 one-line logo; scale K=2 for Retina.
Usage (from the repo root): python3 scripts/make_logos.py [K]   (requires Pillow)"""
import sys
from PIL import Image
K=int(sys.argv[1]) if len(sys.argv)>1 else 2
A=Image.open('doc/logo/logo-source.png').convert('RGBA').getchannel('A')
icon=A.crop((0,0,301,300)); icon=icon.crop(icon.getbbox())
w1=A.crop((340,51,A.width,136)); w1=w1.crop(w1.getbbox())
w2=A.crop((340,164,A.width,249)); w2=w2.crop(w2.getbbox())
W,H=171*K,15*K
SS=8
textW=152*K*SS
gapR=0.45
cap=textW/((w1.width+w2.width)/w1.height+gapR)
def sc(im,h): return im.resize((round(im.width*h/im.height),round(h)),Image.LANCZOS)
mask=Image.new('L',(W*SS,H*SS),0)
mask.paste(sc(icon,H*SS),(0,0))
a=sc(w1,cap); b=sc(w2,cap)
x0=19*K*SS; y0=round((H*SS-cap)/2)
mask.paste(a,(x0,y0)); mask.paste(b,(x0+textW-b.width,y0))
mask=mask.resize((W,H),Image.LANCZOS)
suffix='' if K==1 else f'@{K}x'
for base,col in [('logo-dark',(16,15,13)),('logo-light',(186,186,186))]:
    im=Image.new('RGBA',(W,H),col+(0,)); im.putalpha(mask); im.save(f'{base}{suffix}.png', optimize=True)
