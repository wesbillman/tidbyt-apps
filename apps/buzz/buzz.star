"""
Tidbyt Buzz App
Displays uppercase "BUZZ" in the center matching the buzz.xyz Cash Sans font,
with mini bees styled after the official buzz.xyz bee logo buzzing around it
on the signature yellow background (#D7D72E).
"""

load("render.star", "render")
load("encoding/base64.star", "base64")
load("math.star", "math")

# Exact Cash Sans Bold "BUZZ" wordmark (32x9)
BUZZ_WORDMARK = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAJCAYAAABT2S4KAAAAVElEQVR42mNQlpP7jw0zQAE6H5sYLjNgavDKE6uZ5g7AZQExDsAmR7Q8NaKAWDms8tR0AMmWE2MBsQ4gOeip6QCyLac4BROQJwYTTAO4LCHGA8RgALjv8KE8rcX9AAAAAElFTkSuQmCC"

# Mini bees (11x7) matching the official buzz.xyz geometric bee mark
MINI_BEE_MID = "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAHCAYAAADebrddAAAAK0lEQVR42mNgQAPKcnL/YZgBH4ApQKdxmoYLY1WIzxDSTMbmZlx8BlJCAwBtrzKXXu7hogAAAABJRU5ErkJggg=="
MINI_BEE_UP = "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAHCAYAAADebrddAAAALUlEQVR42mNgQAPKcnL/YZgBG0BXgEyjaEQWIITxWo3XSThNw+V2fHwGUkIDAMswMpcSLP55AAAAAElFTkSuQmCC"
MINI_BEE_DOWN = "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAHCAYAAADebrddAAAAKklEQVR42mNgQAPKcnL/YZgBH4ApQKdxKkbHDMRajSGOzTRcmDSTSQkNABAuMpdCbIh3AAAAAElFTkSuQmCC"

CHARTREUSE = "#D7D72E"

NUM_FRAMES = 36
FRAME_DELAY_MS = 90

def get_bee_sprite(wing_stage):
    if wing_stage == 0:
        return MINI_BEE_MID
    elif wing_stage == 1:
        return MINI_BEE_UP
    elif wing_stage == 2:
        return MINI_BEE_MID
    else:
        return MINI_BEE_DOWN

def main(config):
    frames = []

    for i in range(NUM_FRAMES):
        t = (2.0 * math.pi * i) / NUM_FRAMES

        # Bee 1: Clockwise perimeter loop around "BUZZ"
        x1 = int(math.round(27.0 + 24.0 * math.cos(t)))
        y1 = int(math.round(12.0 + 10.0 * math.sin(t)))
        w1 = i % 4

        # Bee 2: Counter-clockwise loop offset by 180 degrees (opposite side)
        t2 = -t + math.pi
        x2 = int(math.round(27.0 + 24.0 * math.cos(t2)))
        y2 = int(math.round(12.0 + 10.0 * math.sin(t2)))
        w2 = (i + 2) % 4

        # Bee 3: Playful wavy loop across top and bottom
        t3 = t + (math.pi / 2.0)
        x3 = int(math.round(27.0 + 25.0 * math.sin(t3)))
        y3 = int(math.round(12.0 + 10.5 * math.cos(t3)))
        w3 = (i + 1) % 4

        stack_children = [
            # 1. Signature Yellow Background
            render.Box(width = 64, height = 32, color = CHARTREUSE),

            # 2. Centered Cash Sans "BUZZ" Wordmark (32x9, centered at x=16, y=11)
            render.Padding(
                pad = (16, 11, 0, 0),
                child = render.Image(src = base64.decode(BUZZ_WORDMARK)),
            ),

            # 3. Flying Mini Bee 1
            render.Padding(
                pad = (x1, y1, 0, 0),
                child = render.Image(src = base64.decode(get_bee_sprite(w1))),
            ),

            # 4. Flying Mini Bee 2
            render.Padding(
                pad = (x2, y2, 0, 0),
                child = render.Image(src = base64.decode(get_bee_sprite(w2))),
            ),

            # 5. Flying Mini Bee 3
            render.Padding(
                pad = (x3, y3, 0, 0),
                child = render.Image(src = base64.decode(get_bee_sprite(w3))),
            ),
        ]

        frames.append(render.Stack(children = stack_children))

    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Animation(children = frames),
    )
