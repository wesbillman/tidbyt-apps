"""
Tidbyt Stocks App
Displays live stock / ETF price, daily change, and daily range.
Data source: Yahoo Finance chart API (No API key needed).
Configurable via 'ticker' (defaults to AAPL).
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("math.star", "math")

# 9x9 Stock chart icon
STOCK_ICON = "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAAKElEQVR4nGNgIASelf3HLwnDOCXR2dgFkK3DaSS6IoIOJ1oRIUwMAAB6qD+aiUs0ZwAAAABJRU5ErkJggg=="

DEFAULT_TICKER = "AAPL"

def format_cents(val_float):
    # Rounds to 2 decimal places and ensures format like 123.45
    rounded = math.round(val_float * 100.0) / 100.0
    val_str = str(rounded)
    parts = val_str.split(".")
    if len(parts) == 1:
        return parts[0] + ".00"
    if len(parts[1]) == 1:
        return parts[0] + "." + parts[1] + "0"
    return parts[0] + "." + parts[1][:2]

def main(config):
    ticker = config.get("ticker", DEFAULT_TICKER).upper().strip()
    if not ticker:
        ticker = DEFAULT_TICKER

    url = "https://query1.finance.yahoo.com/v8/finance/chart/%s?interval=1d&range=1d" % ticker
    res = http.get(url, ttl_seconds = 60, headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
    })

    if res.status_code != 200:
        return render.Root(
            child = render.Box(
                child = render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(ticker, color = "#FFAA00", font = "CG-pixel-4x5-mono"),
                        render.Text("Err %d" % res.status_code, color = "#FF4444", font = "CG-pixel-3x5-mono"),
                    ],
                ),
            ),
        )

    data = res.json()
    chart = data.get("chart", {})
    results = chart.get("result", [])
    if not results:
        return render.Root(
            child = render.Box(
                child = render.Text("Not Found: %s" % ticker, color = "#FF4444", font = "CG-pixel-3x5-mono"),
            ),
        )

    meta = results[0].get("meta", {})
    price = meta.get("regularMarketPrice", 0.0)
    prev_close = meta.get("chartPreviousClose", price)
    day_high = meta.get("regularMarketDayHigh", price)
    day_low = meta.get("regularMarketDayLow", price)

    diff = price - prev_close
    if prev_close > 0:
        change_pct = (diff / prev_close) * 100.0
    else:
        change_pct = 0.0

    is_positive = diff >= 0
    change_color = "#00E676" if is_positive else "#FF5252"
    sign = "+" if is_positive else ""
    change_formatted = sign + str(math.round(change_pct * 10.0) / 10.0) + "%"

    price_formatted = "$" + format_cents(price)

    # Day Range Bar (width: 24 pixels)
    bar_width = 24
    if day_high > day_low and day_high != day_low:
        ratio = (price - day_low) / (day_high - day_low)
        if ratio < 0.0:
            ratio = 0.0
        if ratio > 1.0:
            ratio = 1.0
        pip_pos = int(ratio * (bar_width - 2))
    else:
        pip_pos = bar_width // 2

    range_bar_children = []
    for i in range(bar_width):
        if i == pip_pos or i == pip_pos + 1:
            range_bar_children.append(render.Box(width = 1, height = 2, color = change_color))
        else:
            range_bar_children.append(render.Box(width = 1, height = 1, color = "#333333"))

    return render.Root(
        child = render.Box(
            padding = 1,
            child = render.Column(
                cross_align = "start",
                main_align = "space_between",
                children = [
                    # Header: Icon + Ticker + Change %
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Image(src = base64.decode(STOCK_ICON)),
                                    render.Box(width = 2, height = 1),
                                    render.Text(ticker, color = "#64B5F6", font = "CG-pixel-4x5-mono"),
                                ],
                            ),
                            render.Text(change_formatted, color = change_color, font = "CG-pixel-3x5-mono"),
                        ],
                    ),

                    # Middle: Big Price
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                price_formatted,
                                color = "#FFFFFF",
                                font = "6x13",
                            ),
                        ],
                    ),

                    # Bottom: Day Low / Bar / Day High
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text(format_cents(day_low), color = "#777777", font = "CG-pixel-3x5-mono"),
                            render.Row(
                                cross_align = "center",
                                children = range_bar_children,
                            ),
                            render.Text(format_cents(day_high), color = "#777777", font = "CG-pixel-3x5-mono"),
                        ],
                    ),
                ],
            ),
        ),
    )
