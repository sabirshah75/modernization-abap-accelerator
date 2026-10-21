CLASS lhc_zzmpr_servicerequest01 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ServiceRequest
        RESULT result,
      SetDefaults FOR DETERMINE ON MODIFY
       keys FOR ServiceRequest~SetDefaults.

    METHODS ValidateRequest FOR VALIDATE ON SAVE
       keys FOR ServiceRequest~ValidateRequest.
ENDCLASS.

CLASS lhc_zzmpr_servicerequest01 IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD SetDefaults.

    READ ENTITIES OF zzmpr_servicerequest01 IN LOCAL MODE
      ENTITY ServiceRequest
      FIELDS ( Priority Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    MODIFY ENTITIES OF zzmpr_servicerequest01 IN LOCAL MODE
      ENTITY ServiceRequest
      UPDATE FIELDS ( Priority Status )
      WITH VALUE #(
        FOR ls_request IN lt_requests
        ( %tky     = ls_request-%tky
          Priority = COND #(
            WHEN ls_request-Priority IS INITIAL
            THEN 'M'
            ELSE ls_request-Priority )
          Status   = COND #(
            WHEN ls_request-Status IS INITIAL
            THEN 'O'
            ELSE ls_request-Status ) )
      )
      REPORTED DATA(lt_reported).

  ENDMETHOD.

  METHOD ValidateRequest.

    READ ENTITIES OF zzmpr_servicerequest01 IN LOCAL MODE
      ENTITY ServiceRequest
      FIELDS ( Title Priority Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    LOOP AT lt_requests INTO DATA(ls_request).


      IF ls_request-Title IS INITIAL
         OR ( ls_request-Priority <> 'H'
          AND ls_request-Priority <> 'M'
          AND ls_request-Priority <> 'L' )
         OR ( ls_request-Status <> 'O'
          AND ls_request-Status <> 'I'
          AND ls_request-Status <> 'C' ).

        APPEND VALUE #( %tky = ls_request-%tky )
          TO failed-ServiceRequest.

        APPEND VALUE #(
          %tky = ls_request-%tky
          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Invalid service request data' )
        ) TO reported-ServiceRequest.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
