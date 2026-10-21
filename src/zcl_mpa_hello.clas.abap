CLASS zcl_mpa_hello DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_mpa_hello IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( 'Modernization ABAP Accelerator - ADT connection OK' ).
  ENDMETHOD.
ENDCLASS.
