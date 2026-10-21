# SAP RAP Service Request Manager — step-by-step implementation (draft-safe)

> **Status:** Integration handbook, **not a claim of activated RAP business logic**. Actual SAP system: ABAP BTP trial, ADT project `TRL_EN`, package `ZMPA_STARTER_01`. The generated RAP objects are **not currently in this Git repository**. Export the complete generated objects with abapGit before attempting automatic integration. Existing application CRUD was manually exercised through Fiori; its generated implementation is not reproducible from this repo alone.

## 0. What has been demonstrated, and what remains

- Repository: `ZCL_MPA_HELLO`, `ZCL_MPA_RULES`, companion unit tests, abapGit metadata. The **original 13** rule ABAP Unit tests passed in SAP (user-verified).
- Runtime: draft-enabled managed RAP Service Request Manager generated in Eclipse ADT; OData V4 UI binding `ZZMPUI_SERVICEREQUEST_O401` published; Fiori Elements Create/Read/Update/Delete manually tested using fictional printer incident.
- The application has an active table `ZZMPSRVCRQUEST01`, draft table `ZZMPSRVCRQST_D01`, root view `ZZMPR_SERVICEREQUEST01`, projection `ZZMPC_SERVICEREQUEST01`, behavior pool `ZZMPBP_R_SERVICEREQUEST01`.
- Priority/status value-help views `ZI_MPA_PRIORITY_VH`, `ZI_MPA_STATUS_VH` activated in ADT; projection failed once in mass activation and later user reported it working, but exact fix was not captured.
- New rule methods and tests on this branch are **unverified** until the user pulls and reruns ABAP Unit. **Do not equate rule tests with RAP integration tests.**

## 1. Architecture

```text
SAP Fiori Elements (List Report / Object Page)
    | OData V4 UI, service binding ZZMPUI_SERVICEREQUEST_O401
    v
Projection: ZZMPC_SERVICEREQUEST01 + projection behavior
    |
    v
Root interface view: ZZMPR_SERVICEREQUEST01
    | BDEF managed + draft
    | behavior pool ZZMPBP_R_SERVICEREQUEST01
    | optional pure rules ZCL_MPA_RULES
    v
Active table ZZMPSRVCRQUEST01 / draft table ZZMPSRVCRQST_D01
```

The EML examples in [EML-GUIDE.md](EML-GUIDE.md) use the **root interface entity** (not the consumption projection) because implementations and tests use the transactional RAP model.

## 2. Preserve the generated behavior definition

Captured from ADT (existing **generated** behavior definition, condensed but names preserved):

```abap
managed implementation in class ZZMPBP_R_SERVICEREQUEST01 unique;
strict ( 2 );
with draft;
extensible;

define behavior for ZZMPR_SERVICEREQUEST01 alias ServiceRequest
  persistent table ZZMPSRVCRQUEST01
  extensible
  draft table ZZMPSRVCRQST_D01
  etag master LocalLastChangedAt
  lock master total etag LastChangedAt
  authorization master ( global )
{
  field ( readonly )
    UUID,
    LocalCreatedBy, LocalCreatedAt,
    LocalLastChangedBy, LocalLastChangedAt, LastChangedAt;

  field ( numbering : managed ) UUID;

  create;
  update;
  delete;

  draft action Activate optimized;
  draft action Discard;
  draft action Edit;
  draft action Resume;
  draft determine action Prepare;

  mapping for ZZMPSRVCRQUEST01 corresponding extensible
  {
    UUID = UUID;
    Title = TITLE;
    Description = DESCRIPTION;
    Priority = PRIORITY;
    Status = STATUS;
    CreatedBy = CREATED_BY;
    CreatedAt = CREATED_AT;
    LocalCreatedBy = LOCAL_CREATED_BY;
    LocalCreatedAt = LOCAL_CREATED_AT;
    LocalLastChangedBy = LOCAL_LAST_CHANGED_BY;
    LocalLastChangedAt = LOCAL_LAST_CHANGED_AT;
    LastChangedAt = LAST_CHANGED_AT;
  }
}
```

**Do not paste this condensed excerpt over the live BDEF.** Maintain the exact generated declarations, additional features, authorization class, side effects and projection behavior already in ADT.

