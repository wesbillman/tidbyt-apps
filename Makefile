.PHONY: dev preview serve-btc serve-stocks serve-github render push-btc push-stocks push-github push-all clean help

help:
	@echo "Available commands:"
	@echo "  make serve-btc       - Preview Bitcoin app in browser (localhost:8080)"
	@echo "  make serve-stocks    - Preview Stocks app in browser"
	@echo "  make serve-github    - Preview GitHub Repos app in browser"
	@echo "  make dev          - Serve ALL apps with hot reload (ports 8090-8092)"
	@echo "  make preview      - Render 8x magnified GIFs to .build/preview/"
	@echo "  make render          - Render all apps to .build/ without pushing"
	@echo "  make push-btc        - Push Bitcoin screen to your Tidbyt"
	@echo "  make push-stocks     - Push Stocks screen to your Tidbyt"
	@echo "  make push-github     - Push GitHub Repos screen to your Tidbyt"
	@echo "  make push-all        - Push all screens to your Tidbyt rotation"

serve-btc:
	pixlet serve apps/bitcoin/bitcoin.star

serve-stocks:
	pixlet serve apps/stocks/stocks.star

serve-github:
	pixlet serve apps/github/github.star

# Serve all apps at once with hot reload (Ctrl+C stops all)
dev:
	@echo "Bitcoin: http://localhost:8090"
	@echo "Stocks:  http://localhost:8091"
	@echo "GitHub:  http://localhost:8092"
	@trap 'kill 0' INT TERM; \
	pixlet serve -p 8090 apps/bitcoin/bitcoin.star & \
	pixlet serve -p 8091 apps/stocks/stocks.star & \
	pixlet serve -p 8092 apps/github/github.star & \
	wait

# Render magnified GIF snapshots to .build/preview/
preview:
	@mkdir -p .build/preview
	pixlet render apps/bitcoin/bitcoin.star --gif -m 8 -o .build/preview/bitcoin.gif
	pixlet render apps/stocks/stocks.star --gif -m 8 -o .build/preview/stocks.gif
	pixlet render apps/github/github.star --gif -m 8 -o .build/preview/github.gif

render:
	@mkdir -p .build
	pixlet render apps/bitcoin/bitcoin.star -o .build/bitcoin.webp
	pixlet render apps/stocks/stocks.star -o .build/stocks.webp
	pixlet render apps/github/github.star -o .build/github.webp
	@echo "Rendered WebP files in .build/"

push-btc:
	./scripts/push.sh bitcoin

push-stocks:
	./scripts/push.sh stocks

push-github:
	./scripts/push.sh github

push-all:
	./scripts/push.sh all

clean:
	rm -rf .build *.webp *.gif
