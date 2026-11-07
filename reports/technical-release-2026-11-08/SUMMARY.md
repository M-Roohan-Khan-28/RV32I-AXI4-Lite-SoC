# RV32I SoC required checker qualification

Clean detached GitHub branch source:
`6af4cd8e5b49d592610281d6bd953114128b6762`.
ModelSim Intel FPGA Starter Edition:
`vsim 2020.1 Simulator 2020.02 Feb 28 2020`.
The functional regression used directed programs and recorded seeds 1, 17,
and 2026. The checker qualification used directed cases without a random seed.

The project wrapper exited **0**: 24/24 functional runs passed, and the
separate checker qualification accepted one legal case and detected all eight
expected-negative response-order violations. The fresh `results.json`,
24 functional logs, nine checker case logs, checker `RESULTS.json`, simulator
version and wrapper console are under `clean-clone/`. The source worktree was
clean. These qualification cases do not add to the 24 functional-run count.

Reproduce with unused paths:

```powershell
git -c core.autocrlf=false clone --branch technical/response-order-qualification https://github.com/M-Roohan-Khan-28/RV32I-AXI4-Lite-SoC.git C:\short\soc-new
git -C C:\short\soc-new config core.autocrlf false
git -C C:\short\soc-new checkout --detach 6af4cd8e5b49d592610281d6bd953114128b6762
$env:PATH = 'C:\intelFPGA\20.1\modelsim_ase\win32aloem;' + $env:PATH
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\short\soc-new\scripts\run_regression.ps1 -OutputDir C:\short\soc-new-output
if ($LASTEXITCODE -ne 0) { throw 'RV32I SoC required suite failed or blocked' }
```
