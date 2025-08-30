#include <bench/gtsst-bench.cuh>
#include <compressors/compactionv5t/compaction-compressor.cuh>
#include <iostream>
#include <vector>

int main(int argc, char* argv[]) {
    const bool use_override = argc >= 2;

    // Set directories to use
    std::vector<std::string> directories = {
        "../../thesis-testing/lineitem-1gb/",
        // "../../thesis-testing/customer-1gb/",
        // "../../thesis-testing/gdelt-locations-inflated-1gb/",
        // "../../thesis-testing/dbtext-inflated-1gb/",
        // "../../thesis-testing/lineitem-2gb/",
        // "../../thesis-testing/customer-2gb/",
        // "../../thesis-testing/gdelt-locations-inflated-2gb/",
        // "../../thesis-testing/dbtext-inflated-2gb/",
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
