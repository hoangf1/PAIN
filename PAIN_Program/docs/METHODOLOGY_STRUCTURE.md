# Structure of a validation chunk in METHODOLOGY.md

This file fixes the layout that every pipeline chunk in [`METHODOLOGY.md`](METHODOLOGY.md) follows, so a reader can go from
"what does this part of the program do" to "what was it checked against" to "which tests, with which pass criteria" without
searching. It is a layout rule only. It changes no criterion, tolerance, result or grade; those stay in
[`VALIDATION_GUIDELINE.md`](VALIDATION_GUIDELINE.md) (criteria, case records) and in the claim register of `METHODOLOGY.md` §9.

## Why chunks

The pipeline is long and no single published source runs through all of it. Each source validates one piece. A *validation
chunk* is a group of blocks on the validation map (`VALIDATION_GUIDELINE.md` §2.13, group ids such as `G_AIR`) that is
described, and claimed, as one unit. The chunk page says what the chunk is, what goes in and out of each block, which sources
check it, and which registered cases do the checking.

## The seven parts, in this order

| # | Part | Content | Rule |
|---|------|---------|------|
| 1 | **Chunk name** | The map group title, e.g. *Airfoil BEMT+F1A*. State in one sentence why the chunk is split into several checks (no source covers the whole chain). | Same name as the map group |
| 2 | **High-level function** | One bullet per tool or sub-model: *Tool (method) does X.* | Name the tool and the method; no equations |
| 3 | **Chain** | One line of blocks in order, inputs first: `Input -> Block -> Block -> Output`. | Block names equal the map block titles |
| 4 | **Inputs and outputs per block** | A table with one row per block: *Block / Inputs / Outputs*. | Every output named here is an input of the next row, or a chunk output |
| 5 | **Implementation notes** | Settings that change the result (sign conventions, ordering, defaults, guards) and the current code status. | Dated; only facts that affect a number |
| 6 | **Validation sources** | A table: *Source / What it tests / Scope and limits*. The scope says what the source is used for and why it was chosen (size, regime). | One row per source; the limit is stated, not implied |
| 7 | **Validation cases** | One table per map check block: *Case / What it tests / Why / Pass criterion / Last recorded*. Then the chunk claim and what it does not support. | Criterion copied from the case record; never restated from a result |

## Rules for part 7 (cases)

1. **Group by check block**, not by source: a block such as *F1A amplitude* may mix Report 996 figures and closed-form checks.
   Code checks (closed form, identity, independent implementation) are listed before experiments, so the reader sees what is
   known about the code before what is known about the physics.
2. **Case id as in the registry** (`VALIDATION_GUIDELINE.md` §2.13). Do not rename.
3. **Criterion**: the frozen pass rule and its tolerance, with the label that applies (V-UNIT, V-CODE, V-EXP, calibrated).
   A case with no criterion says "none (informational)" or "none (display)".
4. **Last recorded**: `k/n` or met / not met, with the date and any post-hoc label exactly as in the case record. If a
   number changed after a re-run, give the current one and the date. A value chosen after seeing a result is labelled post-hoc.
5. **What it tests / Why**: one short phrase each. *What* names the quantity compared; *why* names the failure it would catch or
   the question it answers.
6. The chunk **claim** and the list of what the checks **do not support** close the chunk. The claim uses the grades of
   `METHODOLOGY.md` ("Grades used for every claim").

## Skeleton

```markdown
### N.M <Chunk name>

**Validation chunk:** <name> (map group `G_...`). <why it is split into several checks>

**What it does.**
- <Tool> (<method>) <does X>.

**Chain.** `<input> -> <block> -> <block> -> <output>`

| Block | Inputs | Outputs |
|-------|--------|---------|

**Implementation notes.** ...

**Validation sources.**

| Source | What it tests | Scope and limits |
|--------|---------------|------------------|

**Validation cases.**

*<Check block>* - <one line on what the block checks>

| Case | What it tests | Why | Pass criterion | Last recorded |
|------|---------------|-----|----------------|---------------|

**Claim today: <grade>.** **What these checks do not support.** ...
```

## Status of the chunks

| Chunk | `METHODOLOGY.md` | Structure applied |
|-------|------------------|-------------------|
| 1a Free field, NASA measured data, and the 160-point grid | §2.2 | **done** |
| 1b Airfoil BEMT+F1A | §2.3 | **done** |
| 2 Blocking | §3 | **done** |
| 3 Cabin acoustic modes (CYL2D) | §4 | **done** |
| 4 Structural modes (MRP) | §5 | **done** |
| 5 Trim and loss, PAIN main, end-to-end comparisons | §6.1–6.3 | **done** |
| 6 Metrics | §7 | **done** |

When a chunk is restructured, change its row to **done** in the same edit.
