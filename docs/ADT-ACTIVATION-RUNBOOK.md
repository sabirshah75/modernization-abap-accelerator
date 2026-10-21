# ADT Activation Runbook — Safe RAP Integration (October 21, 2026)

This runbook is for `TRL_EN`, SAP BTP ABAP Environment shared trial; package `ZMPA_STARTER_01`, root entity `ZZMPR_SERVICEREQUEST01`, behavior pool `ZZMPBP_R_SERVICEREQUEST01`, Fiori OData V4 service `ZZMPUI_SERVICEREQUEST_O401`.

**Do not import the whole `integration/adt/` folder into abapGit.** Its BDEF and local handler are reconstructed integration candidates **outside** abapGit's configured `/src/` root. Those files are not generated-class exports and have not passed SAP syntax check. The working generated RAP class may already include authorization and other methods; preserve them.

## A. Pre-change safety checkpoint

1. Verify the OData V4 service preview opens and the baseline working test is recorded (previously manual CRUD succeeded).
2. Open the actual root behavior definition and its behavior pool Local Types; save both actual sources (along with projection behavior) to a secure backup or Git commit before editing.
3. In abapGit, inspect proposed changes before pulling the review branch. **Do not accept deletion or replacement of RAP objects not present in the starter repo**, and do not stage unrelated shared-trial data.
4. Don't merge draft PR #2 to main yet.
5. The review branch holds updated `ZCL_MPA_RULES` and six new tests. Sync those **two starter files first**, inspecting their diff. They are independent of RAP generation.
6. Keep all tests fictional. Avoid using a shared tenant's other users' objects or transactions.

## B. First integration: rule class and tests

1. In GitHub open `src/zcl_mpa_rules.clas.abap` on branch `feature/rap-eml-documented-20261021`.
2. Compare with the active `ZCL_MPA_RULES` in Eclipse ADT. Integrate the added `valid_status`, `default_priority`, and `default_status` methods, retaining the earlier four rules.
3. From `src/zcl_mpa_rules.clas.testclasses.abap`, add the six new test cases for O/I/C/unknown status and Medium/Open defaults. Preserve existing test cases.
4. Activate the class (Ctrl+F3), run **ABAP Unit Test**. Expected after activation: **19 separate tests green**. This is only an expectation; report actual evidence. If the 19 tests fail, stop here and correct the rule code.
5. On success: capture ABAP Unit screenshot and date for the product guide. These standalone tests do not test the Fiori/RAP integration.

## C. Second integration: one determination, not the whole handler

1. In root BDEF `ZZMPR_SERVICEREQUEST01`, after `create; update; delete;`, add **only** this declaration if it is not already present:

```abap
  determination SetDefaults on modify { create; }
```

2. Save and **activate** the BDEF (Ctrl+F3).
3. Put cursor on `SetDefaults`, press **Ctrl+1** and select ADT's option to add the missing method to the behavior pool Local Types. This creates a release-correct method signature and avoids a duplicate local class.
4. Open behavior pool `ZZMPBP_R_SERVICEREQUEST01` → **Local Types**. Find the generated `METHOD SetDefaults.` implementation.
5. Open GitHub `integration/adt/zzmpbp_r_servicerequest01.locals_imp.abap`; transfer **only the body of `METHOD SetDefaults`** into that generated method. Do not paste the entire class definition or the permissive example `get_global_authorizations`.
6. Review and activate class; if there are syntax errors, use the ADT compiler's exact line/error rather than blind edits. The proposed code uses RAP `READ/MODIFY ENTITIES ... IN LOCAL MODE`, `%tky` and `%control`.
7. Open Fiori preview and create a fictional Service Request with Title set, leaving Priority and Status empty. Complete the draft activation flow. Check that it displays **M** and **O**.
8. Repeat with explicitly entered Priority `H` and confirm server determination doesn't override it. Fiori may require metadata refresh to show editable/default behavior.
9. Run the prior CRUD regression test with a new fictional record (then delete only that test record).

**RAP concept:** a determination runs automatically after its configured triggers; unlike direct SQL, EML accesses the RAP transaction buffer. See SAP RAP determination tutorial: https://developers.sap.com/tutorials/abap-environment-rap100-determination .

## D. Third integration: validation + draft prepare

1. In root BDEF add, without duplicating existing declarations:

```abap
  validation ValidateRequest on save { create; update; }
```

2. In the existing draft `Prepare` action, change the empty declaration to:

```abap
  draft determine action Prepare
  {
    validation ValidateRequest;
  }
```

3. Activate the BDEF and use **Ctrl+1** on `ValidateRequest` to generate the callback signature in Local Types.
4. Copy only the `METHOD ValidateRequest ... ENDMETHOD` body from the integration candidate; preserve the actual generated authorization handler. Activate and adjust field types and message syntax to the tenant release.
5. Test: Title empty; invalid Priority `X`; invalid Status `X` (via safe EML/integration tests, since value-help/read-only UI may prevent invalid values). The **active** instance must not be saved/activated; any incomplete drafts should show messages during Prepare/Activate.
6. Confirm reported messages highlight the expected field and the UI shows a useful message; don't conflate draft autosave with active activation.

**RAP concept:** `validation ... on save` is handled in the local behavior pool; draft `Prepare` is relevant to activation. SAP Help: https://help.sap.com/docs/abap-cloud/abap-rap/982a40c45eba4443b2b6a25f824023fa.html .

## E. Fourth integration: Start and Close actions

1. Add root BDEF actions `StartRequest` and `CloseRequest` with `result [1] $self`; confirm release syntax and your intended authorization policy in ADT.
2. Use **Ctrl+1** to generate action method declarations and bodies in the **existing** local handler; insert respective method bodies from candidate only.
3. Ensure generic Status update cannot bypass server transitions. The candidate marks Status readonly; test the resulting Create UI and default determination before accepting it.
4. In the existing projection behavior definition (actual object from ADT), expose `use action StartRequest;` and `use action CloseRequest;`.
5. Add correct `@UI.lineItem` / `@UI.identification` action annotations to the **actual existing metadata extension**, not a guessed file. Refresh service/Fiori metadata as needed.
6. Test Open → In Progress, In Progress → Closed; reject Open → Closed and Closed → Start; check RAP messages, action result and Fiori refresh.
7. Global authorization in the integration candidate is **allow-all for a fictional test tenant**. **Do not replace a real existing authorization method with it.** Implement approved roles/permissions for any real scenario.

## F. Report back after each phase

Capture: BDEF activation message; Local Types syntax check; ABAP Unit executed test count; screenshot of Fiori state and error messages. Store verified source and test evidence in the repository only after review for secrets/shared-trial data.

### Important terminology

- **Global behavior pool class** `ZZMPBP_R_SERVICEREQUEST01` can be an empty, abstract shell.
- **Local Types** (handler) implement determinations, validations and actions.
- **RAP-managed CRUD** can function without custom global methods.
- **IN LOCAL MODE** in behavior handlers bypasses selected checks; not an external consumer authorization shortcut.
- **COMMIT ENTITIES** is consumer-side; never put a commit in RAP handler methods.
- **ABAP Unit 19 tests** are standalone model tests, **not** RAP integration tests.

**Release/activation warning:** Proposed files in `integration/adt` are illustrative until reconciled, compiled and proven in the real ABAP environment. The saved working generated objects remain the source of truth.
