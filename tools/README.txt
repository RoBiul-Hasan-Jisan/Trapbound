Level solver bot (needs: pip install playwright + a Chromium).
  npm run build && npx vite preview --port 4173 &
  python3 tools/solve.py [levelIndex ...]     (MAXR / CAP env vars raise the search budget)
It loads /?test, steps the real Phaser game with a simulated clock, and searches input sequences
(DFS over 100 ms input chunks) until the exit is reached, then re-runs the sequence to confirm.
Mobile test: npm run build && npx vite preview --port 4173 &  python3 tools/mobile_test.py  (emulated phone, real taps; screenshots in /tmp)
