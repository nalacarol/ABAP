*&---------------------------------------------------------------------*
*& Report  ZACSB15
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZACSB15.

DATA:
  gt_usr   TYPE TABLE OF usr02,
  gs_usr   TYPE usr02.

DATA:
    gr_table      TYPE REF TO cl_salv_table,
    gr_columns    TYPE REF TO cl_salv_columns_table,
    gr_column     TYPE REF TO cl_salv_column_list.

*----------------------------------------------------------------------*
*       CLASS cl_event_handler DEFINITION
*----------------------------------------------------------------------*
CLASS cl_event_handler DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS on_before_salv_function         " BEFORE_SALV_FUNCTION
      FOR EVENT if_salv_events_functions~before_salv_function
        OF cl_salv_events_table
          IMPORTING e_salv_function.

    CLASS-METHODS on_after_salv_function          " AFTER_SALV_FUNCTION
      FOR EVENT if_salv_events_functions~before_salv_function
        OF cl_salv_events_table
          IMPORTING e_salv_function.

    CLASS-METHODS on_added_function               " ADDED_FUNCTION
      FOR EVENT if_salv_events_functions~added_function
        OF cl_salv_events_table
          IMPORTING e_salv_function.

    CLASS-METHODS on_top_of_page                  " TOP_OF_PAGE
      FOR EVENT if_salv_events_list~top_of_page
        OF cl_salv_events_table
          IMPORTING r_top_of_page
                    page
                    table_index.

    CLASS-METHODS on_end_of_page                  " END_OF_PAGE
      FOR EVENT if_salv_events_list~end_of_page
        OF cl_salv_events_table
          IMPORTING r_end_of_page
                    page.

    CLASS-METHODS on_double_click                 " DOUBLE_CLICK
      FOR EVENT if_salv_events_actions_table~double_click
        OF cl_salv_events_table
          IMPORTING row
                    column.

    CLASS-METHODS on_link_click                   " LINK_CLICK
      FOR EVENT if_salv_events_actions_table~link_click
        OF cl_salv_events_table
          IMPORTING row
                    column.
ENDCLASS.                    "cl_event_handler DEFINITION

*----------------------------------------------------------------------*
*       CLASS cl_event_handler IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS cl_event_handler IMPLEMENTATION.

  METHOD on_before_salv_function.

  ENDMETHOD.                    "on_before_salv_function

  METHOD on_after_salv_function.

  ENDMETHOD.                    "on_after_salv_function

  METHOD on_added_function.

  ENDMETHOD.                    "on_added_function

  METHOD on_top_of_page.

  ENDMETHOD.                    "on_top_of_page

  METHOD on_end_of_page.

  ENDMETHOD.                    "on_end_of_page

  METHOD on_double_click.
    TRY.
        gr_columns = gr_table->get_columns( ).
        gr_column ?= gr_columns->get_column( 'BCODE' ).
        gr_column->set_visible( value  = if_salv_c_bool_sap=>false ).
      CATCH cx_salv_not_found.
    ENDTRY .
  ENDMETHOD.                    "on_double_click

  METHOD on_link_click.
    TRY.
        gr_columns = gr_table->get_columns( ).
        gr_column ?= gr_columns->get_column( 'BCODE' ).
        gr_column->set_visible( value  = if_salv_c_bool_sap=>true ).
      CATCH cx_salv_not_found.
    ENDTRY .
  ENDMETHOD.                    "on_link_click
ENDCLASS.                    "cl_event_handler IMPLEMENTATION

*&---------------------------------------------------------------------*
*&      START-OF-SELECTION
*&---------------------------------------------------------------------*
START-OF-SELECTION.

* read sample data to internal table
  SELECT * FROM usr02 UP TO 30 ROWS
    APPENDING CORRESPONDING FIELDS OF TABLE gt_usr
    ORDER BY bname.

  PERFORM display_alv.

*&---------------------------------------------------------------------*
*&      Form  display_alv
*&---------------------------------------------------------------------*
FORM display_alv.

data     gr_events     TYPE REF TO cl_salv_events_table.

  TRY.
      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = gr_table
        CHANGING
          t_table      = gt_usr.

      gr_events = gr_table->get_event( ).
      SET HANDLER cl_event_handler=>on_before_salv_function FOR gr_events.
      SET HANDLER cl_event_handler=>on_after_salv_function  FOR gr_events.
      SET HANDLER cl_event_handler=>on_added_function       FOR gr_events.
      SET HANDLER cl_event_handler=>on_top_of_page          FOR gr_events.
      SET HANDLER cl_event_handler=>on_end_of_page          FOR gr_events.
      SET HANDLER cl_event_handler=>on_double_click         FOR gr_events.
      SET HANDLER cl_event_handler=>on_link_click           FOR gr_events.

*     ALV-Toolbar
      gr_table->set_screen_status(
        pfstatus      = 'STANDARD_FULLSCREEN'
        report        = 'SAPLSLVC_FULLSCREEN'
        set_functions = gr_table->c_functions_all ).

      data: gr_funct type ref to cl_salv_functions.

      gr_funct = gr_table->get_functions( ).
      gr_funct->set_all( Abap_True ).

      DATA columns TYPE REF TO cl_salv_columns_table.
      columns = gr_table->get_columns( ).
      columns->set_optimize( ).


*     Set column as hotspot
      gr_columns = gr_table->get_columns( ).
      gr_column ?= gr_columns->get_column( 'BNAME' ).
      gr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

    TRY.
        gr_columns = gr_table->get_columns( ).
        gr_column ?= gr_columns->get_column( 'BCODE' ).
        gr_column->set_visible( value  = if_salv_c_bool_sap=>false ).
      CATCH cx_salv_not_found.
    ENDTRY .

      gr_table->display( ).

    CATCH cx_salv_msg.             " cl_salv_table=>factory()
      WRITE: / 'cx_salv_msg exception'.
      STOP.
    CATCH cx_salv_not_found.       " cl_salv_columns_table->get_column()
      WRITE: / 'cx_salv_not_found exception'.
      STOP.
  ENDTRY.
ENDFORM.                    "display_alv