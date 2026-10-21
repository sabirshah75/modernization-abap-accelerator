# ABAP source walkthrough — why each line exists

> This chapter is paired with the **actual** ABAP files in `src/`. Read source and explanations side by side. The six additional rules tests on this branch have not yet been run in the SAP tenant; the original 13 passed previously. The RAP objects generated locally in ADT are not in `src/` yet.

## A. `src/zcl_mpa_hello.clas.abap`

| Source line / construct | Why we use it |
|---|---|
| `CLASS zcl_mpa_hello DEFINITION` | Opens the definition of a global ABAP class available in the package. |
| `PUBLIC` | Allows other objects and ADT to reference the class. |
| `FINAL` | Disallows subclassing; this small console entry point needs no inheritance. |
| `CREATE PUBLIC.` | Allows normal construction where required by the runtime. |
| `PUBLIC SECTION.` | Introduces the public contract of the class. |
| `INTERFACES if_oo_adt_classrun.` | Implements the released ADT console entry point for running a simple check. |
| `ENDCLASS.` | Ends the class definition section. |
| `CLASS zcl_mpa_hello IMPLEMENTATION.` | Begins executable implementations for methods declared in the class. |
| `METHOD if_oo_adt_classrun~main.` | Implements the framework-called `main` method for Run As → ABAP Application. |
| `out->write( 'Modernization ABAP Accelerator - ADT connection OK' ).` | Writes a visible diagnostic message through the framework output object; no database changes. |
| `ENDMETHOD.` | Closes the method body. |
| `ENDCLASS.` | Closes the implementation section. |

Blank lines are formatting, not executable operations.

## B. `src/zcl_mpa_rules.clas.abap` — all statements explained

| Source line / construct | Why we use it |
|---|---|
| `CLASS zcl_mpa_rules DEFINITION` | Declares a reusable object for the business rules, separate from RAP persistence and UI code. |
| `PUBLIC` | Makes the class visible to behavior handlers and standalone unit tests. |
| `FINAL` | Prevents subclass overrides from changing the validation policy. |
| `CREATE PUBLIC.` | Keeps ordinary construction available, although all methods currently are static. |
| `PUBLIC SECTION.` | Exposes a stable contract to any caller. |
| `TYPES ty_status TYPE c LENGTH 1.` | Declares a one-character status type that matches `O`, `I`, `C`. |
| `TYPES ty_priority TYPE c LENGTH 1.` | Declares a one-character priority type that matches `L`, `M`, `H`. |
| Comment `Pure educational business-rule model` | States intentionally that no database/CDS/behavior implementation is required for this class. |
| `CLASS-METHODS can_start` | Declares a stateless policy check for the Start transition. |
| `IMPORTING iv_status TYPE ty_status` | Receives the current status without changing it. |
| `RETURNING VALUE(rv_allowed) TYPE abap_bool.` | Returns `abap_true` or `abap_false` so callers can branch clearly. |
| `CLASS-METHODS can_close` | Declares a separate policy for closing an in-progress request. |
| `IMPORTING iv_status TYPE ty_status` | Inputs one status code; identical type semantics to `can_start`. |
| `RETURNING VALUE(rv_allowed) TYPE abap_bool.` | Returns permission for the Close action. |
| `CLASS-METHODS valid_priority` | Declares reusable priority-domain validation. |
| `IMPORTING iv_priority TYPE ty_priority` | Ensures one-character priority input. |
| `RETURNING VALUE(rv_valid) TYPE abap_bool.` | Enables error handling at the caller without raising exceptions. |
| `CLASS-METHODS valid_status` | Declares a domain-level status check, distinct from transition rules. |
| `IMPORTING iv_status TYPE ty_status` | Receives status to check. |
| `RETURNING VALUE(rv_valid) TYPE abap_bool.` | Returns yes/no for supported status codes. |
| `CLASS-METHODS valid_title` | Declares text validation independent of RAP persistence. |
| `IMPORTING iv_title TYPE string` | Accepts a flexible caller string so the same rule works outside CDS-generated types. |
| `RETURNING VALUE(rv_valid) TYPE abap_bool.` | Reports whether title passes the rule. |
| `CLASS-METHODS default_priority` | Declares a central default policy rather than hardcoding it in many handlers. |
| `RETURNING VALUE(rv_priority) TYPE ty_priority.` | Returns a single-character default priority. |
| `CLASS-METHODS default_status` | Declares central default for new service requests. |
| `RETURNING VALUE(rv_status) TYPE ty_status.` | Returns a single-character default status. |
| `ENDCLASS.` (definition) | Ends the public interface section. |
| `CLASS zcl_mpa_rules IMPLEMENTATION.` | Starts concrete ABAP method bodies. |
| `METHOD can_start.` | Starts transition policy implementation. |
| `rv_allowed = xsdbool( iv_status = 'O' ).` | Allows start only when Open; `xsdbool` turns comparison into `abap_bool`. |
| `ENDMETHOD.` | Closes `can_start`. |
| `METHOD can_close.` | Starts close policy implementation. |
| `rv_allowed = xsdbool( iv_status = 'I' ).` | Allows close only from In Progress, never Open or Closed. |
| `ENDMETHOD.` | Closes `can_close`. |
| `METHOD valid_priority.` | Starts priority code check. |
| `rv_valid = xsdbool(` | Wraps Boolean expression for standard return type. |
| `iv_priority = 'L' OR iv_priority = 'M' OR iv_priority = 'H' ).` | Whitelists the only three allowed priority codes. |
| `ENDMETHOD.` | Closes priority validation. |
| `METHOD valid_status.` | Starts status domain validation. |
| `rv_valid = xsdbool(` | Converts comparison to an ABAP Boolean result. |
| `iv_status = 'O' OR iv_status = 'I' OR iv_status = 'C' ).` | Whitelists Open, In Progress, Closed; rejects unexpected codes. |
| `ENDMETHOD.` | Closes status check. |
| `METHOD valid_title.` | Starts title validation. |
| `rv_valid = xsdbool( iv_title IS NOT INITIAL AND` | Rejects an empty title before checking length. |
| `strlen( iv_title ) <= 80 ).` | Limits title length to the modeled 80 characters; adjust only alongside CDS/data element. |
| `ENDMETHOD.` | Closes title check. |
| `METHOD default_priority.` | Starts default priority calculation. |
| `rv_priority = 'M'.` | Establishes Medium as the default, leaving explicitly chosen user values untouched at the handler layer. |
| `ENDMETHOD.` | Closes priority default. |
| `METHOD default_status.` | Starts default status calculation. |
| `rv_status = 'O'.` | Establishes Open as the starting status for a newly created request. |
| `ENDMETHOD.` | Closes status default. |
| `ENDCLASS.` | Ends implementation of the rules class. |

