import subprocess, json, os
from PIL import Image

def extract_frame(video, t, out):
    subprocess.run(['ffmpeg','-y','-v','error','-ss',str(t),'-i',video,'-frames:v','1',out], check=True)

def orb_bbox(video, duration):
    """Union bbox of non-background pixels across 5 sampled frames."""
    boxes = []
    for i in range(5):
        t = duration * (0.1 + 0.2 * i)
        extract_frame(video, t, '_f.png')
        im = Image.open('_f.png').convert('RGB')
        w, h = im.size
        im_small = im.resize((w//4, h//4))
        px = im_small.load()
        sw, sh = im_small.size
        # background = average of 4 corners
        corners = [px[2,2], px[sw-3,2], px[2,sh-3], px[sw-3,sh-3]]
        bg = tuple(sum(c[k] for c in corners)//4 for k in range(3))
        minx, miny, maxx, maxy = sw, sh, 0, 0
        for y in range(sh):
            for x in range(sw):
                r,g,b = px[x,y]
                if abs(r-bg[0])+abs(g-bg[1])+abs(b-bg[2]) > 60:
                    if x<minx: minx=x
                    if x>maxx: maxx=x
                    if y<miny: miny=y
                    if y>maxy: maxy=y
        if maxx>minx:
            boxes.append((minx*4, miny*4, maxx*4, maxy*4))
    if not boxes:
        return None
    minx = min(b[0] for b in boxes); miny = min(b[1] for b in boxes)
    maxx = max(b[2] for b in boxes); maxy = max(b[3] for b in boxes)
    return (minx, miny, maxx, maxy)

jobs = [
    ('orb_day.mp4', 'orb_day_sq.mp4', 5.0),
    ('orb_1.mp4', 'orb_night_sq.mp4', 1.46),
    ('orb_colorful.mp4', 'orb_speak_sq.mp4', 6.3),
    ('orb_sphere2.mp4', 'orb_think_sq.mp4', 12.0),
    ('orb_check.mp4', 'orb_bloom_sq.mp4', 6.0),
]
for src, dst, dur in jobs:
    bb = orb_bbox(src, dur)
    probe = subprocess.run(['ffprobe','-v','error','-select_streams','v:0','-show_entries','stream=width,height','-of','csv=p=0',src], capture_output=True, text=True)
    w, h = map(int, probe.stdout.strip().split(','))
    if bb is None:
        side = min(w,h); cx, cy = w//2, h//2
    else:
        minx, miny, maxx, maxy = bb
        bw, bh = maxx-minx, maxy-miny
        side = int(max(bw, bh) * 1.10)
        cx, cy = (minx+maxx)//2, (miny+maxy)//2
    side = min(side, w, h)
    x = max(0, min(w-side, cx - side//2))
    y = max(0, min(h-side, cy - side//2))
    subprocess.run(['ffmpeg','-y','-v','error','-i',src,
        '-vf', f'crop={side}:{side}:{x}:{y},scale=540:540:flags=lanczos',
        '-c:v','libx264','-preset','slow','-crf','23','-pix_fmt','yuv420p',
        '-movflags','+faststart','-an', dst], check=True)
    print(dst, 'crop', side, x, y, '->', os.path.getsize(dst))
