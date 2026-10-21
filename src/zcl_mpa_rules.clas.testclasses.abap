" Tests for the independent reference rule model only; NOT RAP integration tests.
CLASS ltc_mpa_rules DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS start_open FOR TESTING.
    METHODS start_progress FOR TESTING.
    METHODS start_closed FOR TESTING.
    METHODS close_progress FOR TESTING.
    METHODS close_open FOR TESTING.
    METHODS close_closed FOR TESTING.
    METHODS priority_low FOR TESTING.
    METHODS priority_medium FOR TESTING.
    METHODS priority_high FOR TESTING.
    METHODS priority_other FOR TESTING.
    METHODS title_present FOR TESTING.
    METHODS title_empty FOR TESTING.
    METHODS title_too_long FOR TESTING.
ENDCLASS.

CLASS ltc_mpa_rules IMPLEMENTATION.
  METHOD start_open.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>can_start( 'O' ) exp = abap_true ).
  ENDMETHOD.
  METHOD start_progress.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>can_start( 'I' ) exp = abap_false ).
  ENDMETHOD.
  METHOD start_closed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>can_start( 'C' ) exp = abap_false ).
  ENDMETHOD.
  METHOD close_progress.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>can_close( 'I' ) exp = abap_true ).
  ENDMETHOD.
  METHOD close_open.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>can_close( 'O' ) exp = abap_false ).
  ENDMETHOD.
  METHOD close_closed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>can_close( 'C' ) exp = abap_false ).
  ENDMETHOD.
  METHOD priority_low.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>valid_priority( 'L' ) exp = abap_true ).
  ENDMETHOD.
  METHOD priority_medium.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>valid_priority( 'M' ) exp = abap_true ).
  ENDMETHOD.
  METHOD priority_high.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>valid_priority( 'H' ) exp = abap_true ).
  ENDMETHOD.
  METHOD priority_other.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>valid_priority( 'X' ) exp = abap_false ).
  ENDMETHOD.
  METHOD title_present.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>valid_title( 'Sample request' )
      exp = abap_true ).
  ENDMETHOD.
  METHOD title_empty.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>valid_title( '' ) exp = abap_false ).
  ENDMETHOD.
  METHOD title_too_long.
    DATA(long_title) = repeat( val = 'X' occ = 81 ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_mpa_rules=>valid_title( long_title )
      exp = abap_false ).
  ENDMETHOD.
ENDCLASS.
