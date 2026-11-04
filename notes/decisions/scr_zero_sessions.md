# Never-caught sessions in individual-unit tables (#30)

*Ruled 2026-11-03 in standard v1.1-draft, E4 consequence 4.*

**Question.** Multi-session SCR and CR tables carry a row for every individual at every
surveyed trap-occasion while it is at risk, including whole primary periods in which it
was never caught (the Lazenby tables: 454 of 594 and 696 of 924 individual x session
blocks are all zero). A closed-population model fitted to one session (`secr`, a
likelihood conditioned on detection) cannot use an all-zero history.

**Options considered.** (1) Drop never-caught sessions from the core table; (2) keep
them and add first/last-period flags; (3) keep them and let the converters filter.

**Ruling.** Keep the rows (the survey happened and the individual was at risk, so E4's
"row iff surveyed" holds and open-population models use them), and filter in the
converter: `eco_to_ch(drop_zero_sessions = TRUE)` drops all-zero unit x period blocks
by default, with a message. No flag columns: first and last capture are computable
from the rows, and a derived column would be a second copy of the data.

**What E4.4 now says about the span at risk.** An animal caught in the wild was at risk
from the study's first period (leading zeros kept, as MARK histories and Jolly-Seber /
Pradel need); one marked at birth or hatching has no rows before its marking period;
removal ends the span (`obs_removed = 1`); a lost mark ends it after the last period the
mark was known present. An individual never detected is not a unit.

**Test against Ben's rule** (clear, no judgement, lossy only when protection requires):
all rows that the survey record supports are kept; the only judgement, "marked at
birth", comes from the source's protocol.

**Tables affected:** every `unitKind = individual` table; the v1.1 rebuild pads or
trims each to the at-risk span (`BATCH_LOG.md`, standard v1.1 rebuild).
