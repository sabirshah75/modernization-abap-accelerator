# EML in RAP — hands-on guide, explained statement by statement

> **Learning status:** These are educational examples to adapt in ADT, not executed EML integration tests. Verify your entity, field, action, authorization, draft and release-specific EML syntax against the actual generated service BO. Never run destructive tests against customer data.

## 1. Why EML?

**Entity Manipulation Language** is the ABAP syntax for accessing RAP business objects, using their behavior contract rather than directly writing to their database tables. A consumer says **what** it wants to read/change, while RAP handles locking, checks, determinations, authorization (depending on call context), draft behavior and transactional orchestration.

- `READ ENTITIES`: read entity instances in the RAP transactional context.
- `MODIFY ENTITIES`: create, update, delete or execute actions in the RAP transactional buffer.
- `IN LOCAL MODE`: special *inside behavior implementation* access, where certain behavior checks are bypassed; do **not** use it as a generic shortcut in external consumers.
- `COMMIT ENTITIES`: finalize a RAP LUW from an allowed consumer context. **Never issue it inside a RAP behavior handler.**
- `FAILED`: structured instance failures.
- `REPORTED`: information/warnings/errors, often for display.
- `MAPPED`: maps temporary content IDs to generated persistent keys, especially for creates.
- `%cid`: caller-assigned transient correlation ID for create requests.
- `%tky`: transactional identity of an instance, including its draft context.
- `%control`: expresses which fields are intentionally modified (important for update/defaulting).

## 2. READ — start here (outside handler; existing active UUID only)

```abap
" [R01] Use the interface/root behavior entity, not the database table.
READ ENTITIES OF ZZMPR_SERVICEREQUEST01
  " [R02] Choose the behavior alias defined after 'alias' in the root BDEF.
  ENTITY ServiceRequest
  " [R03] ALL FIELDS requests every exposed field; choose explicit FIELDS for optimized production code.
  ALL FIELDS
  " [R04] Supply the existing key. This value is an example only.
  WITH VALUE #( ( UUID = lv_existing_uuid ) )
  " [R05] RAP entity records go into an explicitly named ABAP table.
  RESULT DATA(lt_requests)
  " [R06] Any unsuccessful instance keys go here.
  FAILED DATA(ls_failed)
  " [R07] Business/technical messages go here.
  REPORTED DATA(ls_reported).
```

**Why each line exists:** R01 targets RAP behavior, R02 targets the entity alias, R03 selects fields, R04 chooses instances, R05 receives the records, R06 collects failures, R07 receives messages. In strict ABAP contexts, check whether the `WITH VALUE #( ... )` key is compatible with your generated entity (active/draft key and syntax); ADT quick assist can offer typed `WITH` tables. Prefer `ENTITY ... FIELDS ( UUID Title Status )` for smaller reads. Inspect `ls_failed` before trusting `lt_requests`.

## 3. CREATE — CIDs, mapping, and transaction boundary

```abap
" [C01] Start a RAP write in a consumer class, e.g. IF_OO_ADT_CLASSRUN~MAIN.
MODIFY ENTITIES OF ZZMPR_SERVICEREQUEST01
  " [C02] Target the entity with RAP create enabled.
  ENTITY ServiceRequest
  " [C03] CREATE is an operation; data must match the entity field types.
  CREATE FIELDS ( Title Description Priority Status )
  " [C04] %cid identifies this row before managed UUID numbering.
  WITH VALUE #( ( %cid = 'REQ_001'
                  Title = 'Demo printer request'
                  Description = 'Fictional training case'
                  Priority = 'M'
                  Status = 'O' ) )
  " [C05] Correlate generated keys to %cid.
  MAPPED DATA(ls_mapped)
  " [C06] Instance errors from RAP interaction.
  FAILED DATA(ls_failed)
  " [C07] Messages from RAP interaction.
  REPORTED DATA(ls_reported).

" [C08] Check FAILED and REPORTED before committing.
IF ls_failed IS INITIAL.
  " [C09] Outside handler, persist changes through RAP save sequence.
  COMMIT ENTITIES
    " [C10] Failed save (e.g., on-save validation) is separate from interaction failure.
    RESPONSE OF ZZMPR_SERVICEREQUEST01
    FAILED DATA(ls_commit_failed)
    REPORTED DATA(ls_commit_reported).
ENDIF.
```

**Line-by-line:** C01 is a transactional RAP modify; C02 identifies the entity; C03 indicates create and editable fields; C04 sends data and correlates it; C05 retrieves assigned identities; C06/C07 collect interaction failures/messages; C08 prevents committing a request that already failed; C09 triggers the save phase; C10 reports save-time validation and persistence failures. For production code use explicit checks of **both** failure sets and messages and a safe rollback/recovery policy. `COMMIT ENTITIES` syntax and response variants depend on ABAP language release. Draft-enabled BOs may create draft state vs active state depending on `%is_draft` and flow; do not assume the above creates a published active record on every system. To simulate Fiori's draft activation, use the draft actions and transactional keys defined by your BDEF.

## 4. UPDATE — write only what is intended

