# Modernization ABAP Accelerator — abapGit starter

**Preliminary evaluation code — not SAP-activated or SAP-tested.**

This repository is intentionally limited to fictional, nonconfidential ABAP Cloud starter classes for an SAP BTP ABAP Environment trial. It contains no complete RAP business object or client/proprietary source.

## Import contents

- `ZCL_MPA_HELLO` — ADT console smoke-test class.
- `ZCL_MPA_RULES` — independent educational business rules.
- 13 ABAP Unit test methods in `zcl_mpa_rules.clas.testclasses.abap`.
- `.abapgit.xml` and ABAP class metadata for abapGit.

## Eclipse ADT import

1. Open the existing signed-in ABAP Cloud Project.
2. Open **Window → Show View → Other → abapGit Repositories**.
3. Press green **+** to clone.
4. Use `https://github.com/sabirshah75/modernization-abap-accelerator.git`, branch `main`.
5. Select a **new, writable ABAP package** that you are permitted to modify. Do not reuse the other repositories' packages in the shared trial.
6. Inspect proposed changes and any warnings before confirming.
7. Activate classes as needed, then run ABAP Unit on `ZCL_MPA_RULES` and run `ZCL_MPA_HELLO` as an ABAP console application.

Import and activation depend on the SAP environment, permissions, and abapGit compatibility; results are not yet verified.

## Scope boundaries

- This is *not* the complete RAP Service Request Manager.
- These 13 ABAP Unit tests cover only the standalone rule model, **not** the 45 planned SAP acceptance tests.
- No evidence of successful activation or runtime is claimed.
- Do not upload secrets or client data, and avoid storing commercial source in a publicly accessible shared trial system.
