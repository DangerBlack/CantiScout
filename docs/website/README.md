# CantiScout Website

Static website for [CantiScout](https://512b.it/cantiscout) — a mobile songbook built for offline singing.

## Structure

```
docs/website/
├── index.html              # Landing page
├── chordpro.html           # ChordPro beginner's guide
├── terms.html              # Terms of Service & Privacy Policy
├── assets/
│   ├── css/
│   │   └── style.css       # Mobile-first stylesheet
│   ├── images/
│   │   └── logo.svg        # Brand logo
│   └── gallery/
│       └── screenshot-*.jpg  # App screenshots for the carousel
└── README.md
```

## Local development

```bash
# Python 3
cd docs/website
python -m http.server 8000
# → http://localhost:8000
```

## Deployment (GitHub Pages)

The site is published automatically by the
[`pages.yml`](../../.github/workflows/pages.yml) workflow, which uploads the
`docs/website/` folder to GitHub Pages on every push to `main` that touches
`docs/website/**`. You can also trigger it manually from **Actions → Deploy
website to GitHub Pages → Run workflow**.

Live URL: <https://dangerblack.github.io/CantiScout/>

To deploy manually via rsync:

```bash
rsync -av --delete docs/website/ user@your-server:/var/www/cantiscout/
```

## Adding screenshots

Drop `.jpg` files into `assets/gallery/` and add a slide to the carousel in `index.html`:

```html
<div class="carousel-slide">
  <div class="carousel-card">
    <img src="assets/gallery/screenshot-XX-name.jpg" alt="Description">
  </div>
  <p class="carousel-label">Caption</p>
</div>
```

## Updating download links

Edit the Download section in `index.html`:

```html
<a href="PLAY_STORE_URL" class="download-badge" target="_blank" rel="noopener noreferrer">
  <span>🤖</span> Get it on Google Play
</a>
<a href="APP_STORE_URL" class="download-badge" target="_blank" rel="noopener noreferrer">
  <span>🍎</span> Download on the App Store
</a>
```

Remove the `coming-soon` class from the App Store badge when the iOS app is live.

## Color palette

Extracted from `logo.svg`:

| Variable | Hex | Usage |
|---|---|---|
| `--primary-blue` | `#2D3079` | Headers, footer, nav |
| `--primary-green` | `#689F42` | Buttons, accents, links |
| `--primary-orange` | `#F8971D` | Code block accent, highlights |

## License

MIT — same as the CantiScout app.
