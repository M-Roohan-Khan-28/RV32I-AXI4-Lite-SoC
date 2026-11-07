# SoC AXI4-Lite response-order checker qualification

The passive checker rejects `BVALID` until accepted AW and W requests exist
and `RVALID` until AR was accepted. It checks VALID even under response
backpressure and uses pre-edge accepted state. The legal positive case covers
AW-first, W-first, same-edge AW/W, and stalled read response. This is bounded
checker qualification, not full AXI4-Lite or processor verification.

Reviewed baseline: `f39edbe0d23e28dafced897a7792bfd5be140b0a`.
Corrected checker/test commit: `837e31852535a4def42af85bfc9500109725a55a`.
The old checker was byte-checked against the baseline and tested only in a
disposable negative control.

| Run | Observed result | Evidence |
| --- | --- | --- |
| Old checker | Legal positive accepted; all 8 isolated violations escaped the checker and caused the test's missing-detection fatal | [raw logs and JSON](../reports/technical-completion-2026-11-07/baseline-negative-control/) |
| Corrected checker at `837e318` | Legal positive accepted; all 8 violations produced the expected checker fatal | [raw logs and JSON](../reports/technical-completion-2026-11-07/corrected-qualification/) |
| Existing SoC regression at `837e318` | 24/24 runs passed, wrapper exit 0 in a disposable local clone | [fresh logs and console](../reports/technical-completion-2026-11-07/functional-regression/) |
| Safe regression at `3d36480b02ceaa8c1574025f7ad4a29c0d3d8ab8` | 24/24 runs passed, wrapper exit 0 from a clean local clone; source remained clean | [JSON, raw logs, measured integration VCD](../reports/technical-completion-2026-11-07/safe-regression/) |

ModelSim Intel FPGA Starter Edition was `vsim 2020.1 Simulator 2020.02 Feb
28 2020`. The qualification is directed with no RNG seed and a 60-second
subprocess timeout per case. This ModelSim returned process exit 0 even for
`$fatal`; `scripts/run_checker_response_order.py` requires the exact expected
fatal line and records the actual simulator exit. The first 24-run check used
a disposable clone because the old runner wrote tracked `logs/` files. The
updated `run_regression.ps1` writes to a fresh external directory and routes
the integration VCD there. Its clean-clone rerun left all tracked source and
historical logs unchanged, as recorded in `results.json`.

From a clean checkout, use a new qualification output directory:

```powershell
$env:MODELSIM_BIN = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem'
py -3 scripts/run_checker_response_order.py --output-dir C:\short\soc-checker-unique
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1 -OutputDir C:\short\soc-24-unique
```

The [measured qualification waveform](../reports/technical-completion-2026-11-07/measured-waveform/measured.svg)
was rendered from [raw VCD](../reports/technical-completion-2026-11-07/measured-waveform/measured.vcd)
using `tools/vcd_to_svg.py`. Its [capture log](../reports/technical-completion-2026-11-07/measured-waveform/measured.log)
and [metadata](../reports/technical-completion-2026-11-07/measured-waveform/measured.json)
record the actual source hash and 1 ps VCD timebase. The selected public
signals are clock, reset, and AXI4-Lite VALID/READY pairs. The renderer does
not independently verify protocol behavior.

The separate [measured SoC integration figure](../reports/technical-completion-2026-11-07/safe-regression/integration.svg)
shows the committed clean-clone request, response and retirement signals. Its
[raw VCD](../reports/technical-completion-2026-11-07/safe-regression/integration.vcd),
[metadata](../reports/technical-completion-2026-11-07/safe-regression/integration.json),
and [simulation log](../reports/technical-completion-2026-11-07/safe-regression/soc_integration_test.log)
are published together. The figure is a measured trace, not an independent
functional oracle.

The inherited full AXI/peripheral SoC, complete RV32I ISA, coverage closure,
synthesis, timing, FPGA, and hardware remain separate milestones. Original
RTL, history, licences, attribution, and historical reports are preserved.