### 2.1 Planned declarations — apply incrementally, after exporting generated code

Place these declarations after `create; update; delete;` in the **interface/root** behavior definition. They are a proposed integration recipe, not yet SAP-activated:

```abap
  determination SetDefaults on modify { create; }
  validation ValidateRequest on save { create; update; }
  action StartRequest result [1] $self;
  action CloseRequest result [1] $self;
```

- `determination`: RAP invokes server-side defaulting logic during modification.
- `SetDefaults`: method name which must match the generated local handler declaration and implementation.
- `on modify`: trigger defaults in the modify interaction phase; `create` restricts trigger to creation.
- `validation`: RAP executes consistency checks during save sequence, so invalid entries can be rejected before persistence.
- `on save`: validation timing. With draft, decide explicitly when validation runs at draft activation.
- `create; update;`: the operations the validation listens to. Add field triggers later only after deciding dependency semantics.
- `action`: a user-invokable RAP operation, separate from generic `update`.
- `StartRequest` / `CloseRequest`: propose business-controlled transitions `O -> I -> C`.
- `result [1] $self`: return one updated instance of this same entity, allowing consumers to refresh its display.

**Draft nuance:** for draft-enabled BOs, consider including `validation ValidateRequest on save ...` in the `draft determine action Prepare { validation ValidateRequest; }` block, **only after checking supported syntax and desired UX on the installed ABAP release**. A draft can intentionally remain incomplete; activation must reject invalid final data.

### 2.2 Generate local methods rather than replacing handler class

1. In ADT, open the existing root BDEF and add **only the determination**; save.
2. Use ADT quick fix / method generation for `SetDefaults`, then review the generated local handler class declaration in `ZZMPBP_R_SERVICEREQUEST01`.
3. Keep framework-generated `lhc_*` and `lsc_*` names, method signatures, `READ ENTITIES` aliases, and SAP-generated authorization methods. **Do not replace the entire behavior pool.**
4. Implement and activate determination; run regression CRUD.
5. Repeat with validation, then actions, one small change per activation.
6. Before each operation, commit exported objects and preserve a recovery checkpoint.

### 2.3 Determination logic — *illustrative algorithm*, not ready-to-paste handler

```text
METHOD SetDefaults.
  READ requested instances IN LOCAL MODE.
  FOR EACH entity:
    IF Priority is initial THEN default to 'M'.
    IF Status is initial THEN default to 'O'.
    UPDATE only fields that are missing;
    preserve explicit user values ('H', 'L', 'I', etc.).
  END FOR.
ENDMETHOD.
```

When implementing, use `READ ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE` and `MODIFY ENTITIES ... IN LOCAL MODE`. Read and update by `%tky` (draft-aware transactional key), and use `%control-Priority`/`%control-Status` to avoid overwriting intentionally supplied fields. Check `FAILED` and `REPORTED` responses; do not perform a nested `COMMIT ENTITIES` in behavior handlers. Read draft indicators and EML operation results carefully.

### 2.4 Validation logic — *illustrative algorithm*, not ready-to-paste handler

```text
METHOD ValidateRequest.
  READ the relevant request instances IN LOCAL MODE.
  FOR EACH entity:
    IF Title is blank or length > 80: flag failure and report Title error.
    IF Priority not in 'L', 'M', 'H': flag failure and report Priority error.
    IF Status not in 'O', 'I', 'C': flag failure and report Status error.
  END FOR.
ENDMETHOD.
```

Use `ZCL_MPA_RULES=>valid_title`, `valid_priority`, `valid_status`. Populate RAP `failed-servicerequest` and `reported-servicerequest` with the **actual generated entity alias and method signature**, messages of severity error, and field markers `%element-Title` / `%element-Priority` / `%element-Status`. Exact message-construction API differs by release and message approach; validate against ADT completion and your environment. One invalid field should produce an explanatory error, not a short dump. Keep validation of business transitions separate from generic domain-value validation.

### 2.5 Action logic — *illustrative algorithm*, not ready-to-paste handler

