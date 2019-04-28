*&---------------------------------------------------------------------*
*& Report  ZACSB21
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  ZACSB21.

TABLES: ZACSB21_H, ZACSB21_I.

SELECTION-SCREEN:BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.

SELECT-OPTIONS: s_app  FOR zacsb21_h-aplicacao.
SELECT-OPTIONS: s_datl FOR zacsb21_h-data_lanc.
SELECT-OPTIONS: s_ref  FOR zacsb21_h-referencia.
SELECT-OPTIONS: s_datr FOR zacsb21_i-data_inc_reg.

SELECTION-SCREEN END OF BLOCK b1.

DATA: c_ccont   TYPE REF TO cl_gui_custom_container, "Custom container object
      c_alvgd   TYPE REF TO cl_gui_alv_grid,         "ALV grid object
      it_fcat   TYPE lvc_t_fcat,                     "Field catalogue
      it_layout TYPE lvc_s_layo.

DATA: c_ccont_log TYPE REF TO cl_gui_custom_container, "Custom container object
      c_alvgd_log TYPE REF TO cl_gui_alv_grid,         "ALV grid object
      it_fcat_log TYPE lvc_t_fcat.                     "Field catalogue

Data: stable TYPE lvc_s_stbl.

data: v_flag_monit TYPE c,
      v_flag_log   TYPE c.

data screen(4) TYPE n.

TYPES:BEGIN OF ty_out,
    check        TYPE C,
    cod_empresa  TYPE zacsb21_h-cod_empresa,
    cnpj         TYPE zacsb21_h-cnpj,
    referencia   TYPE zacsb21_h-referencia,
    aplicacao    TYPE zacsb21_h-aplicacao,
    data_doc     TYPE zacsb21_h-data_doc,
    data_lanc    TYPE zacsb21_h-data_lanc,
    exercicio    TYPE zacsb21_h-exercicio,
    periodo      TYPE zacsb21_h-periodo,
    item         TYPE zacsb21_i-item,
    chave_lanc   TYPE zacsb21_i-chave_lanc,
    conta_cont   TYPE zacsb21_i-conta_cont,
    montante     TYPE zacsb21_i-montante,
    atribuicao   TYPE zacsb21_i-atribuicao,
    texto        TYPE zacsb21_i-texto,
    data_inc_reg TYPE zacsb21_i-data_inc_reg,
    processado   TYPE zacsb21_i-processado,
    reenvio      TYPE zacsb21_i-reenvio,
    estorno      TYPE zacsb21_i-estorno,
END OF ty_out.

TYPES:BEGIN OF ty_log,
    status(4)      TYPE C,
    cod_empresa(4) TYPE n,
    referencia     TYPE zacsb21_h-referencia,
END OF ty_log.

DATA: it_out TYPE TABLE OF ty_out,
      wa_out TYPE ty_out,
      it_log TYPE TABLE OF ty_log,
      wa_log TYPE ty_log.

DATA: it_zacsb21_i TYPE TABLE OF zacsb21_i,
      wa_zacsb21_i TYPE zacsb21_i,
      it_zacsb21_h TYPE TABLE OF zacsb21_h,
      wa_zacsb21_h TYPE zacsb21_h.

data: bdc_tab like standard table of bdcdata initial size 0 with header line,
      T_MESSTAB TYPE BDCMSGCOLL OCCURS 0 WITH HEADER LINE.

START-OF-SELECTION.

  SELECT h~cod_empresa
         h~cnpj
         h~referencia
         aplicacao
         data_doc
         data_lanc
         exercicio
         periodo
         item
         chave_lanc
         conta_cont
         montante
         atribuicao
         texto
         data_inc_reg
         processado
         reenvio
         estorno
         FROM zacsb21_h AS h
           INNER JOIN zacsb21_i AS i ON
                        h~cod_empresa   = i~cod_empresa AND
                        h~cnpj          = i~cnpj        AND
                        h~referencia    = i~referencia
         INTO CORRESPONDING FIELDS OF TABLE it_out
          WHERE h~aplicacao    IN s_app  AND
                h~data_lanc    IN s_datl AND
                h~referencia   IN s_ref  AND
                i~data_inc_reg IN s_datr.

