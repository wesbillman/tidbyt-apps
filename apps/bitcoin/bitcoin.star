"""
Tidbyt Bitcoin App
Displays live Bitcoin (BTC) price, 24h % change, and 24h high/low range bar.
Data source: Coinbase API (No API key needed).
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("math.star", "math")

# 9x9 pixel Bitcoin icon
BTC_ICON = "iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAAMUlEQVR4nGNggILvk6X+o2MGZAAT+A8EyDRcIbICZIBiALKx2ExCUUQnk4jyHTHhBACWhZQ/DkwZwgAAAABJRU5ErkJggg=="

COINBASE_SPOT_URL = "https://api.coinbase.com/v2/prices/BTC-USD/spot"
COINBASE_STATS_URL = "https://api.exchange.coinbase.com/products/BTC-USD/stats"

def format_number(val_str):
    # Splits integer portion and adds commas (e.g. 85819 -> 85,819)
    parts = val_str.split(".")
    whole = parts[0]
    res = ""
    count = 0
    for i in range(len(whole) - 1, -1, -1):
        if count == 3:
            res = "," + res
            count = 0
        res = whole[i] + res
        count += 1
    return res

def format_k(val_float):
    k_val = val_float / 1000.0
    # One decimal point
    rounded = math.round(k_val * 10.0) / 10.0
    return str(rounded) + "k"

def main(config):
    # Fetch spot price
    spot_res = http.get(COINBASE_SPOT_URL, ttl_seconds = 30)
    stats_res = http.get(COINBASE_STATS_URL, ttl_seconds = 30, headers = {"User-Agent": "pixlet-tidbyt"})

    if spot_res.status_code != 200 or stats_res.status_code != 200:
        return render.Root(
            child = render.Box(
                child = render.Text("BTC Offline", color = "#ff4444", font = "tb-8"),
            ),
        )

    spot_data = spot_res.json().get("data", {})
    price_str = spot_data.get("amount", "0")
    price_float = float(price_str)

    stats_data = stats_res.json()
    open_str = stats_data.get("open", price_str)
    high_str = stats_data.get("high", price_str)
    low_str = stats_data.get("low", price_str)

    open_float = float(open_str)
    high_float = float(high_str)
    low_float = float(low_str)

    # Calculate 24h change
    if open_float > 0:
        change_pct = ((price_float - open_float) / open_float) * 100.0
    else:
        change_pct = 0.0

    is_positive = change_pct >= 0
    change_color = "#00E676" if is_positive else "#FF5252"
    sign = "+" if is_positive else ""
    change_formatted = sign + str(math.round(change_pct * 10.0) / 10.0) + "%"

    # Price string formatted
    display_price = "$" + format_number(price_str)

    # 24h Range Bar Calculation (width: 24 pixels)
    bar_width = 24
    if high_float > low_float and high_float != low_float:
        ratio = (price_float - low_float) / (high_float - low_float)
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
            range_bar_children.append(render.Box(width = 1, height = 2, color = "#F7931A"))
        else:
            range_bar_children.append(render.Box(width = 1, height = 1, color = "#333333"))

    return render.Root(
        child = render.Box(
            padding = 1,
            child = render.Column(
                cross_align = "start",
                main_align = "space_between",
                children = [
                    # Header: Icon + BTC + 24h Change
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Image(src = base64.decode(BTC_ICON)),
                                    render.Box(width = 2, height = 1),
                                    render.Text("BTC", color = "#F7931A", font = "CG-pixel-4x5-mono"),
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
                                display_price,
                                color = "#FFFFFF",
                                font = "6x13",
                            ),
                        ],
                    ),

                    # Bottom: 24h Range Bar
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text(format_k(low_float), color = "#777777", font = "CG-pixel-3x5-mono"),
                            render.Row(
                                cross_align = "center",
                                children = range_bar_children,
                            ),
                            render.Text(format_k(high_float), color = "#777777", font = "CG-pixel-3x5-mono"),
                        ],
                    ),
                ],
            ),
        ),
    )
