# Source log

Every gas-optimization source mined for the catalog, when it was pulled, and whether it produced at least one original card. Sources that added no card stay recorded here so a dry source is never blindly re-mined; they are deliberately absent from the acknowledgements in the README and the coverage map in `SOURCES.md`, which credit only card-contributing sources.

Listed in the order they were mined.

| Source | Pulled | New cards | Outcome |
|--------|--------|-----------|---------|
| [RareSkills Book of Gas Optimization](https://www.rareskills.io/post/gas-optimization) | 2026-07-13 | 83 | Seed source. 84 items, 83 carded, 1 omitted (ARC-10 retired: library choice is a dependency decision, not a code transform) |
| [WTF-gas-optimization (WTF Academy)](https://github.com/WTFAcademy/WTF-gas-optimization) | 2026-07-14 | 4 | ST-15, ST-16, DEP-10, EXE-23. 24 items; 4 measurements added to existing cards, rest covered |
| [kadenzipfel/gas-optimizations](https://github.com/kadenzipfel/gas-optimizations) | 2026-07-14 | 7 | EXE-24, EXE-25, EXE-26, EXE-27, EXE-28, DEP-11, DEP-12. 21 items; 2 flagged against forbidden cards |
| [0xKitsune/EVM-Gas-Optimizations](https://github.com/0xKitsune/EVM-Gas-Optimizations) | 2026-07-14 | 0 | 25 distinct techniques; 20 already covered, 1 runtime measurement into DEP-12, 4 marginal or optimizer-handled |
| [OpenZeppelin Forum: A Collection of Gas Optimisation Tricks](https://forum.openzeppelin.com/t/a-collection-of-gas-optimisation-tricks/19966) | 2026-07-14 | 1 | CD-05. 20 posts; the rest are canonical tricks already covered |
| [harendra-shakya/solidity-gas-optimization](https://github.com/harendra-shakya/solidity-gas-optimization) | 2026-07-14 | 0 | Derivative pre-Berlin prose guide; every trick already carded (Yul section is verbatim transmissions11) |
| [0xisk/awesome-solidity-gas-optimization](https://github.com/0xisk/awesome-solidity-gas-optimization) | 2026-07-14 | 0 | Link directory. High-yield links (0xmacro cheat sheet, mudit.blog, Polymath/Mudit bytecode article) all map to existing cards; research papers are academic tooling/superoptimization, not source-level techniques |
| [12 Expert Solidity Gas Optimization Techniques (Hela Labs)](https://helalabs.com/blog/12-expert-solidity-gas-optimization-techniques/) | 2026-07-14 | 0 | Derivative listicle; all 12 map to existing cards (fixed-size types ST-05/EXE-10, cache storage ST-02, calldata CD-03, events ST-16, struct packing ST-03/ST-04, short-circuit EXE-11, bitwise EXE-15). Repeats the debunked "external cheaper than public" claim, carded as FBD-08 |

Per-item coverage for the card-contributing sources is mapped in [`SOURCES.md`](SOURCES.md).