IF it_out is INITIAL.

SELECT *
  FROM zacsb21_h
  INTO CORRESPONDING FIELDS OF TABLE it_out
            WHERE aplicacao    IN s_app  AND
                  data_lanc    IN s_datl AND
                  referencia   IN s_ref.

ENDIF.

screen = 2010.

CALL SCREEN 2000.

INCLUDE ZACSB21_F01.

MODULE STATUS_2000 OUTPUT.
  SET PF-STATUS 'STATUS_2000'.
  SET TITLEBAR 'Monitor Interface Investran'.

IF it_fcat IS INITIAL.

*  SET field for ALV
  PERFORM alv_build_fieldcat.

ENDIF.

* Set ALV attributes FOR LAYOUT
  PERFORM alv_report_layout.

IF v_flag_monit IS NOT INITIAL.

  "Creating objects of the container

  CREATE OBJECT c_ccont
    EXPORTING
      container_name = 'C_MONIT'.

*  create object for alv grid

  CREATE OBJECT c_alvgd
    EXPORTING
      i_parent = c_ccont.

  CHECK NOT c_alvgd IS INITIAL.

   CALL METHOD c_alvgd->set_table_for_first_display
    EXPORTING
      is_layout                     = it_layout
      i_save                        = 'A'
    CHANGING
      it_outtab                     = IT_OUT
      it_fieldcatalog               = it_fcat
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.

   ENDIF.

IF v_flag_log IS NOT INITIAL.

  "Creating objects of the container

  CREATE OBJECT c_ccont_log
    EXPORTING
      container_name = 'C_LOG'.

*  create object for alv grid

  CREATE OBJECT c_alvgd_log
    EXPORTING
      i_parent = c_ccont_log.

  CHECK NOT c_alvgd_log IS INITIAL.

* Call ALV GRID

  CALL METHOD c_alvgd_log->set_table_for_first_display
    EXPORTING
      is_layout                     = it_layout
      i_save                        = 'A'
    CHANGING
      it_outtab                     = it_log
      it_fieldcatalog               = it_fcat_log
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.

ENDIF.

ENDMODULE.                 " STATUS_2000  OUTPUT

INCLUDE ZACSB21_USER_COMMAND_2000I01.

MODULE USER_COMMAND_2000 INPUT.

IF c_alvgd IS NOT INITIAL.

  c_alvgd->check_changed_data( ).

ENDIF.

  CASE SY-UCOMM.

    WHEN 'B_MONIT'. "Abrir apenas o Monitor aberto
      screen = 2020.
      v_flag_monit = 'X'.

    WHEN 'B_LOG'. "Abrir apenas o Log aberto
      screen = 2030.
      v_flag_log = 'X'.

    WHEN 'B_MONIT_CLOSE'. "Fechar o Monitor, todos estão fechados
      screen = 2010.
      clear v_flag_monit.

    WHEN 'B_LOG_CLOSE'. "Fechar o Log, todos estão fechados
      screen = 2010.
      clear v_flag_log.

    WHEN 'B_LOG_OPEN'. "Monitor aberto e abrir Log, todos estão abertos
      screen = 2040.
      v_flag_log = 'X'.

    WHEN 'B_MONIT_OPEN'. "Log aberto e abrir monitor, todos estão abertos
      screen = 2040.
      v_flag_monit = 'X'.

    WHEN 'B_MONIT_CLOSE_2'. "Log aberto e fechar monitor, apenas o log aberto
      screen = 2030.
      clear v_flag_monit.

    WHEN 'B_LOG_CLOSE_2'. "Monitor aberto e fechar log, apenas o monitor aberto
      screen = 2020.
      clear v_flag_log.

    WHEN 'BACK'.

      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'EXIT' or 'CANCEL'.

      LEAVE PROGRAM.

  ENDCASE.

  CLEAR: sy-ucomm.

ENDMODULE.                 " USER_COMMAND_2000  INPUT