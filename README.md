# Tidbyt Custom Apps 💡

A collection of custom screens for the [Tidbyt](https://tidbyt.com) 64×32 pixel LED display, built with [Pixlet](https://github.com/tidbyt/pixlet).

Designed to be hosted safely in a **public repository** with zero secrets committed.

---

## 📱 Apps Included

| App | Description | Data Source | Auth Required? |
|---|---|---|---|
| **Bitcoin** (`apps/bitcoin/`) | Live BTC/USD price with trend charts, cycling between 24H and 30D (`period=24H` or `30D` to pin one) | Coinbase API | ❌ None |
| **Stocks** (`apps/stocks/`) | Price, daily $/% change, and intraday line chart vs. previous close. Cycles through multiple tickers (default `COMP,XYZ`) | Yahoo Finance | ❌ None |
| **GitHub Repos** (`apps/github/`) | Status dashboard for key repos: CI pass/fail on `main`, stars, forks, and open PR count for user. Cycles through repos (default `block/buzz,block/buzz-app`). | GitHub REST API | Optional (for private repos or higher limits) |
| **Buzz** (`apps/buzz/`) | Animated Buzz bee mark with hovering flutter, `buzz.xyz` branding, and cycling taglines (chartreuse or dark theme) | Static / Branded | ❌ None |
| **Weather & Wind** (`apps/weather/`) | Lake Havasu City live weather & wind conditions: temp, day/night condition icon, high/low, wind speed & gusts, and 8-directional compass flow arrow | Open-Meteo API | ❌ None |

---

## 🔒 Security & Keeping Secrets Safe

All sensitive credentials (Tidbyt API key, device ID, GitHub Personal Access Token) are loaded from a local `.env` file that is excluded via `.gitignore`.

1. Copy the example configuration:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and fill in your Tidbyt details:
   - **Tidbyt API Key & Device ID**: In the Tidbyt mobile app, go to **Settings → Mobile App / Developer → Get API Key**.

---

## 🛠 Local Development & Live Preview

You can preview any app in your web browser with hot reloading:

```bash
# Preview individual screens
make serve-btc
make serve-stocks
make serve-github
make serve-buzz
make serve-weather
```

Then open `http://localhost:8080` (or the configured port) in your browser.

Or serve **all** apps at once with hot reload:
```bash
make dev       # Bitcoin :8090, Stocks :8091, GitHub :8092, Buzz :8093, Weather :8094
make preview   # 8x magnified GIF snapshots in .build/preview/
```

To test rendering with custom parameters:
```bash
pixlet render apps/stocks/stocks.star tickers="NVDA,SPY" -o preview.webp
pixlet render apps/github/github.star repos="owner/repo1,owner/repo2" -o preview.webp
pixlet render apps/weather/weather.star -o preview.webp
```

---

## 🚀 Pushing to your Physical Tidbyt

Once your `.env` file is configured:

```bash
# Push an individual screen
make push-btc
make push-stocks
make push-github
make push-buzz
make push-weather

# Push all screens to your device rotation
make push-all
```

*Note: Each screen is assigned an alphanumeric installation ID (`custombitcoin`, `customstocks`, `customgithub`, `custombuzz`, `customweather`), keeping them seamlessly in your Tidbyt's regular rotation alongside your other apps.*

---

## ⏰ Automated Updates (24/7 via GitHub Actions)

Tidbyt custom apps are automatically rendered and pushed to your device every **10 minutes** using the included GitHub Actions workflow ([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)):

- **Runs 24/7 in the Cloud**: No need to keep your Mac awake or run a local server.
- **Immediate Deploy on Git Push**: Any changes pushed to `main` instantly trigger an update to your Tidbyt.
- **Manual Trigger**: You can trigger a run at any time from the **Actions** tab on GitHub via "Run workflow".

### Secrets Configuration
The workflow requires two GitHub Actions secrets (already configured):
- `TIDBYT_DEVICE_ID`: Your Tidbyt device identifier
- `TIDBYT_API_TOKEN`: Your Tidbyt developer API token

### Alternative: Local macOS Cron
If you ever want to run updates locally instead:
```bash
crontab -e
```
Add:
```bash
*/10 * * * * cd /Users/wesbillman/dev/tidbyt-apps && ./scripts/push.sh all >/dev/null 2>&1
```
