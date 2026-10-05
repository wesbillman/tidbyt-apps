.PHONY: serve-btc serve-stocks serve-github render push-btc push-stocks push-github push-all clean help

help:
	@echo "Available commands:"
	@echo "  make serve-btc       - Preview Bitcoin app in browser (localhost:8080)"
	@echo "  make serve-stocks    - Preview Stocks app in browser"
	@echo "  make serve-github    - Preview GitHub Repos app in browser"
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
