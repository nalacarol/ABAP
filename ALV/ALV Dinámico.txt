*&---------------------------------------------------------------------*
*& Report  ZERIC_13
*&
*&---------------------------------------------------------------------*
*& Título........: Test Alv Dinámico
*& Descrição.....: Segundo a quantidade de colunas informada é incrementado no ALV
*&
*&---------------------------------------------------------------------*

REPORT  zeric_13.

TYPE-POOLS: slis.



FIELD-SYMBOLS:
<gt_dyntable> TYPE STANDARD TABLE, " Nome da Tabela interna dinâmica
<gs_dyntable>,                     " Field symbol para criar a work área
<gv_fldval> TYPE any.              " Field Symbol para atribuir valores

DATA: gt_fieldcat TYPE slis_t_fieldcat_alv, " Nós vamos usá-lo quando chamar o ALV
      gt_fcat     TYPE lvc_t_fcat.          " Nós vamos usá-lo ao criar a tabela dinâmica

DATA: gv_colno(2)  TYPE n,  " Número de colunas
      gv_flname(5) TYPE c.  " Nome do campo do fieldcat

PARAMETERS: pa_cols(5) TYPE c,  " Campo de texto para inserir o número de colunas
            pa_rows(5) TYPE c.  " Campo de texto para inserir o número de linhas

*----------------------------------------------------------------------*
*START-OF-SELECTION                                            *
*----------------------------------------------------------------------*
" Ao executar o relatório, as seguintes rotinas serão invocadas
PERFORM f_fill_dynamic_catalog.  " Preenche o catálogo de campos da tabela dinâmica
PERFORM f_cria_dynamic_itable.   " Cria a tabela interna dinâmica
PERFORM f_cria_dynamic_warea.    " Cria a área de trabalho para a tabela interna dinâmica
PERFORM f_fill_itable.           " Com as informações a tabela interna será exibida no ALV
PERFORM f_display_alv.           " Visualiza o ALV

*&---------------------------------------------------------------------*
*& Form f_fill_dynamic_catalog
*&---------------------------------------------------------------------*
*" Preenche o catálogo de campos da tabela dinâmica
*----------------------------------------------------------------------*
FORM f_fill_dynamic_catalog.
  DATA: ls_fcat TYPE lvc_s_fcat. "Work area local para o catalogo de campos

  " Primeira Colunna
  ls_fcat-fieldname = 'DESCRIPCION'.
  ls_fcat-datatype = 'CHAR'.
  ls_fcat-intlen = 15.
  APPEND ls_fcat TO gt_fcat.

  " De acordo com o número de colunas inseridas pelo usuário na tela.
  DO pa_cols TIMES.
    CLEAR ls_fcat.
    MOVE sy-index TO gv_colno.
    CONCATENATE 'COL' gv_colno INTO ls_fcat-fieldname.
    ls_fcat-datatype = 'CHAR'.
    ls_fcat-intlen = 10.
    APPEND ls_fcat TO gt_fcat.
  ENDDO.
ENDFORM. " f_fill_dynamic_catalog

*&-----------------------------------------------------------------------*
*& Form f_cria_dynamic_itable
*&-----------------------------------------------------------------------*
*" Cria a tabela interna dinâmica e atribue a um Field-Symbol
*&-----------------------------------------------------------------------*
FORM f_cria_dynamic_itable .
  "Referencia o objeto
  DATA lo_newtable TYPE REF TO data. " Para a tabela interna dinamica

  " Chamamos o método 'create_dynamic_table' da classe cl_alv_table_create
  " Como é uma classe estática, acessamos diretamente da classe para o método.
  CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog = gt_fcat
    IMPORTING
      ep_table        = lo_newtable.

  ASSIGN lo_newtable->* TO <gt_dyntable>.
ENDFORM. " f_cria_dynamic_itable

*&----------------------------------------------------------------------------------------------------*
*& Form f_cria_dynamic_warea
*&----------------------------------------------------------------------------------------------------*
*"Criar a work area para a tabela interna dinâmica e atribuí-la a um field-symbol
*&----------------------------------------------------------------------------------------------------*
FORM f_cria_dynamic_warea.
  "Referencia o objeto
  DATA lo_newline TYPE REF TO data. " Para a tabela interna dinamica

  CREATE DATA lo_newline LIKE LINE OF <gt_dyntable>.
  ASSIGN lo_newline->* TO <gs_dyntable>.
ENDFORM. " f_cria_dynamic_warea

