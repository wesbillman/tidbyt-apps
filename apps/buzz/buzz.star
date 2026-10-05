"""
Tidbyt Buzz App
Displays an animated Buzz bee with site branding based on https://buzz.xyz/.
Features:
  - Animated fluttering bee mark with gentle hovering motion
  - Bold BUZZ lettering + buzz.xyz domain
  - Animated cycling taglines: "your people", "your agents", "your project"
  - Supports classic Buzz Chartreuse (#D7D72E) and Dark theme (#1B1818)
"""

load("render.star", "render")
load("encoding/base64.star", "base64")

# Buzz Bee pixel art (21x15) in Dark Ink (#231E1E) for chartreuse background
BEE_DARK_MID = "iVBORw0KGgoAAAANSUhEUgAAABUAAAAPCAYAAAALWoRrAAAAQUlEQVR42mNgoDdQlpP7jwtT3UCyDUbWiG4Q0Ybicw0+Pk6XE+NVYvEwMpTcOKCdS6llMFFJjBJ5+uUomuR9SgAAAzfcH4V/FPYAAAAASUVORK5CYII="
BEE_DARK_UP = "iVBORw0KGgoAAAANSUhEUgAAABUAAAAPCAYAAAALWoRrAAAAPUlEQVR42mNgoDdQlpP7jwtTbACxmCQX4ePjNJjuhpIdBEPHUFwGk5paqJLEqJrwKTKUEnn6uZQqeZ+aAADyhNwfhZYDRQAAAABJRU5ErkJggg=="
BEE_DARK_DOWN = "iVBORw0KGgoAAAANSUhEUgAAABUAAAAPCAYAAAALWoRrAAAAPUlEQVR42mNgoDdQlpP7jwtT3UCyDUbWiG7Q4DSUIu8TYwhJllDDQAyDyfEe2YbSxKWDz/s0iX265X1KAAAT29wfNccxQAAAAABJRU5ErkJggg=="

# Buzz Bee pixel art (21x15) in Chartreuse (#D7D72E) for dark background
BEE_LIGHT_MID = "iVBORw0KGgoAAAANSUhEUgAAABUAAAAPCAYAAAALWoRrAAAAQUlEQVR42mNgoDe4fl3vPy5MdQPJNhhZI7pBRBuKzzX4+DhdToxXicXDyFBy44B2LqWWwUQlMUrk6ZejaJL3KQEAF9bLy53OpVUAAAAASUVORK5CYII="
BEE_LIGHT_UP = "iVBORw0KGgoAAAANSUhEUgAAABUAAAAPCAYAAAALWoRrAAAAPUlEQVR42mNgoDe4fl3vPy5MsQHEYpJchI+P02C6G0p2EAwdQ3EZTGpqoUoSo2rCp8hQSuTp51Kq5H1qAgBFhcvL9WlvnAAAAABJRU5ErkJggg=="
BEE_LIGHT_DOWN = "iVBORw0KGgoAAAANSUhEUgAAABUAAAAPCAYAAAALWoRrAAAAPUlEQVR42mNgoDe4fl3vPy5MdQPJNhhZI7pBg9NQirxPjCEkWUINAzEMJsd7ZBtKE5cOPu/TJPbplvcpAQDqGMvLnfCw+wAAAABJRU5ErkJggg=="

CHARTREUSE = "#D7D72E"
DARK_INK = "#231E1E"
DARK_BG = "#191717"
SUBTLE_INK = "#5C5638"
SUBTLE_LIGHT = "#99994A"

TAGLINES = [
    "agents",
    "people",
    "project",
]

def render_bee(frame_idx, dark_theme):
    # Wing cycle: mid -> up -> mid -> down
    wing_stage = frame_idx % 4
    if wing_stage == 0:
        b64 = BEE_LIGHT_MID if dark_theme else BEE_DARK_MID
    elif wing_stage == 1:
        b64 = BEE_LIGHT_UP if dark_theme else BEE_DARK_UP
    elif wing_stage == 2:
        b64 = BEE_LIGHT_MID if dark_theme else BEE_DARK_MID
    else:
        b64 = BEE_LIGHT_DOWN if dark_theme else BEE_DARK_DOWN

    # Gentle hover motion (bob 1px up and down every 8 frames)
    hover_y = 1 if (frame_idx % 8) < 4 else 0

    return render.Padding(
        pad = (0, hover_y, 0, 1 - hover_y),
        child = render.Image(src = base64.decode(b64)),
    )

def main(config):
    theme = config.get("theme", "chartreuse").lower().strip()
    dark_theme = (theme == "dark")

    bg_color = DARK_BG if dark_theme else CHARTREUSE
    primary_color = CHARTREUSE if dark_theme else DARK_INK
    secondary_color = SUBTLE_LIGHT if dark_theme else SUBTLE_INK

    frames = []
    # Total animation: 3 taglines x 8 frames = 24 frames (~3.6s loop at 150ms/frame)
    for t_idx, tagline in enumerate(TAGLINES):
        for sub_frame in range(8):
            frame_num = t_idx * 8 + sub_frame
            bee = render_bee(frame_num, dark_theme)

            frame = render.Box(
                width = 64,
                height = 32,
                color = bg_color,
                padding = 1,
                child = render.Row(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_between",
                    children = [
                        # Left side: Animated Bee
                        render.Box(
                            width = 22,
                            height = 30,
                            child = bee,
                        ),
                        # Right side: BUZZ text + domain + cycling tagline
                        render.Column(
                            cross_align = "start",
                            main_align = "center",
                            children = [
                                render.Text(
                                    "BUZZ",
                                    color = primary_color,
                                    font = "6x13",
                                ),
                                render.Box(width = 1, height = 1),
                                render.Text(
                                    "buzz.xyz",
                                    color = secondary_color,
                                    font = "tom-thumb",
                                ),
                                render.Box(width = 1, height = 1),
                                render.Text(
                                    tagline,
                                    color = primary_color,
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ],
                ),
            )
            frames.append(frame)

    return render.Root(
        delay = 150,
        child = render.Animation(
            children = frames,
        ),
    )
