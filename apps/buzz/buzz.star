"""
Tidbyt Buzz App
Displays "Buzz" centered on the iconic yellow/chartreuse background (#D7D72E)
with lively little bees buzzing and flying around it.
Inspired by https://buzz.xyz/.
"""

load("render.star", "render")
load("encoding/base64.star", "base64")
load("math.star", "math")

# Little bee sprites (6x4) with flapping white wings and ink body
BEE_UP_R = "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAECAYAAACtBE5DAAAAHklEQVR42mNggIL/QIBMg4GynNx/EEZhwxgYErgAAOxLFEfkiQziAAAAAElFTkSuQmCC"
BEE_UP_L = "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAECAYAAACtBE5DAAAAHklEQVR42mNgAIL/QIBMg4GynNx/EEZnY5WAS2IDAByiFEcpoYIaAAAAAElFTkSuQmCC"
BEE_DOWN_R = "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAECAYAAACtBE5DAAAAHUlEQVR42mNgwAeU5eT+gzAKG8bAkICB/0CATAMAloUUR4bEPiYAAAAASUVORK5CYII="
BEE_DOWN_L = "iVBORw0KGgoAAAANSUhEUgAAAAYAAAAECAYAAACtBE5DAAAAHUlEQVR42mNgwAWU5eT+gzA6G6sEXPI/ECDTIAAAxs0UR3+vGngAAAAASUVORK5CYII="

CHARTREUSE = "#D7D72E"
INK = "#231E1E"

NUM_FRAMES = 40
FRAME_DELAY_MS = 80

def get_bee_sprite(wing_up, facing_right):
    if wing_up:
        return BEE_UP_R if facing_right else BEE_UP_L
    return BEE_DOWN_R if facing_right else BEE_DOWN_L

def main(config):
    frames = []

    for i in range(NUM_FRAMES):
        t = (2.0 * math.pi * i) / NUM_FRAMES

        # Bee 1: Oval perimeter loop around "Buzz"
        # Clockwise orbit: x = 29 + 25*cos(t), y = 14 + 11*sin(t)
        x1 = int(math.round(29.0 + 25.0 * math.cos(t)))
        y1 = int(math.round(14.0 + 11.0 * math.sin(t)))
        dx1 = -math.sin(t)
        facing1 = (dx1 >= 0)
        wing1 = (i % 2 == 0)

        # Bee 2: Figure-8 infinity flight path
        # x = 29 + 23*sin(t), y = 14 + 10*sin(2t)
        x2 = int(math.round(29.0 + 23.0 * math.sin(t)))
        y2 = int(math.round(14.0 + 10.0 * math.sin(2.0 * t)))
        dx2 = math.cos(t)
        facing2 = (dx2 >= 0)
        wing2 = (i % 2 == 1)

        # Bee 3: Fast-darting bee on diagonal swoops
        t3 = 2.0 * t
        x3 = int(math.round(29.0 + 26.0 * math.cos(t3)))
        y3 = int(math.round(14.0 + 9.0 * math.sin(t3 + (math.pi / 3.0))))
        dx3 = -math.sin(t3)
        facing3 = (dx3 >= 0)
        wing3 = ((i + 1) % 2 == 0)

        stack_children = [
            # 1. Solid Yellow/Chartreuse Background
            render.Box(width = 64, height = 32, color = CHARTREUSE),

            # 2. Bold "Buzz" in the exact center
            render.Box(
                width = 64,
                height = 32,
                child = render.Text(
                    "Buzz",
                    color = INK,
                    font = "10x20",
                ),
            ),

            # 3. Flying Bee 1
            render.Padding(
                pad = (x1, y1, 0, 0),
                child = render.Image(src = base64.decode(get_bee_sprite(wing1, facing1))),
            ),

            # 4. Flying Bee 2
            render.Padding(
                pad = (x2, y2, 0, 0),
                child = render.Image(src = base64.decode(get_bee_sprite(wing2, facing2))),
            ),

            # 5. Flying Bee 3
            render.Padding(
                pad = (x3, y3, 0, 0),
                child = render.Image(src = base64.decode(get_bee_sprite(wing3, facing3))),
            ),
        ]

        frames.append(render.Stack(children = stack_children))

    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Animation(children = frames),
    )
