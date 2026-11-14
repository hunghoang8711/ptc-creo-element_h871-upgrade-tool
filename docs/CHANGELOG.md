

## 2026-11-14 – Confirm separate Density Instance and Contents inquiries

- User ran both direct tests on the known Part in the native Creo Elements/Direct model.
- `:instance` returned `1000.0`; `:contents` returned `304000.0`.
- Part Properties displays the corresponding values as Instance = `1` and Base = `304`.
- Confirmed the two optional kind arguments work in this Modeling 18.1 environment and return distinct fields.
- Recorded the observed 1000:1 scale relationship; its unit semantics still need confirmation before implementing normalization.
- Clarified native model scope: test and develop against `.pkg` / `.bdl`, not STEP-imported geometry.