```abap
" [U01] Target an existing RAP instance by its UUID.
MODIFY ENTITIES OF ZZMPR_SERVICEREQUEST01
  " [U02] Select the entity and update operation.
  ENTITY ServiceRequest
  " [U03] Only the listed field is modified; no unintentional default clearing.
  UPDATE FIELDS ( Description )
  " [U04] Supply the key and replacement value.
  WITH VALUE #( ( UUID = lv_existing_uuid
                  Description = 'Rechecked printer queue' ) )
  " [U05] Always capture RAP failures/messages.
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

**U01–U05:** This updates only `Description`. For a consumer, follow up with an allowed `COMMIT ENTITIES` after checking failure information. For a draft instance, use a draft-aware key/flow and consider `%tky` and `%is_draft`; updating a persisted active entity is not equivalent to editing a Fiori draft. In a behavior handler use `IN LOCAL MODE` with `UPDATE FIELDS` and the read entity's `%tky`, but never `COMMIT ENTITIES` inside the handler.

## 5. DELETE — test data only

```abap
" [D01] Removal is controlled by RAP behavior and authorization.
MODIFY ENTITIES OF ZZMPR_SERVICEREQUEST01
  ENTITY ServiceRequest
  " [D02] Delete only explicitly provided keys.
  DELETE FROM VALUE #( ( UUID = lv_own_test_uuid ) )
  " [D03] Record rejects and business messages.
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

**D01–D03:** Unlike `DELETE FROM database_table`, RAP deletion invokes behavior constraints. Check errors before committing. Never run with shared-production keys. Verify absence via a fresh read after successful commit and draft cleanup where relevant.

## 6. EXECUTE an action — after adding it to the real BDEF

```abap
" [A01] This requires a successfully implemented root action StartRequest.
MODIFY ENTITIES OF ZZMPR_SERVICEREQUEST01
  ENTITY ServiceRequest
  " [A02] Invoke application-specific behavior, not generic UPDATE.
  EXECUTE StartRequest
  " [A03] Choose an existing key.
  FROM VALUE #( ( UUID = lv_existing_uuid ) )
  " [A04] Receive declared action result ($self) if behavior supports it.
  RESULT DATA(lt_action_result)
  " [A05] Invalid transitions should appear as failed and reported.
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

**A01–A05:** Actions let the BO govern transitions `O -> I` and `I -> C`. This example will **not activate** until `StartRequest` is declared, implemented and activated, and its calling contract matches the actual environment. Execute action against the right **active/draft transactional key**. The action's changes must be committed from the consumer where applicable.

## 7. EML inside a RAP handler

Inside a generated handler (`lhc_*`) use the actual method signature from ADT:

```abap
" [H01] Behavior implementation can access its own transactional image.
READ ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
  ENTITY ServiceRequest
  FIELDS ( Title Priority Status )
  WITH CORRESPONDING #( keys )
  RESULT DATA(lt_requests).

" [H02] Only perform internal updates when justified by the determination/action.
" MODIFY ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE ...
" [H03] Never call COMMIT ENTITIES here: RAP owns the save sequence.
```

- **H01** reads draft-aware keys supplied to the handler; `IN LOCAL MODE` is specifically for BO implementation.
- **H02** uses controlled `MODIFY ... IN LOCAL MODE` and `UPDATE FIELDS` to avoid unwanted overwrites and recursive determination loops.
- **H03** leaves the commit to RAP and its request consumer. Be mindful that `IN LOCAL MODE` is not a replacement for security logic.

## 8. Advanced: draft, keys, and transactional identity

1. **Active vs draft.** The root BDEF has `with draft`, draft table `ZZMPSRVCRQST_D01` and draft actions `Edit`, `Activate`, `Discard`, `Resume`, `Prepare`. UI Save often means **draft Activate**; a draft may intentionally be incomplete until activation.
2. **UUID vs %tky.** UUID is the business object's persisted technical key; `%tky` accounts for the relevant transactional/draft instance and should be preferred for actions inside a handler.
3. **%cid.** Temporary correlation for create; use MAPPED to match create responses. Do not treat `%cid` as a saved UUID.
4. **%control.** Required when using the control structure to distinguish a changed field from an empty-but-unchanged field. `UPDATE FIELDS ( Field )` is an alternative update form.
5. **%is_draft.** Use the behavior's draft discriminator where exposed and available. In draft-enabled EML, distinguish editing/activating a draft from direct active modifications.
6. **Authorization.** Root BDEF declares global authorization. Test unauthorized use separately; `IN LOCAL MODE` bypasses parts of normal behavior processing.
7. **Locks/ETags.** `etag master LocalLastChangedAt` and `lock master total etag LastChangedAt` are generated optimistic concurrency controls. Reproduce a stale-update conflict.
8. **SAVE validation.** Checks can fail during `COMMIT ENTITIES` even if `MODIFY ENTITIES` returned no failure. Always inspect response from both phases.
9. **Transactional rollback.** Consult the released syntax for `ROLLBACK ENTITIES` in your ABAP environment when a consumer decides not to save; don't issue an unrelated SQL COMMIT/ROLLBACK to control RAP.
10. **Result data.** `RESULT` receives entity/action output; `FAILED`, `REPORTED`, `MAPPED` have distinct structures and purposes.

## 9. Practice assignments and acceptance criteria

1. **Read** a sample request after Fiori Create; confirm UUID, Title, Priority and Status.
2. **Create** a fictional record using EML, identify returned mapping; verify in UI. Distinguish draft from active.
3. **Update** only Description; ensure Title is unchanged.
4. **Delete** your own sample record and verify fresh read fails/no result.
5. **Validation:** blank Title / Priority X / Status X must be rejected during the correct save phase.
6. **Action:** start an Open request and close an In Progress request; invalid transitions must return useful RAP messages.
7. **Draft:** edit, discard, resume, prepare and activate; verify effective active vs draft states.
8. **Concurrency:** open the same record in two clients and test stale ETag.
9. **Authorization:** verify authenticated-but-not-authorized behavior using a safe restricted test identity.
10. **Unit vs integration:** report independent rule tests separately from handler/EML scenario execution.

See [RAP-IMPLEMENTATION.md](RAP-IMPLEMENTATION.md) and [SOURCE-LINE-BY-LINE.md](SOURCE-LINE-BY-LINE.md). Adapt each snippet in ADT; **no EML snippet here was claimed as executable or tested in the current tenant**.
