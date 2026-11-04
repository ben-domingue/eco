# Species lists that differ between surveys (#31)

*Ruled 2026-11-03 in standard v1.1-draft, E4 consequence 2, E6, ruling #31.*

**Question.** E4.2 (every taxon at every survey) forced deposits whose surveys looked for
different taxa into sibling tables: RMAP by national forest (#31's original case), Shark
Bay by which taxa were countable on each run (batch 20), and it shaped how national
species pools were cut (NEON carabids, batch 14).

**Options considered.** (1) Keep splitting; (2) a per-survey list of taxa surveyed for, in
a side table; (3) a hybrid by overlap of the pools.

**Ruling.** Option 2. One deposit gives one table per survey protocol x response type
(x taxon for individual units, ruling #20). Where the source says the taxa surveyed for
differ between surveys, `<table>__survey_taxa.csv` lists them: `taxon` plus any of
`unit`, `trap`, `period`, `occasion`, at the coarsest level that is true (by unit for
regional pools, by period-occasion for run-level flags). The validator checks every
survey's taxon rows against it; without the side table every taxon is surveyed for
everywhere. Option 3 was rejected because "heavy overlap" is a judgement.

**What still splits.** Different methods (pitfall vs emergence tent, net vs dipnet,
eDNA vs visual) are different protocols; different response types; individual-unit
deposits with several taxa (ruling #20); separate deposits.

**Test against Ben's rule.** The list comes from the source's statement, no threshold is
involved, and nothing is dropped: the merged table holds every row the siblings held.

**Consequences.** `eco_to_array()` and `eco_to_irw()` read the same long table; a user
who builds a species x survey array without `__survey_taxa` sees NA, not zero, for taxa
not surveyed for, which is correct. Sibling tables merged in the v1.1 rebuild are
withdrawn under their old names (`releases/withdrawals.csv`), replaced by the merged
table.
