"""
Tidbyt Lake Havasu City Weather & Wind App
Displays live weather conditions and detailed marine/wind data for Lake Havasu City, AZ.
Data source: Open-Meteo API (Free, no API key required).
Features:
  - Current temperature & weather condition icon (day/night aware)
  - Daily High / Low range
  - Live wind speed (mph) & wind gusts
  - Visual 8-directional compass arrow pointing with wind flow
  - Cardinal wind direction (e.g., SSE, NW)
"""

load("render.star", "render")
load("http.star", "http")
load("encoding/base64.star", "base64")
load("math.star", "math")

# Lake Havasu City, AZ coordinates
DEFAULT_LAT = 34.4839
DEFAULT_LON = -114.3224
TIMEZONE = "America/Phoenix"

# 10x10 Weather Icons
ICON_SUN = "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAOElEQVR42mNgQAP/JzL8B2EGbACnBC65/9eApiFh7DrRFGEohhmNTyFYDdEKibaaJM+QHDz4AhwAJrN5NV7h8sQAAAAASUVORK5CYII="
ICON_MOON = "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAKUlEQVR42mNgIAf8RwJwsWsM/7EqItkkvAqJdhtZniDZVAxfk2wyLgAA4GZVWVchCzEAAAAASUVORK5CYII="
ICON_PARTLY = "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAJklEQVR42mP4f43hPzJmwAXoo/A/EsCuCQcgShGGYuorJNqNhAAAfWbIpT0x1d4AAAAASUVORK5CYII="
ICON_CLOUD = "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAIklEQVR42mNgoCnYsO/of2RMlCKsinEpwlBMfYVEu5GqAAA1yH/Rg3SuMgAAAABJRU5ErkJggg=="
ICON_RAIN = "iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAALUlEQVR42mNgIAds2Hf0PzImShFWxbgUYSgmWiHRVqMDhyP//5MsSZYmokwEAHlIeE2E9Ja5AAAAAElFTkSuQmCC"

# 7x7 Directional Arrows (Cyan #26C6DA) pointing where the wind is blowing towards
ARROW_N = "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAIUlEQVR42mNgQAJqx279Z8AGQBIwzIBNBzrNQJSx1JUEAOk4Hnh4zgMYAAAAAElFTkSuQmCC"
ARROW_NE = "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAIElEQVR42mNgQANqx279h2EGbACnJEwQQxKvUVSSAAIAdoYeeBRPZQcAAAAASUVORK5CYII="
ARROW_E = "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAHklEQVR42mNgIAWoHbv1H68kXAGMgw3j10mSncgAAN5KJAIPsbG3AAAAAElFTkSuQmCC"
ARROW_SE = "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAHElEQVR42mNQO3brPwM+QEcFOBWCJLBKwiRAGADQeh54tK95JQAAAABJRU5ErkJggg=="
ARROW_S = "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAH0lEQVR42mNgQAJqx279Z8AFqCwJE0SnURTAMFHGAgAlPx54DzysyQAAAABJRU5ErkJggg=="
ARROW_SW = "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAHUlEQVR42mNgwAHUjt36TysJmABWHSBBvEbhUgAAl/EeeJLJmA4AAAAASUVORK5CYII="
ARROW_W = "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAHklEQVR42mNgIAaoHbv1H6cEVkmYBDaMXydBO3EBAI+ZJAJSR0PQAAAAAElFTkSuQmCC"
ARROW_NW = "iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAAG0lEQVR42mNQO3brPwwzoAOcEjBJZBonoJMCAD39Hnjzipj1AAAAAElFTkSuQmCC"

def get_wind_direction_info(deg):
    # deg: 0-360 degrees
    # Wind directions describe where wind is coming FROM.
    # The arrow points where wind is blowing TOWARDS (flow direction = deg + 180)
    cardinals = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    idx = int(math.round(deg / 22.5)) % 16
    cardinal = cardinals[idx]

    # Flow arrow (8 directions)
    flow_deg = (deg + 180) % 360
    flow_idx = int(math.round(flow_deg / 45.0)) % 8
    arrows = [ARROW_N, ARROW_NE, ARROW_E, ARROW_SE, ARROW_S, ARROW_SW, ARROW_W, ARROW_NW]
    return cardinal, arrows[flow_idx]

