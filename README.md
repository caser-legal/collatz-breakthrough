# Convergence verification of the Collatz problem

[![Build Status](https://app.travis-ci.com/YOUR_GITHUB_USER/collatz.svg?branch=master)](https://app.travis-ci.com/YOUR_GITHUB_USER/collatz)

## Run on every available NVIDIA GPU and CPU

This fork adds a one-command, continuous launcher around the
published 128-bit CPU/OpenCL verifier. It automatically detects all NVIDIA GPUs
and logical CPUs, reserves one host thread per GPU, and uses every remaining CPU
thread. Work is assigned and checkpointed by the project's central server, so a
restart resumes from globally incomplete work rather than repeating a local
fixed range. There is no configured work-unit count or runtime cap.

On Ubuntu with the NVIDIA driver already installed:

```bash
git clone https://github.com/caser-legal/collatz-breakthrough.git
cd collatz-breakthrough
sudo ./scripts/install_ubuntu.sh
./scripts/build_all.sh
./scripts/run_all_available.sh
./scripts/status.sh --watch
```

Status refreshes every two seconds. Stop the local clients cleanly with:

```bash
./scripts/stop_all.sh
```

The launcher defaults to `collatz.example.edu`, requests the lowest globally
incomplete assignments, submits checksums and overflow information, and falls
back from a GPU work unit to the GMP-enabled CPU worker if necessary. Override
the assignment server only by explicitly setting `SERVER_NAME`.

This is exhaustive finite verification, not a proof of the full Collatz
conjecture. The worker's exact numeric domain is 128-bit; a decimal endpoint
larger than `2^128-1` cannot be represented by this verifier. A machine cannot
exhaustively traverse an unbounded set or establish a non-cyclic divergent orbit
merely by waiting. The continuous launcher therefore has no operational task
count cap while preserving the verifier's documented arithmetic boundary.

## Details

This repository contains computer programs implementing a completely new approach to calculating iterates of <a href="https://en.wikipedia.org/wiki/Collatz_conjecture">the Collatz function</a>.
The trick is that, when calculating the function iterates, the programs switch between two domains in such a way that they can always use the count trailing zeros (ctz) operation and a small lookup table with pre-computed powers of three.
This approach differs significantly from the commonly used approach utilizing a space-time tradeoff using huge lookup tables.
Mathematical details on this approach are given [here](doc/ALGORITHM.md).
The programs can check 128-bit numbers.

## Run on your own cluster

Submit scripts under `scripts/` are templates. Before you queue them, replace `YOUR_HPC_PROJECT`, `YOUR_GITHUB_USER`, `user@example.com`, and `${USER}` home paths with your own account. Do not publish cluster usernames, mail addresses, or project ids. The default assignment server is `collatz.example.edu`; set `SERVER_NAME` to your server.

## Contact

Open a GitHub issue on this repository. Do not put a personal email address in the tree.

## License
This project is licensed under the terms of the [MIT license](LICENSE.md).

## References

- Barina, D. Convergence verification of the Collatz problem. _J Supercomput_ 77, 2681–2688 (2021). https://doi.org/10.1007/s11227-020-03368-x
- Barina, D. Improved verification limit for the convergence of the Collatz conjecture. _J Supercomput_ 81, 810 (2025). https://doi.org/10.1007/s11227-025-07337-0
