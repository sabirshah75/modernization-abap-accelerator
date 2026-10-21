" RAP handler source for behavior pool ZZMPBP_R_SERVICEREQUEST01.
" ADT: Global class -> Local Types. Integrate/reconcile generated methods.
" EDUCATIONAL TRIAL IMPLEMENTATION — not yet activated in SAP.
CLASS lhc_ServiceRequest DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations
      FOR ServiceRequest
      RESULT result.

    METHODS SetDefaults
      FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ServiceRequest~SetDefaults.

    METHODS ValidateRequest
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR ServiceRequest~ValidateRequest.

    METHODS StartRequest
      FOR MODIFY
      IMPORTING keys FOR ACTION ServiceRequest~StartRequest
      RESULT result.

    METHODS CloseRequest
      FOR MODIFY
      IMPORTING keys FOR ACTION ServiceRequest~CloseRequest
      RESULT result.

ENDCLASS.

CLASS lhc_ServiceRequest IMPLEMENTATION.

  METHOD get_global_authorizations.
    " IMPORTANT: demonstration only; replace with real authorization checks
    " before using outside an isolated fictional-data trial.
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD SetDefaults.
    " LOCAL MODE reads the current RAP transactional buffer, including draft.
    READ ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
      ENTITY ServiceRequest
      FIELDS ( Priority Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(ls_read_failed).

    " Explicit %control flags update only missing fields.
    DATA lt_updates TYPE TABLE FOR UPDATE ZZMPR_SERVICEREQUEST01.

    LOOP AT lt_requests ASSIGNING FIELD-SYMBOL(<request>).
      IF <request>-Priority IS NOT INITIAL
         AND <request>-Status IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO lt_updates ASSIGNING FIELD-SYMBOL(<update>).
      <update>-%tky = <request>-%tky.

      IF <request>-Priority IS INITIAL.
        <update>-Priority = zcl_mpa_rules=>default_priority( ).
        <update>-%control-Priority = if_abap_behv=>mk-on.
      ENDIF.

      IF <request>-Status IS INITIAL.
        <update>-Status = zcl_mpa_rules=>default_status( ).
        <update>-%control-Status = if_abap_behv=>mk-on.
      ENDIF.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
        ENTITY ServiceRequest
        UPDATE FROM lt_updates
        FAILED DATA(ls_modify_failed)
        REPORTED DATA(ls_modify_reported).
    ENDIF.
  ENDMETHOD.

  METHOD ValidateRequest.
    " The validation runs at RAP save/activation, not at every keystroke.
    READ ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
      ENTITY ServiceRequest
      FIELDS ( Title Priority Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(ls_read_failed).

    APPEND LINES OF ls_read_failed-servicerequest
      TO failed-servicerequest.

    LOOP AT lt_requests ASSIGNING FIELD-SYMBOL(<request>).
      DATA(lv_invalid) = abap_false.

      IF zcl_mpa_rules=>valid_title(
           CONV string( <request>-Title ) ) = abap_false.
        lv_invalid = abap_true.
        APPEND VALUE #(
          %tky = <request>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Title is required and must be at most 80 characters' )
          %element-Title = if_abap_behv=>mk-on )
          TO reported-servicerequest.
      ENDIF.

      IF zcl_mpa_rules=>valid_priority(
           <request>-Priority ) = abap_false.
        lv_invalid = abap_true.
        APPEND VALUE #(
          %tky = <request>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Priority must be L, M, or H' )
          %element-Priority = if_abap_behv=>mk-on )
          TO reported-servicerequest.
      ENDIF.

      IF zcl_mpa_rules=>valid_status(
           <request>-Status ) = abap_false.
        lv_invalid = abap_true.
        APPEND VALUE #(
          %tky = <request>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Status must be O, I, or C' )
          %element-Status = if_abap_behv=>mk-on )
          TO reported-servicerequest.
      ENDIF.

      IF lv_invalid = abap_true.
        APPEND VALUE #( %tky = <request>-%tky )
          TO failed-servicerequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD StartRequest.
    READ ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
      ENTITY ServiceRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(ls_read_failed).

    APPEND LINES OF ls_read_failed-servicerequest
      TO failed-servicerequest.

    DATA lt_updates TYPE TABLE FOR UPDATE ZZMPR_SERVICEREQUEST01.

    LOOP AT lt_requests ASSIGNING FIELD-SYMBOL(<request>).
      IF zcl_mpa_rules=>can_start( <request>-Status ) = abap_false.
        APPEND VALUE #( %tky = <request>-%tky )
          TO failed-servicerequest.
        APPEND VALUE #(
          %tky = <request>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Only Open requests may be started' )
          %element-Status = if_abap_behv=>mk-on )
          TO reported-servicerequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky = <request>-%tky
        Status = 'I'
        %control-Status = if_abap_behv=>mk-on )
        TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
        ENTITY ServiceRequest
        UPDATE FROM lt_updates
        FAILED DATA(ls_modify_failed)
        REPORTED DATA(ls_modify_reported).

      APPEND LINES OF ls_modify_failed-servicerequest
        TO failed-servicerequest.
      APPEND LINES OF ls_modify_reported-servicerequest
        TO reported-servicerequest.

      READ ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
        ENTITY ServiceRequest
        ALL FIELDS
        WITH CORRESPONDING #( lt_updates )
        RESULT DATA(lt_after).

      result = VALUE #(
        FOR request IN lt_after
          ( %tky = request-%tky
            %param = request ) ).
    ENDIF.
  ENDMETHOD.

  METHOD CloseRequest.
    READ ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
      ENTITY ServiceRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests)
      FAILED DATA(ls_read_failed).

    APPEND LINES OF ls_read_failed-servicerequest
      TO failed-servicerequest.

    DATA lt_updates TYPE TABLE FOR UPDATE ZZMPR_SERVICEREQUEST01.

    LOOP AT lt_requests ASSIGNING FIELD-SYMBOL(<request>).
      IF zcl_mpa_rules=>can_close( <request>-Status ) = abap_false.
        APPEND VALUE #( %tky = <request>-%tky )
          TO failed-servicerequest.
        APPEND VALUE #(
          %tky = <request>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Only In Progress requests may be closed' )
          %element-Status = if_abap_behv=>mk-on )
          TO reported-servicerequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        %tky = <request>-%tky
        Status = 'C'
        %control-Status = if_abap_behv=>mk-on )
        TO lt_updates.
    ENDLOOP.

    IF lt_updates IS NOT INITIAL.
      MODIFY ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
        ENTITY ServiceRequest
        UPDATE FROM lt_updates
        FAILED DATA(ls_modify_failed)
        REPORTED DATA(ls_modify_reported).

      APPEND LINES OF ls_modify_failed-servicerequest
        TO failed-servicerequest.
      APPEND LINES OF ls_modify_reported-servicerequest
        TO reported-servicerequest.

      READ ENTITIES OF ZZMPR_SERVICEREQUEST01 IN LOCAL MODE
        ENTITY ServiceRequest
        ALL FIELDS
        WITH CORRESPONDING #( lt_updates )
        RESULT DATA(lt_after).

      result = VALUE #(
        FOR request IN lt_after
          ( %tky = request-%tky
            %param = request ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
