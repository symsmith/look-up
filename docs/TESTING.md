# Manual test checklist

Run these after changes that touch the app shell, the overlay or pause detection. `make test` covers the pure logic in `LookUpCore`.

1. `make preview`: a break covers every screen. Check the breathing orb, the text and the countdown. Press `Esc`: the overlay fades out.
2. `make run`: click the eye and check the status line (`Next break in 20 min`).
3. Set the interval to 5 minutes and the duration to 10 seconds. Wait for the break. It ends by itself after 10 seconds.
4. Type a new break text and click `Start Break Now`: the panel closes and the break shows the new text. Clear the field: the next break shows the default text.
5. Play a YouTube video: the icon changes to the closed eye and the status reads `Paused — media playing`. Pause the video: the countdown resumes.
6. Join a Google Meet call, or open Photo Booth: `Paused — in a call`.
7. Play music only: the countdown keeps running.
8. Switch `Enabled` off: the icon changes to the slashed eye and no break starts.
9. Lock the screen for more than 30 seconds and unlock: the countdown restarts at the full interval.
10. Quit and reopen: your settings are kept.