```text
METHOD StartRequest.
  READ entities keyed by %tky IN LOCAL MODE.
  IF Status <> 'O':
    append failed key + reported reason "Only open requests can start".
  ELSE:
    MODIFY entity Status = 'I' IN LOCAL MODE with Status control set.
  RETURN updated instance in result.
ENDMETHOD.

METHOD CloseRequest.
  READ entities keyed by %tky IN LOCAL MODE.
  IF Status <> 'I':
    append failed key + reported reason "Only in-progress requests can close".
  ELSE:
    MODIFY entity Status = 'C' IN LOCAL MODE with Status control set.
  RETURN updated instance in result.
ENDMETHOD.
```

Use field-control/instance features to disable invalid actions in the UI where appropriate, but **always enforce transitions on the server**. A button hidden in Fiori is not security or data validation. Make sure any consumer cannot directly bypass transitions through generic Update; either restrict direct Status edits or validate old/new status transitions at save.

### 2.6 Projection exposure

For actions to appear in the Fiori projection, check the projection behavior definition (the generated `projection;` BDEF) and explicitly **expose** each action, typically `use action StartRequest;` and `use action CloseRequest;`. Exposing the action in the BDEF is separate from adding Fiori UI annotations/buttons; also review authorization, semantic keys, and side effects.

## 3. Value helps and UI

- Tables `ZMPA_PRIORITY` and `ZMPA_STATUS` reportedly activated with a database-index warning; check actual functional indexing and platform guidelines rather than changing keys solely to hide warnings.
- CDS value helps `ZI_MPA_PRIORITY_VH`, `ZI_MPA_STATUS_VH` activated; associations/annotations need review in the actual projection.
- Keep exactly one source of truth for admin fields. The screenshot showed blank custom `CreatedBy`/`CreatedAt` alongside generated managed `LocalCreatedBy`, `LocalCreatedAt`, and duplicate change dates. Do not drop database columns while existing persisted records/draft support depend on them. First clean UI annotations, then plan a data-safe schema migration.
- Replace `###GENERATED Core Data Service Entity` with meaningful app title and use `Title` as `@UI.headerInfo.title.value` after verifying the actual metadata extension targets.
- Treat code list text (priority High/Medium/Low, status Open/In Progress/Closed) as separate value-help texts, while retaining stable stored codes.

## 4. Acceptance-test checklist

| ID | Scenario | Expected |
|---|---|---|
| U01 | Run previously tested standalone unit cases | Original 13 continue to pass |
| U02 | Run six new unit cases | 19/19 passing **only after SAP executes them** |
| C01 | Create title/priority/status | Active entity created after activation |
| C02 | Read existing entity | Same UUID and values |
| C03 | Update description/title | Same UUID and updated timestamp |
| C04 | Delete **your own fictional test entity** | Entity absent on refreshed query |
| D01 | Create with omitted defaults | Medium / Open generated, explicit values preserved |
| V01 | Blank title | Activation/save rejected with Title error |
| V02 | Invalid Priority = X | Activation/save rejected with Priority error |
| V03 | Invalid Status = X | Activation/save rejected with Status error |
| A01 | Start Open | Status becomes In Progress |
| A02 | Start Closed | Rejected with readable message |
| A03 | Close In Progress | Status becomes Closed |
| A04 | Close Open | Rejected with readable message |
| X01 | Draft edit and discard | Active version remains unchanged |
| X02 | Draft edit and resume | Same draft resumed where supported |
| X03 | Two-user edit and stale ETag | Conflict reported without data loss |
| X04 | Global authorization | Unauthorized operation rejected as designed |
| F01 | Fiori action buttons and messages | Correct availability, labels, messages |
| R01 | Re-run CRUD + OData V4 preview | No regression |

**Status for D/V/A/X/F/R tests: pending execution.** Preserve evidence: timestamps, screenshots, activated object names, ABAP Unit results, HTTP/EML error payloads where safe to share.

## 5. Source control synchronization — important

The currently generated RAP objects may exist only inside the SAP tenant. In ADT abapGit, inspect the diff for your package, confirm no secrets or unrelated code, and stage the relevant generated RAP artifacts into a review branch **after** activating and verifying them. Do **not** pull these sample BDEF fragments over your live SAP objects. Avoid staging binary or generated personalized data. The clean product handoff should reproduce: schema, CDS, behavior, service, metadata, value help, tests, and setup instructions.
