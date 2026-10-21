# RAP Business Logic Development — Priority and Status Dropdowns

## Overview
This change adds fixed-value OData V4 value helps for existing `Priority` and `Status` fields in the draft-enabled RAP Service Request Manager. Storage codes are unchanged.

| Priority | Description | Status | Description |
|---|---|---|---|
| H | High | O | Open |
| M | Medium | I | In Progress |
| L | Low | C | Closed |

## Deployment order
1. Review feature branch and resolve any pending local ADT edits **before pulling**.
2. Import via abapGit to package `ZMPA_STARTER_01`, preserving existing application objects. Check activation errors.
3. Activate tables `ZMPA_PRIORITY` and `ZMPA_STATUS` first.
4. Activate class `ZCL_MPA_SEED_VALUES` and run as ABAP Application (Console) **once** to populate the six fixed values. Re-running updates the same keys; it does not delete other records.
5. Activate CDS value helps `ZI_MPA_PRIORITY_VH` and `ZI_MPA_STATUS_VH`.
6. Activate updated projection `ZZMPC_SERVICEREQUEST01`. Check dependency activation and republish/refresh published OData V4 UI service `ZZMPUI_SERVICEREQUEST_O401` as needed.
7. Refresh Fiori Elements preview (and metadata/cache when needed). Test Priority and Status dropdown behavior in Create and Edit.

## Expected behavior and caveats
- `@Consumption.valueHelpDefinition` connects value-help CDS entities. `@ObjectModel.resultSet.sizeCategory: #XS` marks a small/fixed value set; the Fiori client determines actual control rendering and can show a value help dialog instead of a select dropdown depending on UI metadata/version.
- Validation remains server-side: H/M/L for Priority, O/I/C for Status; default M/O logic is unchanged.
- The current Status field remains editable for this milestone; subsequent lifecycle actions may make it readonly.
- New tables and generated XML were composed for abapGit; **SAP activation and runtime validation are pending**. Do not treat this code as verified until activation/preview tests pass.
- Existing service request table, behavior definitions/implementations, draft table, binding, and tests are unchanged except for the projection annotations.

## Acceptance evidence
- Both value-help CDS views return 3 rows and text labels.
- On create/edit, user can select priority and status from fixed values.
- Save with M/O defaults still works.
- Existing invalid priority/status validation still rejects unsupported values through a backend request.
- Draft activation and CRUD behavior continue to work.
