# Generated behavior pool: global class vs local handler classes

**Object:** `ZZMPBP_R_SERVICEREQUEST01`  
**Behavior definition:** `ZZMPR_SERVICEREQUEST01`  
**Source:** copied from the actual ADT **global class** editor by the project author on 2026-10-21.  
**Verification:** Source captured, but no local handler or saver implementations have been exported yet.

## 1. Exact global class as supplied

```abap
class ZZMPBP_R_SERVICEREQUEST01 definition
  public
  abstract
  final
  for behavior of ZZMPR_SERVICEREQUEST01 .

public section.
protected section.
private section.
ENDCLASS.

CLASS ZZMPBP_R_SERVICEREQUEST01 IMPLEMENTATION.
ENDCLASS.
```

**This is normal and is NOT evidence that the behavior implementation is broken or empty.** In managed RAP, the global behavior pool class can be only a shell, while actual determination/validation/action methods are written in *local handler classes* declared in a separate **Local Types** source section. Save-time hooks, if used, can be in a local saver class. Generated behavior and managed CRUD handling are also provided by the RAP framework and do not require a handwritten global class method.

## 2. Why each source line exists

| Exact source construct | Explanation and purpose |
|---|---|
| `class ZZMPBP_R_SERVICEREQUEST01 definition` | Opens the global ABAP class definition for the behavior pool. Its class name must match the implementation class referenced by the root behavior definition. |
| `public` | Makes the global behavior pool class visible as required for framework access. This does not mean every handler method should be a public global method. |
| `abstract` | Specifies a class that is not directly instantiated by ordinary application code. RAP dispatches business operations through its behavior runtime. |
| `final` | Disallows subclasses. The generated behavior pool is not intended as an inheritance extension point. |
| `for behavior of ZZMPR_SERVICEREQUEST01 .` | Associates this special-purpose class with the root RAP behavior definition; the behavior runtime links the implementation to that business object. |
| `public section.` | Starts public members of the global class. There are none in the captured shell. |
| `protected section.` | Starts members visible to the class and subclasses (there are none; the class is also final). |
| `private section.` | Starts implementation-private members of this global class. None are declared here. |
| `ENDCLASS.` | Ends the global class definition. |
| `CLASS ZZMPBP_R_SERVICEREQUEST01 IMPLEMENTATION.` | Opens the global class's implementation area. It is valid for it to have no methods. |
| `ENDCLASS.` | Ends the global implementation area. It does **not** end the source of the separate local handler class tab. |

Blank lines and capitalization do not affect execution. The `for behavior of` clause distinguishes the behavior pool from ordinary ABAP global classes.

## 3. Exactly where to find the code we must edit

In **Eclipse ADT**:

1. In Project Explorer, expand package `ZMPA_STARTER_01` → **Source Code Library** → **Classes** (or navigate via the BDEF quick links).
2. Open `ZZMPBP_R_SERVICEREQUEST01`.
3. In the class editor, find the **Local Types** tab beside **Global Class** (tab labels can vary by ADT release).
4. Copy the **entire Local Types** source. Look for declarations such as `CLASS lhc_ServiceRequest DEFINITION INHERITING FROM cl_abap_behavior_handler.`, `METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION`, or `CLASS lsc_... INHERITING FROM cl_abap_behavior_saver`.
5. If **Local Types** is missing or empty, navigate from a declaration in the active root BDEF using **Ctrl+Click**, **F3/Open Declaration**, or ADT quick fix **Create Behavior Implementation** / **Add behavior implementation** according to editor availability; record the actual generated source. Avoid guessing the method signatures.
6. Also copy the current **root BDEF** and **projection BDEF** after any changes, so method names, aliases, authorizations and projection-exposed actions match.
7. Inspect before making changes: preserve authorization methods and any generated logic. Do not overwrite the global class or create a second class with the same name from this guide.

## 4. What should live where

| Concern | Right implementation location |
|---|---|
| Public BO contracts, triggers, actions, draft settings | Root BDEF `ZZMPR_SERVICEREQUEST01` |
| Method signatures for RAP callbacks | Local handler declaration (Local Types) |
| Determination `SetDefaults` implementation | Local handler implementation (Local Types) |
| Validation `ValidateRequest` implementation | Local handler implementation (Local Types) |
| `StartRequest` / `CloseRequest` implementations | Local handler implementation (Local Types) |
| Additional save lifecycle methods, if necessary | Local saver class, respecting managed behavior and supported extensibility |
| Exposing actions for OData/Fiori | Projection BDEF and metadata/UI annotations |
| Independent rule policies | Global `ZCL_MPA_RULES`, with ABAP Unit tests |
| EML used inside handlers | `READ/MODIFY ENTITIES ... IN LOCAL MODE`, never a handler-side `COMMIT ENTITIES` |

**Do not add `METHOD SetDefaults`, `METHOD ValidateRequest`, or `METHOD StartRequest` to the empty global `IMPLEMENTATION` block.** These names must be declared and implemented with generated RAP handler signatures in the local class.

## 5. Next integration artifact

The required missing input is the complete **Local Types** content plus current root/projection BDEF. Only then can we make a compile-targeted handler implementation, with line-by-line explanations and testing procedures, without altering the already functioning draft-enabled CRUD application. See [RAP-IMPLEMENTATION.md](RAP-IMPLEMENTATION.md) and [EML-GUIDE.md](EML-GUIDE.md).
