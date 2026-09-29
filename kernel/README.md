# Kernel work

Kernel work is intentionally staged after the stock-kernel EvoX A16 Treble bring-up.

1. Pin Lenovo's `official-3.18.120` source and preserve the unmodified source revision.
2. Reproduce a clean kernel build with the closest matching config and Android GCC 4.9 cross toolchain; the Linux host's GCC 13 and Clang 18 are not assumed compatible.
3. Repack and validate a clean boot image, then verify the real tablet before adding Root.
4. Only after clean-kernel acceptance, integrate current ReSukiSU Manual Hook for Linux 3.18 and keep that diff separate.

Preserve stock boot, clean self-build boot, and ReSukiSU boot as separate rollback artifacts outside Git. Record toolchain hash, config hash, source commit, output hash, and packaging method for each.