*&-----------------------------------------------------------------------*
*& Form f_fill_itable
*&-----------------------------------------------------------------------*
*" Preenche a tabela interna que será exibida no ALV
*&-----------------------------------------------------------------------*
FORM f_fill_itable.

  DATA: lv_index_row(3) TYPE c,  " Número de linhas que estão sendo tratadas
        lv_index_col(3) TYPE c,  " Número de coluna que estão sendo tratadas
        lv_fldval(10)   TYPE c.  " Valor que será atribuído na referida célula da linha e coluna

  DO pa_rows TIMES. " Leitura das linhas que estão sendo inseridas na tela
    lv_index_row = sy-index.

* <gv_fldval> apontará para a coluna DESCRIPCION e para cada linha irá atribuir seu valor correspondente
* Por exemplo, se fosse um ALV dinâmico que mostrasse as características de um veículo, seria bom
* que antes foi definido primeiro uma tabela interna que contém os nomes de cada característica por * exemplo: COR, MODELO, ANO DE FABRICAÇÃO
* etc de tal forma que aqui o que seria feito é
* faça uma tabela de leitura para a referida tabela interna e, de acordo com a linha que está sendo analisada, leremos o texto.

    ASSIGN COMPONENT 'DESCRIPCION' OF STRUCTURE <gs_dyntable> TO <gv_fldval>.
    CONCATENATE 'FILA-' lv_index_row INTO lv_fldval.
    CONDENSE lv_fldval NO-GAPS. "NO-GAPS para eliminas os espaços em brancos
    <gv_fldval> = lv_fldval.

    DO pa_cols TIMES. " Para cada linha checamos as colunas que entraram na tela
      lv_index_col = sy-index.

      MOVE lv_index_col TO gv_colno.
      CONCATENATE 'COL' gv_colno INTO gv_flname.
      "<gv_fldval> apontará a coluna COL01, COL02, COL03 e assim por diante, de acordo com a coluna que "está sendo analisada e lá o novo valor correspondente será armazenado.
      ASSIGN COMPONENT gv_flname OF STRUCTURE <gs_dyntable> TO <gv_fldval>.

      CONCATENATE 'VALOR' lv_index_row '-' lv_index_col INTO lv_fldval.
      CONDENSE lv_fldval NO-GAPS."NO-GAPS para eliminas os espaços em brancos
      <gv_fldval> = lv_fldval.

    ENDDO. " Finaliza a analise de colunas

    APPEND <gs_dyntable> TO <gt_dyntable>."Añadimos la línea d valores a nuestra tabla interna dinámica

  ENDDO." Finaliza a criação das linhas

ENDFORM. " f_fill_itable

*&---------------------------------------------------------------------*
*& Form f_display_alv
*&---------------------------------------------------------------------*
*" Visualiza o ALV
*----------------------------------------------------------------------*
FORM f_display_alv.

  PERFORM fill_catalog_alv.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      it_fieldcat = gt_fieldcat
    TABLES
      t_outtab    = <gt_dyntable>.

ENDFORM. " f_display_alv



TYPE LVC_T_FCAT OPTIONAL



*&---------------------------------------------------------------------*
*& Form FILL_CATALOG_ALV
*&---------------------------------------------------------------------*
* Preenche o catálogo de campo do ALV a ser exibido na tela
*----------------------------------------------------------------------*
FORM fill_catalog_alv .
  DATA: ls_fieldcat TYPE slis_fieldcat_alv.

  ls_fieldcat-fieldname = 'DESCRIPCION'.
  ls_fieldcat-seltext_l = 'Nro de Fila'.
  ls_fieldcat-outputlen = '15'.
  APPEND ls_fieldcat TO gt_fieldcat.

  DO pa_cols TIMES.
    CLEAR ls_fieldcat.
    MOVE sy-index TO gv_colno.
    CONCATENATE 'COL' gv_colno INTO gv_flname.
    ls_fieldcat-fieldname = gv_flname.
    ls_fieldcat-seltext_s = gv_flname.
    ls_fieldcat-outputlen = '10'.
    APPEND ls_fieldcat TO gt_fieldcat.
  ENDDO.

ENDFORM. " FILL_CATALOG_ALV





*  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
*    EXPORTING
*      i_structure_name       = 'ZTRM_AUDITORIA'
*    CHANGING
*      ct_fieldcat            = lt_fieldcat
*    EXCEPTIONS
*      inconsistent_interface = 1
*      program_error          = 2
*      OTHERS                 = 3.
