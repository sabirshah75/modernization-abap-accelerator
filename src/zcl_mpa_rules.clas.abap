CLASS zcl_mpa_rules DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_status   TYPE c LENGTH 1.
    TYPES ty_priority TYPE c LENGTH 1.

    " Pure educational business-rule model; no database dependencies.
    CLASS-METHODS can_start
      IMPORTING iv_status TYPE ty_status
      RETURNING VALUE(rv_allowed) TYPE abap_bool.
    CLASS-METHODS can_close
      IMPORTING iv_status TYPE ty_status
      RETURNING VALUE(rv_allowed) TYPE abap_bool.
    CLASS-METHODS valid_priority
      IMPORTING iv_priority TYPE ty_priority
      RETURNING VALUE(rv_valid) TYPE abap_bool.
    CLASS-METHODS valid_status
      IMPORTING iv_status TYPE ty_status
      RETURNING VALUE(rv_valid) TYPE abap_bool.
    CLASS-METHODS valid_title
      IMPORTING iv_title TYPE string
      RETURNING VALUE(rv_valid) TYPE abap_bool.
    CLASS-METHODS default_priority
      RETURNING VALUE(rv_priority) TYPE ty_priority.
    CLASS-METHODS default_status
      RETURNING VALUE(rv_status) TYPE ty_status.
ENDCLASS.

CLASS zcl_mpa_rules IMPLEMENTATION.
  METHOD can_start.
    rv_allowed = xsdbool( iv_status = 'O' ).
  ENDMETHOD.
  METHOD can_close.
    rv_allowed = xsdbool( iv_status = 'I' ).
  ENDMETHOD.
  METHOD valid_priority.
    rv_valid = xsdbool(
      iv_priority = 'L' OR iv_priority = 'M' OR iv_priority = 'H' ).
  ENDMETHOD.
  METHOD valid_status.
    rv_valid = xsdbool(
      iv_status = 'O' OR iv_status = 'I' OR iv_status = 'C' ).
  ENDMETHOD.
  METHOD valid_title.
    rv_valid = xsdbool( iv_title IS NOT INITIAL AND
                           strlen( iv_title ) <= 80 ).
  ENDMETHOD.
  METHOD default_priority.
    rv_priority = 'M'.
  ENDMETHOD.
  METHOD default_status.
    rv_status = 'O'.
  ENDMETHOD.
ENDCLASS.
