
REPORT  ZACSB12.

*-----------------------------------------------------------------------
* TABLES
*-----------------------------------------------------------------------
TABLES: mara.

*-----------------------------------------------------------------------
* TYPES DEFINITIONS
*-----------------------------------------------------------------------
TYPES: BEGIN OF ty_mara,
         matnr TYPE mara-matnr, " NUMERO DO MATERIAL
         mtart TYPE mara-mtart, " TIPO DO MATERIAL
       END OF ty_mara,
       BEGIN OF ty_t134t,
         mtart TYPE t134t-mtart, " TIPO DO MATERIAL
         mtbez TYPE t134t-mtbez, " DENOMINAÃO DO TIPO DO MATERIAL
       END OF ty_t134t.

*-----------------------------------------------------------------------
* TABLE TYPES DEFINITIONS
*-----------------------------------------------------------------------
DATA: gt_mara TYPE TABLE OF ty_mara,
      gt_t134 TYPE TABLE OF ty_t134t.

* Tabela alv
DATA: gt_fieldcat TYPE lvc_t_fcat.

*-----------------------------------------------------------------------
* WORKAREA DEFINITIONS
*-----------------------------------------------------------------------
DATA: wa_mara  TYPE ty_mara,
      wa_t134t TYPE ty_t134t.

* Tabela alv
DATA: wa_layout   TYPE lvc_s_layo,
      wa_variant  TYPE disvariant,
      wa_fieldcat TYPE lvc_t_fcat.

*-----------------------------------------------------------------------
* OBJECT DEFINITIONS
*-----------------------------------------------------------------------
DATA: ob_grid TYPE REF TO cl_gui_alv_grid,
      ob_splitter TYPE REF TO cl_gui_splitter_container,
      ob_container_grid TYPE REF TO cl_gui_container,
      ob_container_html TYPE REF TO cl_gui_container,
      ob_document TYPE REF TO cl_dd_document,
      O_HTML_CNTRL TYPE REF TO CL_GUI_HTML_VIEWER.

*-----------------------------------------------------------------------
* SELECTION-SCREEN DEFINITIONS
*-----------------------------------------------------------------------
SELECTION-SCREEN: BEGIN OF  BLOCK b01 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: s_matnr FOR mara-matnr.
SELECTION-SCREEN: END OF BLOCK b01.

*-----------------------------------------------------------------------
* START-OF-SELECTION.
*-----------------------------------------------------------------------
START-OF-SELECTION.
* SELECIONA TABELA DE MATERIAIS
  PERFORM f_seleciona_mara.

  CALL SCREEN 100.

*&---------------------------------------------------------------------*
*&      Form  F_SELECIONA_MARA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_seleciona_mara .
  SELECT matnr
         mtart
         FROM mara
    INTO TABLE gt_mara
    WHERE  matnr IN s_matnr.

ENDFORM.                    " F_SELECIONA_MARA
*&---------------------------------------------------------------------*
*&      Form  F_LAYOUT_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_layout_fieldcat .

  CLEAR: wa_layout.
  wa_layout-zebra = 'X'.

  wa_layout-cwidth_opt = 'X'.          "Largura melhor possível coluna
  wa_layout-edit       = space.        "Não Permitir a edição
  wa_layout-sel_mode   = 'D'.          "Modo de Seleção
  wa_layout-zebra      = 'X'.          "Listagem aparece zebrada.
  wa_layout-info_fname = 'LINE_COLOR'. "Campo para definição de cor
  wa_layout-no_rowmark = 'X'.          "SEM MARCAÇÃO DE LINHAS
  wa_layout-no_hgridln = ' '.          "SEM LINHAS HORIZONTAIS
  wa_layout-no_vgridln = ' '.          "SEM LINHAS VERTICAIS
  wa_variant-report    = sy-repid.     "NOME DO PROGRAMA



ENDFORM.                    " F_LAYOUT_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  F_BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_build_fieldcat .

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = 'ZST_ALV_OO'
    CHANGING
      ct_fieldcat            = gt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.

  ENDIF.

