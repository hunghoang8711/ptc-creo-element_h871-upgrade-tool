

## KI-006 – Density API values differ from Part Properties display scale

- **Status:** API calls confirmed; value normalization semantics still under investigation.
- **Native test object:** Part `010-plate_2.1.1.2.1` in the user's native Creo Elements/Direct model (`.pkg` / `.bdl`), not STEP-imported geometry.
- **Part predicate:** `(sd-inq-part-p part)` returns `T`.
- **Instance inquiry:** `(sd-inq-part-density part :instance)` returns `1000.0` (`LONG-FLOAT`).
- **Contents/Base inquiry:** `(sd-inq-part-density part :contents)` returns `304000.0` (`LONG-FLOAT`).
- **Part Properties display:** Instance = `1`, Base = `304`.
- **Observed relationship:** both returned API values are 1000 times the corresponding UI values on this Part.
- **Interpretation:** optional kind arguments are supported in this Modeling 18.1 installation, and the two calls expose the intended separate fields. The unit/conversion reason for the factor is not yet proven.
- **Risk:** comparing raw API values directly against user-entered UI values (1 and 304) will not match. Do not apply an unverified global conversion factor until another known Part or authoritative 18.1 documentation confirms it.
- **Native data constraint:** all development and tests must use native Creo Elements/Direct `.pkg` / `.bdl` model content. Do not assume a STEP import data path.
- **Next action:** verify the scale on another known Part, then normalize values in a dedicated reusable function before exact-pair comparison.
- **Production filter status:** a successful isolated inquiry is not proof that the complete Assembly scan or result UI works. Keep full runtime status separate.
