# Look Up

A native macOS menu bar app that reminds you to look away from the screen. Every 20 minutes it covers your screens with a breathing animation and a short message for 20 seconds.

Breaks pause while a video plays (YouTube, Netflix, QuickTime, IINA…) or while you are in a call (Google Meet, or anything using the microphone or camera).

See [SPEC.md](SPEC.md) for the full behaviour and [TASKS.md](TASKS.md) for how the work was split.

## Requirements

- macOS 14 or later
- Xcode 16 or later (Swift 6)

## Commands

```bash
make test      # unit tests (LookUpCore)
make app       # build build/LookUp.app (release, ad-hoc signed)
make run       # build and open the app
make preview   # build and show a break immediately
make install   # copy the app to /Applications
```

## Manual test steps

1. Run `make preview`. A break covers every screen. Check the breathing orb, the text, the `Breathe in / Hold / Breathe out` hint and the countdown. Press `Esc` and check that the overlay fades out.
2. Run `make run`. Check the `eye` icon in the menu bar. Open the menu and check the status line (`Next break in 20 min`).
3. Set `Break Interval` to 5 minutes and `Break Duration` to 10 seconds. Wait for the break. Check that it ends by itself after 10 seconds.
4. Use `Break Text…`, type a new text, save. Use `Start Break Now`. Check the new text. Clear the text and save: the default text comes back.
5. Play a YouTube video in a browser. Within 1–2 seconds the icon changes to `pause.circle` and the status reads `Paused — media playing`. Pause the video: the countdown resumes from where it stopped.
6. Join a Google Meet call (or open Photo Booth). The status reads `Paused — in a call`.
7. Play music only (no video). The countdown keeps running.
8. Uncheck `Enabled`: the icon changes to `eye.slash` and no break starts.
9. Lock the screen for more than 30 seconds and unlock: the countdown restarts at the full interval.
10. Quit and reopen: your settings are kept.