ENDFORM.                    " F_BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  F_BUILD_CONTAINER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_build_container .

*  CREATE OBJECT ob_grid
*    EXPORTING
*      i_parent = cl_gui_container=>default_screen.

* Cria um container
  CREATE OBJECT ob_splitter
    EXPORTING
      parent  = cl_gui_container=>default_screen
      rows    = 2 " 2 linha = título e campos
      columns = 1.

*   Define os espaços
  CALL METHOD ob_splitter->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = ob_container_grid. "Container I

  CALL METHOD ob_splitter->set_row_height
    EXPORTING
      id     = 1
      height = 20.

*   2a.parte do container : TITULO
  CALL METHOD ob_splitter->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = ob_container_html. "Container II

*   Create TOP-Document: Titulo
  CREATE OBJECT ob_document
    EXPORTING
      style = 'ALV_GRID'.

*    from here as usual..you need to specify parent as splitter part
*    which we alloted for grid
  CREATE OBJECT ob_grid
    EXPORTING
      i_parent          = ob_container_html
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  CALL METHOD ob_grid->set_table_for_first_display
    EXPORTING
      is_layout       = wa_layout
      is_variant      = wa_variant
      i_save          = 'A'
    CHANGING
      it_outtab       = gt_mara
      it_fieldcatalog = gt_fieldcat.


  CALL METHOD ob_document->initialize_document
    EXPORTING
      background_color = cl_dd_area=>col_textarea.

** Filling top of page
  perform FILL_TOP_OF_PAGE.

 CALL METHOD ob_document->display_document
    EXPORTING
       parent = ob_container_grid.

  CALL METHOD ob_document->initialize_document.

  CALL METHOD ob_grid->list_processing_events
    EXPORTING
      i_event_name = 'TOP_OF_PAGE'
      i_dyndoc_id  = ob_document.

*   Seta X para ter interatividade para ter ação dentro do programa
*   (chama a execução de performs do pgm ao clicar em botões no alv)
  CALL METHOD ob_grid->set_toolbar_interactive.


ENDFORM.                   " F_BUILD_CONTAINER

*&---------------------------------------------------------------------*
*&      Form  FILL_TOP_OF_PAGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form FILL_TOP_OF_PAGE .

* Calling the methods for dynamic text
      CALL METHOD ob_document->add_text
      EXPORTING
        text          = 'List Item Details For : '
        sap_style     = cl_dd_document=>heading
        sap_fontsize  = cl_dd_document=>medium
        sap_emphasis  = cl_dd_document=>strong.

* Adding Line
  CALL METHOD ob_document->new_line.
  CALL METHOD ob_document->new_line.

* Calling the methods for dynamic text
      CALL METHOD ob_document->add_text
      EXPORTING
        text          = 'Teste'.

* Adding Line
  CALL METHOD ob_document->new_line.

*
  CALL FUNCTION 'REUSE_ALV_GRID_COMMENTARY_SET'
    EXPORTING
      Document = ob_document
      bottom   = space.

endform.                    " FILL_TOP_OF_PAGE


*&---------------------------------------------------------------------*
*&      Module  STATUS_0900  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS '0100'.
  SET TITLEBAR '0100'.

ENDMODULE.                 " STATUS_0900  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  EXIBE_RELATORIO  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exibe_relatorio OUTPUT.

  IF ob_grid IS INITIAL.
*    Define layout
    PERFORM f_layout_fieldcat.

*    Define os campos do alv
    PERFORM f_build_fieldcat.

*    Monta container
    PERFORM f_build_container.
  ELSE.
    CALL METHOD ob_grid->refresh_table_display.
  ENDIF.

ENDMODULE.                 " EXIBE_RELATORIO  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0900  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE sy-ucomm.
    WHEN 'BACK'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'CANCEL' OR 'EXIT'.
      LEAVE PROGRAM.
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0900  INPUT

INCLUDE ZACSB12_FILL_TOP_OF_PAGEF01.