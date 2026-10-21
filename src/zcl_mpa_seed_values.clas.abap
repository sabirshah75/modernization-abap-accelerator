CLASS zcl_mpa_seed_values DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_mpa_seed_values IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    MODIFY zmpa_priority FROM TABLE @( VALUE #(
      ( client = sy-mandt priority = 'H' priority_text = 'High' )
      ( client = sy-mandt priority = 'M' priority_text = 'Medium' )
      ( client = sy-mandt priority = 'L' priority_text = 'Low' ) ) ).
    DATA(lv_priorities) = sy-dbcnt.

    MODIFY zmpa_status FROM TABLE @( VALUE #(
      ( client = sy-mandt status = 'O' status_text = 'Open' )
      ( client = sy-mandt status = 'I' status_text = 'In Progress' )
      ( client = sy-mandt status = 'C' status_text = 'Closed' ) ) ).
    DATA(lv_statuses) = sy-dbcnt.
    out->write( |Priority rows affected: { lv_priorities }| ).
    out->write( |Status rows affected: { lv_statuses }| ).
  ENDMETHOD.
ENDCLASS.
