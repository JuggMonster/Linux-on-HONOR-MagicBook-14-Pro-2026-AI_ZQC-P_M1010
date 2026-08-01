# Keeping the fixes applied across package updates

| | |
|---|---|
| Problem | some fixes live inside files a package update replaces |
| Fix | pacman hooks that rebuild them automatically |
| Scope | Arch-like systems only |

```sh
sudo bash patch/auto-rebuild/install.sh
```

## What is fragile and why

| Fix | Lives in | Replaced by |
|---|---|---|
| [`headset-mic/`](../headset-mic/) | `snd-hda-codec-alc269.ko` | any kernel package update |
| [`sof-audio/`](../sof-audio/) | `snd-sof.ko` | any kernel package update |
| [`fingerprint/`](../fingerprint/) | `libfprint` | any libfprint update |

The other fixes need nothing: the ACPI override is a firmware file, the
mic-mute fixup is a CO-RE BPF object, and the fan module uses DKMS.

Both kernel-module fixes install into `/usr/lib/modules/$KVER/updates/`, which
`depmod` searches before `kernel/`, so the packaged modules are never
overwritten. A new kernel simply has no `updates/` entry yet, which is what the
hook fills in.

## What gets installed

```
/etc/pacman.d/hooks/95-honor-zqcp-kernel-modules.hook
/etc/pacman.d/hooks/96-honor-zqcp-libfprint.hook
/usr/local/lib/honor-zqcp/rebuild.sh     hook dispatcher
/usr/local/lib/honor-zqcp/deferred.sh    runs outside the transaction
/etc/honor-zqcp-autorebuild.conf         REPO= and BUILD_USER=
```

| Hook | Trigger | Action |
|---|---|---|
| `95-…-kernel-modules` | any `usr/lib/modules/*/vmlinuz` installed or upgraded | rebuilds `headset-mic` and `sof-audio` for each kernel named in the transaction, in `PostTransaction` |
| `96-…-libfprint` | `libfprint` installed or upgraded | re-applies the fingerprint patch |

Neither rebuild runs inside the transaction. Both are handed to a transient
systemd unit that waits for `/var/lib/pacman/db.lck` to clear, then runs the
installers. Two reasons: the fingerprint fix calls `pacman -U` and would
deadlock on the database, and every installer fetches its sources from the
matching kernel tag, which was observed to fail with an immediate connection
error when run from inside a transaction. A long build should not hold the
transaction open either. `makepkg` refuses to run as root, so `BUILD_USER`
records the account that installed the hooks.

The deferred work lives in its own script, `deferred.sh`, rather than being
passed to `systemd-run` as a command line: systemd expands `$VAR` in `ExecStart`
itself and would consume the script's own loop variables.

Every step logs to `/var/log/honor-zqcp-autorebuild.log`, and the dispatcher
always exits 0, so a failure reports itself without breaking the transaction.

## Behaviour worth knowing

- Kernels without headers are skipped with a message naming the command to run
  after installing them.
- All installed kernels are rebuilt for, not only the running one, so a
  fallback LTS kernel stays fixed too.
- An installer exit code of `3` means "this fix does not apply to that kernel",
  reported as *skipped* rather than a failure.
- The repository must stay where it was when the hooks were installed. If you
  move it, re-run `install.sh` or edit `REPO` in
  `/etc/honor-zqcp-autorebuild.conf`.
- The rebuild fetches sources from `raw.githubusercontent.com`. Without
  network, it logs the failure and the fix is simply missing until you re-run
  it.

## Trying it without waiting for an update

```sh
echo | sudo /usr/local/lib/honor-zqcp/rebuild.sh modules
```

Empty input means "every installed kernel that has headers".

## Uninstall

```sh
sudo rm /etc/pacman.d/hooks/9[56]-honor-zqcp-*.hook \
        /usr/local/lib/honor-zqcp/rebuild.sh \
        /etc/honor-zqcp-autorebuild.conf
```

`uninstall_patch.sh` does this as part of the full revert.