**Design caution:** `valid_title` presently rejects the empty string, but may treat strings containing only spaces according to ABAP blank-string semantics. Add explicit whitespace policy and test cases if your business requirement requires trimming/non-whitespace. `can_start`/`can_close` only encode a condition; authorization and stale-data concurrency must still be enforced by RAP.

## C. `src/zcl_mpa_rules.clas.testclasses.abap` — every test statement pattern

Each of the **19 test methods** follows the same syntax:

```abap
CLASS ltc_mpa_rules DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS start_open FOR TESTING.
ENDCLASS.

CLASS ltc_mpa_rules IMPLEMENTATION.
  METHOD start_open.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>can_start( 'O' ) exp = abap_true ).
  ENDMETHOD.
ENDCLASS.
```

| Source line | Why it is needed |
|---|---|
| `CLASS ltc_mpa_rules DEFINITION FINAL FOR TESTING` | Makes a local, final ABAP Unit test class discoverable by test tooling. |
| `DURATION SHORT` | Declares that unit tests are fast. |
| `RISK LEVEL HARMLESS.` | Declares no risky side effects (the class only calls pure business-rule methods). |
| `PRIVATE SECTION.` | Test cases are implementation details, not public methods. |
| `METHODS start_open FOR TESTING.` | Registers this method as one ABAP Unit test case. Every distinct `METHODS ... FOR TESTING` declaration contributes a case. |
| `ENDCLASS.` | Closes test declarations. |
| `CLASS ltc_mpa_rules IMPLEMENTATION.` | Opens executable test bodies. |
| `METHOD start_open.` | Begins the named test. |
| `cl_abap_unit_assert=>assert_equals(` | Uses the standard ABAP Unit equality assertion. |
| `act = zcl_mpa_rules=>can_start( 'O' )` | Calls actual behavior with status Open to capture observed result. |
| `exp = abap_true ).` | Specifies expected result. ABAP Unit fails the test on mismatch. |
| `ENDMETHOD.` | Closes the case. |
| `ENDCLASS.` | Ends test implementation. |

The other methods differ only in their input, rule and expected return; each independently exercises a boundary or allowed/forbidden state. **The six new tests** are `status_open`, `status_progress`, `status_closed`, `status_unknown`, `default_priority_medium`, and `default_status_open`. They are pending verification in SAP.

### Test traceability table

| Methods | Rule verified |
|---|---|
| `start_open`, `start_progress`, `start_closed` | Start only from Open |
| `close_progress`, `close_open`, `close_closed` | Close only from In Progress |
| `priority_low`, `priority_medium`, `priority_high`, `priority_other` | L/M/H valid, unexpected code rejected |
| `title_present`, `title_empty`, `title_too_long` | Text required and limited to 80 |
| `status_open`, `status_progress`, `status_closed`, `status_unknown` | O/I/C valid, unexpected code rejected |
| `default_priority_medium`, `default_status_open` | M/O defaults |

## D. Why you should *not* inline every comment inside .abap source

This product uses two layers: concise high-value comments in production ABAP files, and an adjacent source walkthrough with line-by-line reasons. This keeps the executable sample readable during actual coding interviews and enterprise code reviews while ensuring a beginner can explain every statement. For the RAP handler and CDS objects **we cannot do a truthful line-by-line review until their actual generated source is exported**; [RAP-IMPLEMENTATION.md](RAP-IMPLEMENTATION.md) provides the next integration steps.

See also [EML-GUIDE.md](EML-GUIDE.md) for annotated EML by statement and example line.
