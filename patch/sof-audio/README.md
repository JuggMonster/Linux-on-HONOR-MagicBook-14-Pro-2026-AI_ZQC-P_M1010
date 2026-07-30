# SOF DSP suspend/resume panic — preventive backport

**This fix is preventive.** The bug it addresses never reproduced on the unit
this repo was developed on. It is shipped because the upstream fix is small and
clean and the trigger is workload-dependent, so it may surface later.

## The upstream bug

On Intel SOF platforms including Panther Lake, the IPC4 `ipc_config_data`
buffer for copier widgets is built once during `ipc_prepare` and cached. On
suspend/resume the host and link DMA streams are released and re-allocated,
potentially with different stream tags — but because the widget list persists
across suspend, `sof_pcm_hw_params` skips `sof_pcm_setup_connected_widgets` and
`ipc_prepare` never runs again.

The stale cached payload is then sent to firmware carrying boot-time DMA
channel assignments, which collide with the newly allocated ones. Result: DMA
channel conflict, firmware panic, dead audio until reboot.

Documented upstream as thesofproject/sof#10700, *"Dell XPS 14 DA14260 (Panther
Lake): DSP error when unsuspending"*. The fix is Peter Ujfalusi's copier-payload
refresh, thesofproject/linux PR #5762 — one file, refreshing the payload before
widget setup.

## Why it is here despite not reproducing

An earlier session in this repo believed a DSP panic was the cause of the
mic-mute problem. **That was wrong**, and the record is corrected here to save
anyone the same detour:

- The real cause of the mic-mute symptom is the EC firmware — see
  [`../micmute/`](../micmute/).
- The diagnostic that appeared to show DSP panics was counting *every*
  `fw_state` transition, which includes ordinary runtime-PM D3 entries. Those
  are normal power management, not crashes.
- A direct test — `pavucontrol` open, `rtcwake -m mem -s 8` three times —
  produced **zero** `DSP panic!` entries, and the six boots in the local
  journal contain zero as well.

So the backport stays as insurance only. Whether the upstream race triggers
depends on application behaviour (which PipeWire version, whether streams are
open at the moment of suspend), so a clean run today is not proof it cannot
happen.

## Installing

```sh
sudo bash patch/sof-audio/install.sh
```

Fetches the running kernel's `sound/soc/sof` tree from the upstream stable
tree, applies the patch, builds `snd-sof.ko` out-of-tree, and drops it into the
modules `updates/` overlay so it loads instead of the in-tree module.

Re-run after every kernel update. Becomes unnecessary once the fix reaches the
kernel you run — at that point delete the overlay and this directory.
