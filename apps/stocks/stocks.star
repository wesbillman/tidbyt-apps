"""
Tidbyt Stocks App
Displays live stock / ETF price, daily change, and an intraday line chart.
Cycles through multiple tickers.
Data source: Yahoo Finance chart API (No API key needed).
Config options:
  - tickers: Comma-separated list of symbols (default: 'COMP,XYZ')
  - ticker:  Legacy single-symbol option (used if 'tickers' is not set)
"""

load("render.star", "render")
load("http.star", "http")
load("math.star", "math")

DEFAULT_TICKERS = "COMP,XYZ"

# 5-minute bars in a regular US session (9:30-16:00 ET)
BAR_SECONDS = 300
SESSION_BARS = 78

CHART_HEIGHT = 18
FRAME_MS = 4000

GREEN = "#00E676"
RED = "#FF5252"
GRAY = "#9E9E9E"
GREEN_FILL = "#00E67633"
RED_FILL = "#FF525233"

def format_cents(val_float):
    rounded = math.round(val_float * 100.0) / 100.0
    val_str = str(rounded)
    parts = val_str.split(".")
    if len(parts) == 1:
        return parts[0] + ".00"
    if len(parts[1]) == 1:
        return parts[0] + "." + parts[1] + "0"
    return parts[0] + "." + parts[1][:2]

def message_frame(ticker, msg):
    return render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            cross_align = "center",
            main_align = "center",
            children = [
                render.Text(ticker, color = "#64B5F6", font = "CG-pixel-4x5-mono"),
                render.Box(width = 1, height = 2),
                render.Text(msg, color = RED, font = "tom-thumb"),
            ],
        ),
    )

def fetch_quote(ticker):
    url = "https://query1.finance.yahoo.com/v8/finance/chart/%s?interval=5m&range=1d" % ticker
    res = http.get(url, ttl_seconds = 60, headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    })
    if res.status_code != 200:
        return None, "Err %d" % res.status_code

    results = res.json().get("chart", {}).get("result") or []
    if not results:
        return None, "Not found"
    return results[0], None

def render_ticker_frame(ticker):
    result, err = fetch_quote(ticker)
    if err:
        return message_frame(ticker, err)

    meta = result.get("meta", {})
    price = meta.get("regularMarketPrice", 0.0)
    prev_close = meta.get("chartPreviousClose") or meta.get("previousClose") or price

    # Build intraday series as (bar_index, price - prev_close) so the plot's
    # zero line is yesterday's close: green above, red below.
    session_start = meta.get("currentTradingPeriod", {}).get("regular", {}).get("start", 0)
    timestamps = result.get("timestamp") or []
    quotes = result.get("indicators", {}).get("quote") or [{}]
    closes = quotes[0].get("close") or []

    points = []
    for i in range(min(len(timestamps), len(closes))):
        c = closes[i]
        if c == None:
            continue
        x = (timestamps[i] - session_start) / BAR_SECONDS if session_start else i
        if x < 0 or x > SESSION_BARS:
            continue
        points.append((float(x), c - prev_close))

    # Change % (round first so tiny moves read as a neutral 0.0%)
    change_pct = ((price - prev_close) / prev_close) * 100.0 if prev_close > 0 else 0.0
    rounded_pct = math.round(change_pct * 10.0) / 10.0
    if rounded_pct > 0:
        change_color, sign = GREEN, "+"
    elif rounded_pct < 0:
        change_color, sign = RED, ""
    else:
        change_color, sign, rounded_pct = GRAY, "", 0.0
    change_formatted = sign + str(rounded_pct) + "%"
    diff = price - prev_close
    diff_formatted = (sign if diff >= 0 else "-") + format_cents(abs(diff))

    # Symmetric-ish y range that always includes the prev-close baseline
    if points:
        ys = [p[1] for p in points]
        y_min = min(min(ys), 0.0)
        y_max = max(max(ys), 0.0)
    else:
        y_min, y_max = -1.0, 1.0
    if y_max - y_min < 0.0001:
        y_min, y_max = -1.0, 1.0

    if len(points) >= 2:
        chart = render.Plot(
            data = points,
            width = 64,
            height = CHART_HEIGHT,
            color = GREEN,
            color_inverted = RED,
            fill = True,
            fill_color = GREEN_FILL,
            fill_color_inverted = RED_FILL,
            x_lim = (0, SESSION_BARS),
            y_lim = (y_min, y_max),
        )
    else:
        chart = render.Box(
            width = 64,
            height = CHART_HEIGHT,
            child = render.Text("no intraday data", color = "#555555", font = "tom-thumb"),
        )

    return render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            children = [
                # Row 1: Ticker + Change %
                render.Padding(
                    pad = (1, 1, 1, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text(ticker, color = "#64B5F6", font = "CG-pixel-4x5-mono"),
                            render.Text(change_formatted, color = change_color, font = "tom-thumb"),
                        ],
                    ),
                ),
                # Row 2: Price + $ change
                render.Padding(
                    pad = (1, 1, 1, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "end",
                        children = [
                            render.Text("$" + format_cents(price), color = "#FFFFFF", font = "5x8"),
                            render.Text(diff_formatted, color = change_color, font = "tom-thumb"),
                        ],
                    ),
                ),
                # Row 3: Intraday chart
                chart,
            ],
        ),
    )

def main(config):
    tickers_str = config.get("tickers") or config.get("ticker") or DEFAULT_TICKERS
    tickers = [t.strip().upper() for t in tickers_str.split(",") if t.strip()]
    if not tickers:
        tickers = DEFAULT_TICKERS.split(",")

    frames = [render_ticker_frame(t) for t in tickers]

    if len(frames) == 1:
        return render.Root(child = frames[0])

    return render.Root(
        delay = FRAME_MS,
        child = render.Animation(children = frames),
    )
