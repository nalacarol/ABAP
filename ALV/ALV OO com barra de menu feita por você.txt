*&---------------------------------------------------------------------*
*& Report  ZACSB16
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZACSB16.

*---------------------------------------------------------------------*
*       CLASS class_handle_events DEFINITION
*---------------------------------------------------------------------*
*  define a local class for handling events of cl_salv_table
*---------------------------------------------------------------------*
class class_handle_events definition.
  public section.
    methods:
      on_user_command
                    for event added_function of cl_salv_events
        importing e_salv_function. "e_salv_function es como el OK_CODE de las dynpros

endclass.                    "lcl_handle_events DEFINITION
*---------------------------------------------------------------------*
*       CLASS lcl_handle_events IMPLEMENTATION
*---------------------------------------------------------------------*
* implement the events for handling the events of cl_salv_table
*---------------------------------------------------------------------*
class class_handle_events implementation.

  method on_user_command.

    case e_salv_function. "Contiene el cod. de funcion del pulsador seleccionado
      WHEN 'GO_VBELN'.  "mensaje por pantalla
        MESSAGE 'Esto es una prueba, funcion GO_VBELN' TYPE 'I'.
      WHEN 'GO_VF03'.
        MESSAGE 'Esto es una prueba, funcion GO_VF03' TYPE 'I'.
      WHEN 'GO_MM02'.
        MESSAGE 'Esto es una prueba, funcion MM02' TYPE 'I'.
    ENDCASE.

  endmethod.

endclass.                    "lcl_handle_events IMPLEMENTATION

*---------------------------------------------------------------------*
*       TIPOS, ESTRUCTURAS y VARIABLES GLOBALES
*---------------------------------------------------------------------*
types: begin of type_matnr,
         matnr type mara-matnr,
         maktx type makt-maktx,
         mtart type mara-mtart,
         matkl type mara-matkl,
         meins type mara-meins,
       end of type_matnr.

* Tabla interna con los datos del ALV
data ti_mara type standard table of type_matnr.


data gr_table type ref to cl_salv_table.
data r_handler_salv_table type REF TO class_handle_events.

*Variables globales para gestionar las excepciones
data gr_msg  type string.
data cx_salv  type ref to cx_salv_msg.
data cx_not_found TYPE ref to cx_salv_not_found.
*&---------------------------------------------------------------------*
*& START-OF-SELECTION
*&---------------------------------------------------------------------*
start-of-selection.

  select m~matnr t~maktx m~mtart m~matkl m~meins
    into corresponding fields of table ti_mara
    from mara as m
    inner join makt as t
       on m~matnr eq t~matnr
      and t~spras eq sy-langu.

  try.
      cl_salv_table=>factory(
        importing
          r_salv_table = gr_table
        changing
          t_table      = ti_mara ).
    catch cx_salv_msg into cx_salv.
*     Gestionamos las excepciones que puedan suceder
      gr_msg = cx_salv->get_text( ).
      message gr_msg type 'E'.
  endtry.

  try.
*   Registramos el status gui para el ALV
      gr_table->set_screen_status( pfstatus = 'ZSTATUS'  "Nuestro STATUS GUI
                                   report = sy-repid
                                   set_functions = gr_table->C_FUNCTIONS_ALL ).

*   Creamos la instancia de la clase de eventos y registramos el evento on_user_command

      data salv_events type ref to cl_salv_events.

      salv_events = gr_table->get_event( ).
      CREATE OBJECT r_handler_salv_table.
      SET HANDLER r_handler_salv_table->on_user_command for salv_events.

    catch  cx_salv_msg into cx_salv.
      gr_msg = cx_salv->get_text( ).
      message gr_msg type 'E'.
    catch  cx_salv_not_found into cx_not_found.
      gr_msg = cx_not_found->get_text( ).
      message gr_msg type 'E'.
  endtry.

  gr_table->display( ).