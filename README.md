# TERRAIN/LINK

**Radio path profile analyzer for the browser.** Click two points on a map, get a terrain cross-section, line-of-sight, Fresnel zone, and diffraction loss in dB — frequency-aware, with realistic multi-obstacle modeling.

![Status](https://img.shields.io/badge/status-stable-green) ![License](https://img.shields.io/badge/license-MIT-blue) ![Single File](https://img.shields.io/badge/build-no_build_step-orange)

## What it does

Plan radio links between two locations. The app samples terrain along the great-circle path between your two points (SRTM elevation data, ~30 m resolution), draws a cross-section, and computes:

- **Line of sight** with Earth-curvature correction (4/3 Earth radius for radio refraction)
- **First Fresnel zone** sized by frequency
- **Knife-edge diffraction loss** for each obstacle along the path,# TERRAIN/LINK

**Radio path profile analyzer for the browser.** Click two points on a map, get a terrain cross-section, line-of-sight, Fresnel zone, and diffraction loss in dB — frequency-aware, with realistic multi-obstacle modeling.

![Status](https://img.shields.io/badge/status-stable-green) ![License](https://img.shields.io/badge/license-MIT-blue) ![Single File](https://img.shields.io/badge/build-no_build_step-orange)

## What it does

Plan radio links between two locations. The app samples terrain along the great-circle path between your two points (SRTM elevation data, ~30 m resolution), draws a cross-section, and computes:

- **Line of sight** with Earth-curvature correction (4/3 Earth radius for radio refraction)
- **First Fresnel zone** sized by frequency
- **Knife-edge diffraction loss** for each obstacle along the path, using the Deygout multi-edge method with ITU-R P.526 corrections to avoid over-counting comparable obstacles
- **Environment clutter loss** for forest, urban, or suburban paths (SRTM is bare-earth)
- **Free-space path loss** and total end-to-end loss in dB

The verdict tells you whether the path is geometrically clear, lightly obstructed, heavily obstructed, or severely obstructed at the frequency you specified. It does *not* attempt to estimate whether your specific radio will close the link — that requires equipment specs (TX power, antenna gain, RX sensitivity, noise) that aren't visible on a map.

## Screenshot

*(Drop a screenshot of the app here)*

## Quick start

### Open directly

It's a single HTML file. Download `terrain-profile.html` and open it in any modern browser:

```bash
# Open in your default browser
xdg-open terrain-profile.html       # Linux
open terrain-profile.html           # macOS
start terrain-profile.html          # Windows
```

No build step, no npm, no API keys.

### Run with Podman / Docker

For a hosted version on your network (so phones on the same Wi-Fi can use it):

```bash
podman build -t terrain-profile .
podman run -d -p 8080:80 --name terrain terrain-profile
```

Visit `http://localhost:8080` — or `http://<your-ip>:8080` from another device.

To stop and remove:

```bash
podman stop terrain && podman rm terrain
```

Docker works identically — substitute `docker` for `podman` in every command.

### Reverse-proxy behind Caddy / nginx / Traefik

The container serves on port 80 internally. Point your reverse proxy at it:

```caddy
terrain.example.com {
    reverse_proxy localhost:8080
}
```

## Using the app

1. **Click the map** to drop point A (the transmitter). Click again to drop point B (the receiver). Drag either pin to refine.
2. **Set antenna heights and frequency** in the side panel. Pick your **environment** — open, suburban, forested, or urban.
3. **Hit "Run Path Analysis."** The elevation profile chart appears at the bottom, with stats and a verdict in the side panel.

Other controls:

- **Locate Me** — uses browser geolocation to center the map on you (GPS-accurate)
- **Use Example** — drops a sample path across mountainous Swiss terrain
- **Layer switcher** (top-right) — toggle between topographic and satellite imagery, with optional place labels
- **Expand icon** (bottom-right of map) — full-width map for easier point planning. Press `Esc` to collapse.
- **A− / A+** (top-right) — adjust side-panel text size, persists across sessions
- **Hover the elevation chart** — a marker appears on the map at the corresponding location
- **Permalink URLs** — the current path is encoded in the URL hash. Bookmark, share, or use browser back/forward.

## The math

### Diffraction loss

Single knife-edge loss uses the ITU-R P.526 approximation of the Fresnel-Kirchhoff parameter ν:

```
ν = h · √(2·(d₁+d₂) / (λ·d₁·d₂))
J(ν) = 6.9 + 20·log₁₀(√((ν−0.1)² + 1) + ν − 0.1)   for ν > −0.78
J(ν) = 0                                            otherwise
```

For multi-obstacle paths, the **Deygout method** is applied recursively. The principal (tallest) obstacle is identified, its loss computed, then sub-edges on each side are found and their losses added — but scaled by `tanh(ν_sub / ν_principal)` per the ITU correction, so secondaries don't get double-counted when they're in the shadow of the principal.

The result is a single diffraction loss number in dB that's:

- **Zero on clear paths**
- **Identical to single knife-edge** when there's one dominant obstacle
- **A few dB higher than single knife-edge** when multiple comparable ridges exist
- **Frequency-aware** — at low VHF, large wavelengths give small ν, so terrain that kills a 2.4 GHz link barely affects 70 MHz

### Earth curvature

The standard 4/3-Earth radius model is used: terrain is "lifted" by `d₁·d₂ / (2·k·R)` with k = 4/3, R = 6371 km. This accounts for the average atmospheric refraction that bends radio waves downward, making the effective horizon slightly farther than the geometric one. The LOS appears as a straight line on the cross-section chart; the visualization is the standard convention used in commercial path-planning tools.

### Clutter loss

SRTM terrain data is bare-earth — it doesn't include trees, buildings, or other ground clutter. A frequency-scaled clutter loss is added on top of the diffraction loss, with saturation at high frequencies (radio waves go over and around clutter, not through 10 km of it):

| Environment | 150 MHz | 1 GHz | 10 GHz |
|---|---|---|---|
| Open | 0 dB | 0 dB | 0 dB |
| Suburban | 4 dB | 8 dB | 13 dB |
| Forested | 7 dB | 11 dB | 16 dB |
| Urban | 10 dB | 14 dB | 19 dB |

These are intentionally crude — real clutter loss depends on path geometry, vegetation density, building heights, and more. The single-number model captures the right order of magnitude for path planning.

### Verdict thresholds

Based on excess loss above free space (diffraction + clutter):

| Verdict | Excess loss | Meaning |
|---|---|---|
| Clear Path | < 6 dB | Essentially free-space conditions |
| Light Obstruction | 6–15 dB | Workable for most equipment |
| Heavy Obstruction | 15–25 dB | Needs good antennas and adequate TX power |
| Marginal | 25–40 dB | May work under favorable atmospheric conditions but unreliable |
| Severe Obstruction | > 40 dB | Unlikely to work without relay or lower frequency |

## Architecture

Single HTML file (~80 KB unminified) with everything inline:

- **HTML** for layout (map pane, side panel, profile pane, top bar)
- **CSS** for the dark "tactical instrument" theme (custom properties, JetBrains Mono + Fraunces fonts from Google Fonts)
- **JavaScript** organized into logical sections:
  - State and map setup (Leaflet)
  - Initial IP-based location guess
  - Reverse geocoding (Nominatim)
  - Permalink (URL hash encode/decode)
  - Elevation cache (`localStorage`)
  - Geolocation (browser API)
  - Geo math (haversine, bearing, interpolation)
  - Elevation API (Open-Meteo primary, Open-Elevation fallback, with retry and chunked requests)
  - Radio math (Fresnel zone, Earth bulge, FSPL, knife-edge, Deygout)
  - Environment clutter
  - Path analysis orchestration
  - Chart rendering (Chart.js)
  - Font scaling

External dependencies are loaded from the jsDelivr CDN with `crossorigin="anonymous"` so any failures surface as real error messages rather than the generic "Script error":

| Library | Version | Purpose |
|---|---|---|
| Leaflet | 1.9.4 | Interactive map |
| Chart.js | 4.4.0 | Profile cross-section |

External services used (all free, no API keys):

- **Esri ArcGIS Online** — map tiles (topo + satellite), permissive CORS, works from `file://`
- **Open-Meteo** — elevation data, primary
- **Open-Elevation** — elevation data, fallback
- **Nominatim** — forward and reverse geocoding (OpenStreetMap)
- **ipapi.co / geojs.io / ipwho.is** — IP-based initial location, tried in order

## Limitations

- **SRTM resolution is ~30 m** — small features (single buildings, narrow gaps) are not represented
- **No clutter database** — environment is a single dropdown; real terrain has localized variations
- **No link budget calculation** — TX power, antenna gain, and RX sensitivity are equipment-specific and aren't part of the analysis
- **Atmospheric ducting and other anomalous propagation modes are not modeled** — the 4/3 Earth model assumes standard refraction
- **Vertical exaggeration on the chart** makes obstructions look more dramatic than they are in reality (this is normal for path profile charts)
- **Free public elevation APIs occasionally rate-limit** — the app retries and falls back, but very long paths (>500 km) may need re-running

## Browser support

Works in any reasonably modern browser. Tested on:

- Chrome / Edge / Brave (Chromium 100+)
- Firefox 100+
- Safari 15+
- Mobile Safari (iOS 15+)
- Chrome for Android

In-app browsers (Facebook, Instagram, Twitter, etc.) **do not work** — they block third-party API calls. The app detects this and shows a warning telling you to open in a real browser.

## Development

The whole app is in one file for simplicity. To work on it:

1. Open `terrain-profile.html` in a browser
2. Edit the source in your editor
3. Reload

For a smoother experience with auto-reload, serve it from any local web server (Python's `http.server`, `npx serve`, etc.) and use your browser's live-reload extension or hot-reload tools of choice.

Pull requests welcome.

## Files in this repository

```
terrain-profile.html    The complete application (single file)
Containerfile           Container build definition (Podman/Docker)
nginx.conf              Nginx configuration for serving the file
README.md               This file
```

## License

MIT. See [LICENSE](LICENSE) for full text. Map tiles, elevation data, and geocoding are provided by their respective services under their own terms.

## Acknowledgments

- **ITU-R P.526** for the knife-edge diffraction approximation
- **Deygout (1966)** for the multi-obstacle method
- **NASA SRTM** for global elevation data
- **OpenStreetMap contributors** for geocoding data
- **Esri** for the free map tile services
- **Open-Meteo** and **Open-Elevation** for free elevation APIs using the Deygout multi-edge method with ITU-R P.526 corrections to avoid over-counting comparable obstacles
- **Environment clutter loss** for forest, urban, or suburban paths (SRTM is bare-earth)
- **Free-space path loss** and total end-to-end loss in dB

The verdict tells you whether the path is geometrically clear, lightly obstructed, heavily obstructed, or severely obstructed at the frequency you specified. It does *not* attempt to estimate whether your specific radio will close the link — that requires equipment specs (TX power, antenna gain, RX sensitivity, noise) that aren't visible on a map.

## Screenshot

*(Drop a screenshot of the app here)*

## Quick start

### Open directly

It's a single HTML file. Download `terrain-profile.html` and open it in any modern browser:

```bash
# Open in your default browser
xdg-open terrain-profile.html       # Linux
open terrain-profile.html           # macOS
start terrain-profile.html          # Windows
```

No build step, no npm, no API keys.

### Run with Podman / Docker

For a hosted version on your network (so phones on the same Wi-Fi can use it):

```bash
podman build -t terrain-profile .
podman run -d -p 8080:80 --name terrain terrain-profile
```

Visit `http://localhost:8080` — or `http://<your-ip>:8080` from another device.

To stop and remove:

```bash
podman stop terrain && podman rm terrain
```

Docker works identically — substitute `docker` for `podman` in every command.

### Reverse-proxy behind Caddy / nginx / Traefik

The container serves on port 80 internally. Point your reverse proxy at it:

```caddy
terrain.example.com {
    reverse_proxy localhost:8080
}
```

## Using the app

1. **Click the map** to drop point A (the transmitter). Click again to drop point B (the receiver). Drag either pin to refine.
2. **Set antenna heights and frequency** in the side panel. Pick your **environment** — open, suburban, forested, or urban.
3. **Hit "Run Path Analysis."** The elevation profile chart appears at the bottom, with stats and a verdict in the side panel.

Other controls:

- **Locate Me** — uses browser geolocation to center the map on you (GPS-accurate)
- **Use Example** — drops a sample path across mountainous Swiss terrain
- **Layer switcher** (top-right) — toggle between topographic and satellite imagery, with optional place labels
- **Expand icon** (bottom-right of map) — full-width map for easier point planning. Press `Esc` to collapse.
- **A− / A+** (top-right) — adjust side-panel text size, persists across sessions
- **Hover the elevation chart** — a marker appears on the map at the corresponding location
- **Permalink URLs** — the current path is encoded in the URL hash. Bookmark, share, or use browser back/forward.

## The math

### Diffraction loss

Single knife-edge loss uses the ITU-R P.526 approximation of the Fresnel-Kirchhoff parameter ν:

```
ν = h · √(2·(d₁+d₂) / (λ·d₁·d₂))
J(ν) = 6.9 + 20·log₁₀(√((ν−0.1)² + 1) + ν − 0.1)   for ν > −0.78
J(ν) = 0                                            otherwise
```

For multi-obstacle paths, the **Deygout method** is applied recursively. The principal (tallest) obstacle is identified, its loss computed, then sub-edges on each side are found and their losses added — but scaled by `tanh(ν_sub / ν_principal)` per the ITU correction, so secondaries don't get double-counted when they're in the shadow of the principal.

The result is a single diffraction loss number in dB that's:

- **Zero on clear paths**
- **Identical to single knife-edge** when there's one dominant obstacle
- **A few dB higher than single knife-edge** when multiple comparable ridges exist
- **Frequency-aware** — at low VHF, large wavelengths give small ν, so terrain that kills a 2.4 GHz link barely affects 70 MHz

### Earth curvature

The standard 4/3-Earth radius model is used: terrain is "lifted" by `d₁·d₂ / (2·k·R)` with k = 4/3, R = 6371 km. This accounts for the average atmospheric refraction that bends radio waves downward, making the effective horizon slightly farther than the geometric one. The LOS appears as a straight line on the cross-section chart; the visualization is the standard convention used in commercial path-planning tools.

### Clutter loss

SRTM terrain data is bare-earth — it doesn't include trees, buildings, or other ground clutter. A frequency-scaled clutter loss is added on top of the diffraction loss, with saturation at high frequencies (radio waves go over and around clutter, not through 10 km of it):

| Environment | 150 MHz | 1 GHz | 10 GHz |
|---|---|---|---|
| Open | 0 dB | 0 dB | 0 dB |
| Suburban | 4 dB | 8 dB | 13 dB |
| Forested | 7 dB | 11 dB | 16 dB |
| Urban | 10 dB | 14 dB | 19 dB |

These are intentionally crude — real clutter loss depends on path geometry, vegetation density, building heights, and more. The single-number model captures the right order of magnitude for path planning.

### Verdict thresholds

Based on excess loss above free space (diffraction + clutter):

| Verdict | Excess loss | Meaning |
|---|---|---|
| Clear Path | < 6 dB | Essentially free-space conditions |
| Light Obstruction | 6–15 dB | Workable for most equipment |
| Heavy Obstruction | 15–25 dB | Needs good antennas and adequate TX power |
| Severe Obstruction | > 25 dB | Challenging — consider relay, lower frequency |

## Architecture

Single HTML file (~80 KB unminified) with everything inline:

- **HTML** for layout (map pane, side panel, profile pane, top bar)
- **CSS** for the dark "tactical instrument" theme (custom properties, JetBrains Mono + Fraunces fonts from Google Fonts)
- **JavaScript** organized into logical sections:
  - State and map setup (Leaflet)
  - Initial IP-based location guess
  - Reverse geocoding (Nominatim)
  - Permalink (URL hash encode/decode)
  - Elevation cache (`localStorage`)
  - Geolocation (browser API)
  - Geo math (haversine, bearing, interpolation)
  - Elevation API (Open-Meteo primary, Open-Elevation fallback, with retry and chunked requests)
  - Radio math (Fresnel zone, Earth bulge, FSPL, knife-edge, Deygout)
  - Environment clutter
  - Path analysis orchestration
  - Chart rendering (Chart.js)
  - Font scaling

External dependencies are loaded from the jsDelivr CDN with `crossorigin="anonymous"` so any failures surface as real error messages rather than the generic "Script error":

| Library | Version | Purpose |
|---|---|---|
| Leaflet | 1.9.4 | Interactive map |
| Chart.js | 4.4.0 | Profile cross-section |

External services used (all free, no API keys):

- **Esri ArcGIS Online** — map tiles (topo + satellite), permissive CORS, works from `file://`
- **Open-Meteo** — elevation data, primary
- **Open-Elevation** — elevation data, fallback
- **Nominatim** — forward and reverse geocoding (OpenStreetMap)
- **ipapi.co / geojs.io / ipwho.is** — IP-based initial location, tried in order

## Limitations

- **SRTM resolution is ~30 m** — small features (single buildings, narrow gaps) are not represented
- **No clutter database** — environment is a single dropdown; real terrain has localized variations
- **No link budget calculation** — TX power, antenna gain, and RX sensitivity are equipment-specific and aren't part of the analysis
- **Atmospheric ducting and other anomalous propagation modes are not modeled** — the 4/3 Earth model assumes standard refraction
- **Vertical exaggeration on the chart** makes obstructions look more dramatic than they are in reality (this is normal for path profile charts)
- **Free public elevation APIs occasionally rate-limit** — the app retries and falls back, but very long paths (>500 km) may need re-running

## Browser support

Works in any reasonably modern browser. Tested on:

- Chrome / Edge / Brave (Chromium 100+)
- Firefox 100+
- Safari 15+
- Mobile Safari (iOS 15+)
- Chrome for Android

In-app browsers (Facebook, Instagram, Twitter, etc.) **do not work** — they block third-party API calls. The app detects this and shows a warning telling you to open in a real browser.

## Development

The whole app is in one file for simplicity. To work on it:

1. Open `terrain-profile.html` in a browser
2. Edit the source in your editor
3. Reload

For a smoother experience with auto-reload, serve it from any local web server (Python's `http.server`, `npx serve`, etc.) and use your browser's live-reload extension or hot-reload tools of choice.

Pull requests welcome.

## Files in this repository

```
terrain-profile.html    The complete application (single file)
Containerfile           Container build definition (Podman/Docker)
nginx.conf              Nginx configuration for serving the file
README.md               This file
```

## License

MIT. See [LICENSE](LICENSE) for full text. Map tiles, elevation data, and geocoding are provided by their respective services under their own terms.

## Acknowledgments

- **ITU-R P.526** for the knife-edge diffraction approximation
- **Deygout (1966)** for the multi-obstacle method
- **NASA SRTM** for global elevation data
- **OpenStreetMap contributors** for geocoding data
- **Esri** for the free map tile services
- **Open-Meteo** and **Open-Elevation** for free elevation APIs
