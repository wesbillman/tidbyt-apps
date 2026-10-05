"""
Tidbyt Bitcoin App
Displays live Bitcoin (BTC) price with a trend chart, cycling between
the last 24 hours and the last 30 days.
Data source: Coinbase API (No API key needed).
"""

load("render.star", "render")
load("http.star", "http")
load("math.star", "math")

COINBASE_SPOT_URL = "https://api.coinbase.com/v2/prices/BTC-USD/spot"
COINBASE_CANDLES_URL = "https://api.exchange.coinbase.com/products/BTC-USD/candles?granularity=%d"

# (label, candle granularity in seconds, number of candles, cache ttl)
PERIODS = [
    ("24H", 900, 96, 300),
    ("30D", 86400, 30, 3600),
]

CHART_HEIGHT = 18
FRAME_MS = 4000

BTC_ORANGE = "#F7931A"
GREEN = "#00E676"
RED = "#FF5252"
GRAY = "#9E9E9E"
GREEN_FILL = "#00E67633"
RED_FILL = "#FF525233"

def format_number(val_float):
    # 85809.12 -> "85,809"
    whole = str(int(math.round(val_float)))
    res = ""
    count = 0
    for i in range(len(whole) - 1, -1, -1):
        if count == 3:
            res = "," + res
            count = 0
        res = whole[i] + res
        count += 1
    return res

def fetch_candles(granularity, count, ttl):
    # Coinbase candle format: [time, low, high, open, close, volume], newest first
    res = http.get(
        COINBASE_CANDLES_URL % granularity,
        ttl_seconds = ttl,
        headers = {"User-Agent": "pixlet-tidbyt"},
    )
    if res.status_code != 200:
        return None
    candles = res.json()[:count]
    return [c for c in reversed(candles)]  # oldest first

def message_frame(msg):
    return render.Box(
        width = 64,
        height = 32,
        child = render.Text(msg, color = RED, font = "tom-thumb"),
    )

def render_period_frame(label, candles, price):
    if not candles or len(candles) < 2:
        return message_frame("BTC %s: no data" % label)

    base = candles[0][3]  # open of the oldest candle in the window

    # Plot relative to the period's opening price: green above, red below
    points = [(float(i), c[4] - base) for i, c in enumerate(candles)]
    points.append((float(len(candles)), price - base))  # live spot price as the last point

    ys = [p[1] for p in points]
    y_min = min(min(ys), 0.0)
    y_max = max(max(ys), 0.0)
    if y_max - y_min < 0.0001:
        y_min, y_max = -1.0, 1.0

    change_pct = ((price - base) / base) * 100.0 if base > 0 else 0.0
    rounded_pct = math.round(change_pct * 10.0) / 10.0
    if rounded_pct > 0:
        change_color, sign = GREEN, "+"
    elif rounded_pct < 0:
        change_color, sign = RED, ""
    else:
        change_color, sign, rounded_pct = GRAY, "", 0.0

    return render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            children = [
                # Row 1: BTC + change % for this period
                render.Padding(
                    pad = (1, 1, 1, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text("BTC", color = BTC_ORANGE, font = "CG-pixel-4x5-mono"),
                            render.Text(sign + str(rounded_pct) + "%", color = change_color, font = "tom-thumb"),
                        ],
                    ),
                ),
                # Row 2: Price + period label
                render.Padding(
                    pad = (1, 1, 1, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Text("$" + format_number(price), color = "#FFFFFF", font = "5x8"),
                            render.Text(label, color = GRAY, font = "tom-thumb"),
                        ],
                    ),
                ),
                # Row 3: Trend chart
                render.Plot(
                    data = points,
                    width = 64,
                    height = CHART_HEIGHT,
                    color = GREEN,
                    color_inverted = RED,
                    fill = True,
                    fill_color = GREEN_FILL,
                    fill_color_inverted = RED_FILL,
                    x_lim = (0, len(points) - 1),
                    y_lim = (y_min, y_max),
                ),
            ],
        ),
    )

def main(config):
    spot_res = http.get(COINBASE_SPOT_URL, ttl_seconds = 30)
    if spot_res.status_code != 200:
        return render.Root(child = message_frame("BTC Offline"))
    price = float(spot_res.json().get("data", {}).get("amount", "0"))

    only = config.get("period", "").upper().strip()

    frames = []
    for label, granularity, count, ttl in PERIODS:
        if only and only != label:
            continue
        candles = fetch_candles(granularity, count, ttl)
        frames.append(render_period_frame(label, candles, price))

    if len(frames) == 1:
        return render.Root(child = frames[0])

    return render.Root(
        delay = FRAME_MS,
        child = render.Animation(children = frames),
    )