def get_weather_icon(code, is_day):
    # WMO Weather interpretation codes
    if code == 0 or code == 1:
        return ICON_SUN if is_day else ICON_MOON, "Sunny" if is_day else "Clear"
    elif code == 2:
        return ICON_PARTLY, "Pt Cloudy"
    elif code == 3:
        return ICON_CLOUD, "Overcast"
    elif code >= 51 and code <= 67:
        return ICON_RAIN, "Rain"
    elif code >= 80 and code <= 82:
        return ICON_RAIN, "Showers"
    elif code >= 95:
        return ICON_RAIN, "T-Storm"
    return ICON_SUN if is_day else ICON_MOON, "Fair"

def main(config):
    lat = float(config.get("lat", DEFAULT_LAT))
    lon = float(config.get("lon", DEFAULT_LON))

    url = (
        "https://api.open-meteo.com/v1/forecast" +
        "?latitude=%f&longitude=%f" % (lat, lon) +
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m" +
        "&daily=temperature_2m_max,temperature_2m_min" +
        "&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=%s" % TIMEZONE
    )

    res = http.get(url, ttl_seconds = 300)
    if res.status_code != 200:
        return render.Root(
            child = render.Box(
                child = render.Text("Weather Err", color = "#FF5252", font = "tom-thumb"),
            ),
        )

    data = res.json()
    curr = data.get("current", {})
    daily = data.get("daily", {})

    temp = int(math.round(curr.get("temperature_2m", 0.0)))
    code = curr.get("weather_code", 0)
    is_day = curr.get("is_day", 1) == 1
    wind_speed = int(math.round(curr.get("wind_speed_10m", 0.0)))
    wind_dir = curr.get("wind_direction_10m", 0.0)
    wind_gusts = int(math.round(curr.get("wind_gusts_10m", 0.0)))

    highs = daily.get("temperature_2m_max", [temp])
    lows = daily.get("temperature_2m_min", [temp])
    high_temp = int(math.round(highs[0])) if highs else temp
    low_temp = int(math.round(lows[0])) if lows else temp

    icon_b64, condition_text = get_weather_icon(code, is_day)
    cardinal, arrow_b64 = get_wind_direction_info(wind_dir)

    # Wind color styling based on speed:
    # Calm/Breeze (< 10 mph) = Cyan #26C6DA
    # Moderate (10-18 mph) = Lime/Green #00E676
    # Breezy/Rough (> 18 mph) = Amber/Orange #FFB74D
    if wind_speed >= 18:
        wind_color = "#FFA726"
    elif wind_speed >= 10:
        wind_color = "#00E676"
    else:
        wind_color = "#26C6DA"

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            padding = 1,
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    # Top Row: HAVASU + High/Low
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text("HAVASU", color = "#64B5F6", font = "CG-pixel-4x5-mono"),
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Text("%d°" % high_temp, color = "#FFA726", font = "tom-thumb"),
                                    render.Box(width = 2, height = 1),
                                    render.Text("%d°" % low_temp, color = "#81D4FA", font = "tom-thumb"),
                                ],
                            ),
                        ],
                    ),

                    # Middle Row: [Temp + Icon] on left | [Wind Arrow + Speed] on right
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            # Weather condition: Icon + Temp
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Image(src = base64.decode(icon_b64)),
                                    render.Box(width = 2, height = 1),
                                    render.Text("%d°" % temp, color = "#FFFFFF", font = "6x13"),
                                ],
                            ),
                            # Wind: Arrow + Speed
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Image(src = base64.decode(arrow_b64)),
                                    render.Box(width = 2, height = 1),
                                    render.Text("%d" % wind_speed, color = wind_color, font = "6x13"),
                                    render.Box(width = 1, height = 1),
                                    render.Text("mph", color = "#80DEEA", font = "tom-thumb"),
                                ],
                            ),
                        ],
                    ),

                    # Bottom Row: Condition name | Direction & Gusts
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text(condition_text, color = "#B0BEC5", font = "tom-thumb"),
                            render.Row(
                                cross_align = "center",
                                children = [
                                    render.Text(cardinal, color = wind_color, font = "tom-thumb"),
                                    render.Box(width = 2, height = 1),
                                    render.Text("G:%d" % wind_gusts, color = "#FFA726", font = "tom-thumb"),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
