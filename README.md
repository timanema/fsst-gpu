> [!WARNING] 
> Note that this repository currently is a stub for https://github.com/timanema/msc-thesis-public.
> Transferring the work done for the thesis is still a WIP, but will be finished **before** ADMS 2025

# High Throughput GPU-Accelerated FSST String Compression
This repository contains the compressor used for benchmarks for the ADMS 2025 paper titled 'High Throughput GPU-Accelerated FSST String Compression'.
This GPU-accelerated compressor is based on the FSST (\textit{Fast Static Symbol Table}) compressor, providing a throughput of 74 GB/s on an RTX4090 while maintaining its compression ratio. 
The resulting compression pipeline is 3.86x faster than nvCOMP's LZ4 compressor, while providing similar compression ratios (0.84x).
We achieved this by creating a memory-efficient encoding table, an encoding kernel that uses a voting mechanism to maximize memory bandwidth, and an efficient gathering pipeline using stream compaction.

* Developer: Tim Anema
* Contributors: Joost Hoozemans, Zaid Al-Ars, H. Peter Hofstee

_This repository is based on the work in https://github.com/timanema/msc-thesis-public._
