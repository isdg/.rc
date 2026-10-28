# LockMirror

A lock that leaves the screen looking as it was. Ctrl+Cmd+L (Hammerspoon,
`hammerspoon/lockmirror.lua`) snapshots every display and starts the
LockMirror screen saver, which draws those snapshots; with the lock set to
immediate, that screen saver is a real `loginwindow` lock. The normal lock
screen appears at the first key press.

The bootstrap (level 3, Darwin) builds `LockMirror.saver` with `swiftc` into
`~/Library/Screen Savers` and links the Hammerspoon config. The rest needs
System Settings or a password, so it is done once by hand on each Mac.

## After the bootstrap

1. **Pick the screen saver.** System Settings > Wallpaper > Screen Saver,
   scroll to Other, choose LockMirror, Done. Do this before the first
   Ctrl+Cmd+L: the saver reads its snapshots from its sandbox folder,
   which macOS creates when the saver host first runs.

   If LockMirror is not listed, the extension cached its list before the
   bundle existed. Quit System Settings, then:

   ```sh
   killall WallpaperLegacyExtension
   ```

2. **Lock as soon as the saver starts.** Otherwise the saver is just a
   picture for the delay:

   ```sh
   sysadminctl -screenLock immediate -password -
   ```

   Or System Settings > Lock Screen > "Require password after screen saver
   begins or display is turned off" > Immediately.

3. **Let Hammerspoon see the screen.** System Settings > Privacy & Security
   > Screen & System Audio Recording: enable Hammerspoon, or the snapshots
   show only the wallpaper. The first lock may also ask to let Hammerspoon
   access data from other apps (the saver's container): allow it.

4. **Check.**

   ```sh
   ~/.rc/.rcboot/boot.sh --ensure
   ```

   The lockmirror lines should all be `[OK]`.

## Tuning the tone

macOS draws screen savers slightly darker than the same pixels on the
desktop, and no screen capture can see it, so the snapshot is brightened by
eye: `exposure` in stops (0.1 is about +7%), `gamma` below 1 lifts only the
mid-tones. `init.lua` holds the value tuned on an LG HDR 4K; another display
may want its own.

Set the lock delay to a few seconds while tuning, then loop:

```sh
hs -c 'require("lockmirror").tone = { exposure = 0.3, gamma = 1 }'
```

Press Ctrl+Cmd+L and watch the fade-in: when it is invisible, the tone is
right. Write the value into the `bind` call in `hammerspoon/init.lua` and
set the delay back to Immediately.

## Limits

- Idle lock, closing the lid and the Touch ID button bypass the hotkey and
  show the normal lock screen.
- Pure white cannot be brightened, so it may stay faintly dim.
- One tone applies to every display.

## Removing it

Pick another screen saver, then:

```sh
rm -rf ~/Library/Screen\ Savers/LockMirror.saver
```
