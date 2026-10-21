CLASS zcl_mpa_seed_values DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_mpa_seed_values IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA priorities TYPE STANDARD TABLE OF zmpa_priority WITH EMPTY KEY.
    DATA statuses   TYPE STANDARD TABLE OF zmpa_status WITH EMPTY KEY.

    priorities = VALUE #(
      ( client = sy-mandt priority = 'H' priority_text = 'High' )
      ( client = sy-mandt priority = 'M' priority_text = 'Medium' )
      ( client = sy-mandt priority = 'L' priority_text = 'Low' ) ).

    statuses = VALUE #(
      ( client = sy-mandt status = 'O' status_text = 'Open' )
      ( client = sy-mandt status = 'I' status_text = 'In Progress' )
      ( client = sy-mandt status = 'C' status_text = 'Closed' ) ).

    MODIFY zmpa_priority FROM TABLE @priorities.
    DATA(priority_count) = sy-dbcnt.
    MODIFY zmpa_status FROM TABLE @statuses.
    DATA(status_count) = sy-dbcnt.

    out->write( |Priority rows affected: { priority_count }| ).
    out->write( |Status rows affected: { status_count }| ).
  ENDMETHOD.
ENDCLASS.
