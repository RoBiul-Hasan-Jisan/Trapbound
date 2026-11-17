<div align="center">

# Trapbound

**A gentle-looking platformer where nothing is quite what it seems.**

Reach the exit across 30 handcrafted levels, but trust nothing: floors collapse, doors lie, gravity flips and your controls sometimes reverse.

![Phaser](https://img.shields.io/badge/Phaser-3.80-8e6fb0?style=flat-square)
![TypeScript](https://img.shields.io/badge/TypeScript-5-3178c6?style=flat-square)
![Vite](https://img.shields.io/badge/Vite-5-9d7bff?style=flat-square)
![Platform](https://img.shields.io/badge/platform-web%20%C2%B7%20mobile-9ff0c8?style=flat-square)

</div>

---

## Table of contents

1. [Features](#features)
2. [Controls](#controls)
3. [Quick start](#quick-start)
4. [Scripts](#scripts)
5. [Building and deployment](#building-and-deployment)
6. [Project structure](#project-structure)
7. [Level design guide](#level-design-guide)
8. [Testing tools](#testing-tools)
9. [Design system](#design-system)
10. [Optional: Android app](#optional-android-app)
11. [Troubleshooting](#troubleshooting)
12. [Browser support](#browser-support)
13. [Contributing](#contributing)
14. [License](#license)

## Features

- **30 levels in 3 worlds:** *The Warm-Up*, *False Confidence* and *Reality Glitch*, with a difficulty curve that builds on each trap type.
- **11 trap types:** collapsing and vanishing floors, falling blocks, spikes, saws, moving platforms, crushing walls, timed hazards, decoy doors, reversed controls and gravity flips.
- **Tight, forgiving platforming:** coyote time, jump buffering and variable jump height, with instant restarts so a death never costs more than a moment.
- **Mobile-first controls:** a slide-able glass move pad, a large jump button, safe-area aware layout and haptic feedback.
- **Soft, polished visuals:** dusk gradient sky, drifting glow orbs, rounded UI, particles and gentle transitions.
- **Zero asset files:** graphics are drawn in code and sound is generated with the Web Audio API, so the whole game is a small static site.
- **Saves automatically:** progress and settings are stored in the browser (`localStorage`).
- **Accessible motion:** honours the system "reduce motion" setting by skipping screen shake, flashes, confetti and floating effects.
- **Verified solvable:** every level is checked by an automated solver bot (see [Testing tools](#testing-tools)).

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | `A` `D` or `←` `→` | Glass pad on the left (slide between ◀ and ▶ without lifting) |
| Jump | `W` `↑` or `Space` | ▲ button on the right |
| Pause | `Esc` | **II** button at the top left |
| Restart level | `R` | Pause menu → Restart |
| Back to menu | `M` (while paused) | Pause menu → Menu |

On phones, play in **landscape** for the largest view. The menu also has a **Fullscreen** button.

## Quick start

**Requirements:** [Node.js](https://nodejs.org) 18 or newer and npm.

```bash
git clone <your-repository-url>
cd Trapbound
npm install
npm run dev
```

Open the address Vite prints (usually `http://localhost:5173`). To test on a phone, open the **Network** address from the same Wi-Fi.

## Scripts

| Command | Description |
| --- | --- |
| `npm run dev` | Start the development server with hot reload |
| `npm run build` | Type-check, then create the production build in `dist/` |
| `npm run preview` | Serve the production build locally |
| `npm run typecheck` | Run the TypeScript compiler without emitting files |
| `npm run solve` | Run the level-solver bot (see [Testing tools](#testing-tools)) |
| `npm run test:mobile` | Run the emulated-phone touch test |

## Building and deployment

```bash
npm run build
```

The finished site is written to `dist/`. It is fully static and can be hosted anywhere.

Make sure `vite.config.ts` exists with a relative base path, so the game works from sub-folders and inside app wrappers:

```ts
import { defineConfig } from 'vite';

export default defineConfig({ base: './' });
```

| Host | How |
| --- | --- |
| **Netlify** | Drag the `dist` folder onto <https://app.netlify.com/drop>, or connect the repository (build `npm run build`, publish `dist`) |
| **Vercel** | Import the repository, build command `npm run build`, output directory `dist` |
| **Cloudflare Pages** | Build command `npm run build`, output directory `dist` |
| **GitHub Pages** | Publish the contents of `dist/` using a GitHub Action or a `gh-pages` branch |

Serve over **HTTPS** so fullscreen, vibration and *Add to Home Screen* work reliably on phones.

## Project structure

```
Trapbound/
├── index.html          Page shell, background gradient and touch-control styles
├── src/
│   ├── main.ts         Boots Phaser (after the font loads) and wires the touch controls
│   ├── scenes.ts       Menu, level select and the Game scene (physics, traps, win/lose)
│   ├── levels.ts       Definitions for all 30 levels
│   ├── ui.ts           Palette, text helper, rounded buttons, cards and animated backdrop
│   └── core.ts         Save data, shared touch state and sound effects
├── tools/              Solver bot, mobile test and their notes
├── package.json
└── tsconfig.json
```

**Architecture in short:** three Phaser scenes (`Menu` → `Levels` → `Game`). The `Game` scene builds a level from data in `levels.ts`, runs Arcade Physics for the player, and checks trap triggers and hitboxes each frame. UI and visuals live in `ui.ts`, separate from gameplay logic.

## Level design guide

Levels are plain data in `src/levels.ts`. The play area is **960 × 540** pixels.

```ts
{
  name: 'Easy Does It',
  spawn: [40, 450],            // where the player starts
  exit:  [900, 432],           // top-left of the exit door (32 × 48)
  plats: [[0, 480, 400, 60],   // solid platforms: [x, y, width, height]
          [520, 480, 440, 60]],
  traps: [{ t: 'spike', r: [620, 456, 40, 24], trig: [570, 300, 40, 180] }]
}
```

| Trap `t` | Behaviour |
| --- | --- |
| `spike` | Hidden until triggered, then pops up and kills |
| `collapse` | Looks solid, shakes and falls after the player steps on it |
| `vanish` | Looks solid, disappears shortly after being touched |
| `block` | Drops from above when triggered |
| `saw` | Moves back and forth between `r` and `to` |
| `mover` | Moving platform between `r` and `to` |
| `wall` | Crushing wall that slides between `r` and `to` |
| `timed` | Hazard that switches on and off on a loop (`v` is the period in ms) |
| `fake` | Decoy door that kills on touch |
| `rev` | Reverses left/right controls for 3 seconds |
| `grav` | Flips (`v: -1`) or restores (`v: 1`) gravity |

Useful options: `trig` is the area that fires a trap, `to` is a destination, `v` is speed (or period for `timed`), and `chain` lists traps to fire after this one.

After editing a level, run the solver to confirm it can still be completed.

## Testing tools

Add these to the address bar while running the game:

- `?debug` shows physics boxes, trap trigger zones and a live status line.
- `?test` exposes `window.__g` (the Phaser game) and `window.__t` (touch state), and disables decorative effects so bots run quickly.

**Level solver** (`tools/solve.py`) loads the real game, simulates a clock and searches input sequences until the exit is reached, then replays the result to confirm it. **Mobile test** (`tools/mobile_test.py`) drives an emulated phone with real taps and takes screenshots.

Both need Python, Playwright and Chromium:

```bash
pip install playwright
npm run build
npx vite preview --port 4173      # keep this running in another terminal
python3 tools/solve.py            # all levels, or pass level indexes: solve.py 0 4 12
python3 tools/mobile_test.py
```

`MAXR` and `CAP` environment variables raise the solver's search budget for harder levels.

## Design system

| Role | Colour |
| --- | --- |
| Sky gradient | `#4a3d82` → `#7656a6` → `#a56fa8` |
| Platforms | `#b7a3e6` with `#f0eaff` edge |
| Player | `#ffe3b0` |
| Exit door | `#9ff0c8` |
| Hazards | `#ff8fa3`, `#ff7a93`, `#ffc27a` |
| Accents | rose `#ff9eb5`, sky `#9cc8ff`, lilac `#c9a8ff` |
| Text | `#fdf6ff`, muted `#c9bde0` |

The font is **Nunito**. All colours and helpers are centralised in `src/ui.ts`, so a re-theme is a small change.

## Optional: Android app

The web build can be wrapped as an Android app with [Capacitor](https://capacitorjs.com):

```bash
npm i @capacitor/core @capacitor/android
npm i -D @capacitor/cli
npx cap init Trapbound com.yourname.trapbound --web-dir=dist
npm run build
npx cap add android
npx cap sync
```

Then open the `android/` folder in Android Studio to run or build an APK. After every game change, run `npm run build` and `npx cap sync`. To lock the game to landscape, add `android:screenOrientation="sensorLandscape"` to the activity in `AndroidManifest.xml`.

**No Android Studio?** Host the web build and use [PWABuilder](https://www.pwabuilder.com) to generate an Android package from the live link.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Blank screen after deploying or inside an app | Add `vite.config.ts` with `base: './'` and rebuild |
| Text looks like a plain system font | The Google Font could not load (offline or blocked). Bundle Nunito locally with `@font-face` |
| No sound until I tap | Browsers block audio before the first interaction. Tap anywhere, then it works |
| Controls missing on desktop | Touch controls only appear on touch devices by design |
| Page scrolls or zooms on a phone | Make sure the viewport meta tag in `index.html` is unchanged |
| Saved progress disappeared | Progress lives in browser storage and is lost if site data is cleared or a private window is used |
| `npx cap` says "could not determine executable" | Capacitor is not installed. Run the install commands in the Android section first |

## Browser support

Current versions of Chrome, Edge, Firefox and Safari on desktop, and Chrome and Safari on Android and iOS. WebGL is used when available, with a canvas fallback.

## Contributing

Ideas and fixes are welcome.

1. Create a branch for your change.
2. Run `npm run typecheck` and `npm run build`.
3. If you changed a level or gameplay, run `npm run solve` and make sure every level still passes.
4. Open a pull request describing what changed and why.

Please keep gameplay logic and visuals separate: physics and traps in `scenes.ts`, look and feel in `ui.ts` and `index.html`.

## License

No license has been chosen yet. Add a `LICENSE` file (for example MIT) before sharing the project publicly, and update this section to match.

---

<div align="center">Made with <a href="https://phaser.io">Phaser</a> · soft dusk palette · built to be fun on a phone</div>
