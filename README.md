# High Throughput GPU-Accelerated FSST String Compression
This repository contains the compressor used for benchmarks for the ADMS 2025 paper titled 'High Throughput GPU-Accelerated FSST String Compression'.
This GPU-accelerated compressor is based on the FSST (_Fast Static Symbol Table_) compressor, providing a throughput of 74 GB/s on an RTX4090 while maintaining its compression ratio. 
The resulting compression pipeline is 3.86x faster than nvCOMP's LZ4 compressor, while providing similar compression ratios (0.84x).
We achieved this by creating a memory-efficient encoding table, an encoding kernel that uses a voting mechanism to maximize memory bandwidth, and an efficient gathering pipeline using stream compaction.

* Developer: Tim Anema
* Contributors: Tim Anema, Joost Hoozemans, Zaid Al-Ars, H. Peter Hofstee

_This repository is based on the work in https://github.com/timanema/msc-thesis-public._

## Instructions
The repository is organized as follows:
```bash
.
├── include               # Header files
│   ├── bench             # Benchmark files
│   ├── compressors       # Actual compressors
│   ├── fsst              # Modified version of FSST
│   └── gtsst             # Encoding tables, symbols, shared code
└── src                   # Source files
    ├── bench
    ├── compressors
    └── fsst

```
Every (interesting) compression pipeline will have tree header files: `*-compressor.cuh`, `*-defines.cuh`, and `*-encode.cuh`.
These contain the public methods, parameter definitions, and private definitions, respectively.
All compressors implements this template:
```c++
struct CompressionManager
{
    virtual ~CompressionManager() = default;
    virtual CompressionConfiguration configure_compression(size_t buf_size) = 0;
    virtual GTSSTStatus compress(const uint8_t* src, uint8_t* dst, const uint8_t* sample_src, uint8_t* tmp,
                                 CompressionConfiguration& config, size_t* out_size,
                                 CompressionStatistics& stats) = 0;

    virtual DecompressionConfiguration configure_decompression(size_t buf_size) = 0;

    virtual DecompressionConfiguration configure_decompression_from_compress(
        const size_t buf_size, CompressionConfiguration& config)
    {
        return DecompressionConfiguration{
            .input_buffer_size = buf_size,
            .decompression_buffer_size = config.input_buffer_size,
        };
    }

    virtual GTSSTStatus decompress(const uint8_t* src, uint8_t* dst, DecompressionConfiguration& config,
                                   size_t* out_size) = 0;

private:
    virtual GTSSTStatus validate_compression_buffers(const uint8_t* src, uint8_t* dst, uint8_t* tmp,
                                                     CompressionConfiguration& config) = 0;
};
```

### Building the project
To build the project, you need to at least have the [CUDA development library](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/) and CMake 3.25.2 installed, but a more complete C++/CUDA environment is recommended.
You can then build the project with the following commands:
```bash
cmake . -B build -DCMAKE_BUILD_TYPE=Release
cd build/
make
```

### Running the project
Once you have build the project, the executable can simply be run with `./gtsst`.

However, this will likely result in the following error:
`Error: filesystem error: directory iterator cannot open directory: No such file or directory [../../thesis-testing/lineitem-1gb/]`
This is because, by default, the project uses this directory to load data.
The directories to use can be given as a program argument:
`./gtsst ../../thesis-testing/lineitem-1gb/ ../../thesis-testing/lineitem-0.5gb/`

By default, the final pipeline is used to perform 100 compression iterations on all files in the given directories and
a single validation decompression. This can be changed by modifying the main.cu file:
```c++
int main(int argc, char* argv[]) {
    const bool use_override = argc >= 2;

    // Set directories to use
    std::vector<std::string> directories = {
         "../../thesis-testing/lineitem-1gb/",
    };

    if (use_override) {
        directories.clear();

        for (int i = 1; i < argc; i++) {
            directories.emplace_back(argv[i]);
        }
    }

    // Active compressor (see thesis repo for others)
    gtsst::compressors::CompactionV5TCompressor compressor;

    // Set bench settings
    constexpr int compression_iterations = 100;
    constexpr int decompression_iterations = 1;
    constexpr bool strict_checking =
        true; // Exit program when a single decompression mismatch occurs, otherwise only report it

    // Run benchmark (use_dir=true if all files in the directory must be used, otherwise uses first file only)
    const bool match = gtsst::bench::full_cycle_directory(directories, false, compression_iterations,
                                                          decompression_iterations, compressor, false, strict_checking);
    if (!match) {
        std::cerr << "Cycle data mismatch." << std::endl;
        return 1;
    }

    return 0;
}
```
The default directories can be modified, the compressor can be chosen, and the number of iterations can be selected.