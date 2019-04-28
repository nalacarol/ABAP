
type-pools : abap, slis.
field-symbols: <fs_table> type standard table,
               <fs_wa>,
               <fs_field>.
data: dyn_table    type ref to data,
      dyn_line     type ref to data,
      wa_fieldcat type lvc_s_fcat,
      it_fieldcat type lvc_t_fcat.

*ALV data declarations
data: fieldcatalog type slis_t_fieldcat_alv with header line,
      gd_tab_group type slis_t_sp_group_alv,
      gd_layout    TYPE slis_layout_alv,
      gd_repid     like sy-repid.

selection-screen begin of block block1 with frame.
parameters: p_table(30) type c default 'SFLIGHT'.
selection-screen end of block block1.

***********************************************************************
*start-of-selection.
start-of-selection.
  perform get_table_structure.
  perform create_itab_dynamically.
  perform get_data.
  perform display_data.

*&---------------------------------------------------------------------*
*&      Form  get_table_structure
*&---------------------------------------------------------------------*
*       Get structure of an SAP table
*----------------------------------------------------------------------*
form get_table_structure.
  data : it_tabdescr type abap_compdescr_tab,
         wa_tabdescr type abap_compdescr.
  data : ref_table_descr type ref to cl_abap_structdescr.

* Return structure of the table.
  ref_table_descr ?= cl_abap_typedescr=>describe_by_name( p_table ).
  it_tabdescr[] = ref_table_descr->components[].
  loop at it_tabdescr into wa_tabdescr.
    clear wa_fieldcat.
    wa_fieldcat-fieldname = wa_tabdescr-name .
    wa_fieldcat-datatype  = wa_tabdescr-type_kind.
    wa_fieldcat-inttype   = wa_tabdescr-type_kind.
    wa_fieldcat-intlen    = wa_tabdescr-length.
    wa_fieldcat-decimals  = wa_tabdescr-decimals.
    append wa_fieldcat to it_fieldcat.
  endloop.
endform.                    "get_table_structure

*&---------------------------------------------------------------------*
*&      Form  create_itab_dynamically
*&---------------------------------------------------------------------*
*       Create internal table dynamically
*----------------------------------------------------------------------*
form create_itab_dynamically.
* Create dynamic internal table and assign to Field-Symbol
  call method cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog = it_fieldcat
    IMPORTING
      ep_table        = dyn_table.
  assign dyn_table->* to <fs_table>.
* Create dynamic work area and assign to Field Symbol
  create data dyn_line like line of <fs_table>.
  assign dyn_line->* to <fs_wa>.
endform.                    "create_itab_dynamically

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Populate dynamic itab
*----------------------------------------------------------------------*
form get_data.
* Select Data from table using field symbol which points to dynamic itab
  select * into CORRESPONDING FIELDS OF TABLE  <fs_table>
             from (p_table).
endform.                    "get_data

*&---------------------------------------------------------------------*
*&      Form  display_data
*&---------------------------------------------------------------------*
*       display data using ALV
*----------------------------------------------------------------------*
FORM display_data.
  perform build_fieldcatalog.
  perform build_layout.
  perform display_alv_report.
ENDFORM.                    " display_data

*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
*       Build Fieldcatalog for ALV Report, using SAP table structure
*----------------------------------------------------------------------*
form build_fieldcatalog.
* ALV Function module to build field catalog from SAP table structure
  DATA: it_fcat  TYPE slis_t_fieldcat_alv.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = p_table
    CHANGING
      ct_fieldcat            = it_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  fieldcatalog[] =  it_fcat[].
endform.                    " BUILD_FIELDCATALOG

*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT
*&---------------------------------------------------------------------*
*       Build layout for ALV grid report
*----------------------------------------------------------------------*
form build_layout.
  gd_layout-colwidth_optimize = 'X'.
endform.                    " BUILD_LAYOUT

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_REPORT
*&---------------------------------------------------------------------*
*       Display report using ALV grid
*----------------------------------------------------------------------*
form display_alv_report.
  gd_repid = sy-repid.
  call function 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = gd_repid
      is_layout          = gd_layout
      it_fieldcat        = fieldcatalog[]
      i_save             = 'X'
    TABLES
      t_outtab           = <fs_table>
    EXCEPTIONS
      program_error      = 1
      others             = 2.
endform.                    " DISPLAY_ALV_REPORT