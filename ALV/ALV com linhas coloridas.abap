
TABLES:     ekko.

type-pools: slis.                                 "ALV Declarations
*Data Declaration
*----------------
TYPES: BEGIN OF t_ekko,
  ebeln TYPE ekpo-ebeln,
  ebelp TYPE ekpo-ebelp,
  statu TYPE ekpo-statu,
  aedat TYPE ekpo-aedat,
  matnr TYPE ekpo-matnr,
  menge TYPE ekpo-menge,
  meins TYPE ekpo-meins,
  netpr TYPE ekpo-netpr,
  peinh TYPE ekpo-peinh,
  line_color(4) type c,     "Used to store row color attributes
 END OF t_ekko.

DATA: it_ekko TYPE STANDARD TABLE OF t_ekko INITIAL SIZE 0,
      wa_ekko TYPE t_ekko.

*ALV data declarations
data: fieldcatalog type slis_t_fieldcat_alv with header line,
      gd_tab_group type slis_t_sp_group_alv,
      gd_layout    type slis_layout_alv,
      gd_repid     like sy-repid.


************************************************************************
*Start-of-selection.
START-OF-SELECTION.

perform data_retrieval.
perform build_fieldcatalog.
perform build_layout.
perform display_alv_report.


*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCATALOG
*&---------------------------------------------------------------------*
*       Build Fieldcatalog for ALV Report
*----------------------------------------------------------------------*
form build_fieldcatalog.

* There are a number of ways to create a fieldcat.
* For the purpose of this example i will build the fieldcatalog manualy
* by populating the internal table fields individually and then
* appending the rows. This method can be the most time consuming but can
* also allow you  more control of the final product.

* Beware though, you need to ensure that all fields required are
* populated. When using some of functionality available via ALV, such as
* total. You may need to provide more information than if you were
* simply displaying the result
*               I.e. Field type may be required in-order for
*                    the 'TOTAL' function to work.

  fieldcatalog-fieldname   = 'EBELN'.
  fieldcatalog-seltext_m   = 'Purchase Order'.
  fieldcatalog-col_pos     = 0.
  fieldcatalog-outputlen   = 10.
  fieldcatalog-emphasize   = 'X'.
  fieldcatalog-key         = 'X'.
*  fieldcatalog-do_sum      = 'X'.
*  fieldcatalog-no_zero     = 'X'.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.

  fieldcatalog-fieldname   = 'EBELP'.
  fieldcatalog-seltext_m   = 'PO Item'.
  fieldcatalog-col_pos     = 1.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.

  fieldcatalog-fieldname   = 'STATU'.
  fieldcatalog-seltext_m   = 'Status'.
  fieldcatalog-col_pos     = 2.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.

  fieldcatalog-fieldname   = 'AEDAT'.
  fieldcatalog-seltext_m   = 'Item change date'.
  fieldcatalog-col_pos     = 3.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.

  fieldcatalog-fieldname   = 'MATNR'.
  fieldcatalog-seltext_m   = 'Material Number'.
  fieldcatalog-col_pos     = 4.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.

  fieldcatalog-fieldname   = 'MENGE'.
  fieldcatalog-seltext_m   = 'PO quantity'.
  fieldcatalog-col_pos     = 5.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.

  fieldcatalog-fieldname   = 'MEINS'.
  fieldcatalog-seltext_m   = 'Order Unit'.
  fieldcatalog-col_pos     = 6.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.

  fieldcatalog-fieldname   = 'NETPR'.
  fieldcatalog-seltext_m   = 'Net Price'.
  fieldcatalog-col_pos     = 7.
  fieldcatalog-outputlen   = 15.
  fieldcatalog-datatype     = 'CURR'.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.

  fieldcatalog-fieldname   = 'PEINH'.
  fieldcatalog-seltext_m   = 'Price Unit'.
  fieldcatalog-col_pos     = 8.
  append fieldcatalog to fieldcatalog.
  clear  fieldcatalog.
endform.                    " BUILD_FIELDCATALOG


*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT
*&---------------------------------------------------------------------*
*       Build layout for ALV grid report
*----------------------------------------------------------------------*
form build_layout.
  gd_layout-no_input          = 'X'.
  gd_layout-colwidth_optimize = 'X'.
  gd_layout-totals_text       = 'Totals'(201).
* Set layout field for row attributes(i.e. color) 
  gd_layout-info_fieldname =      'LINE_COLOR'.
*  gd_layout-totals_only        = 'X'.
*  gd_layout-f2code            = 'DISP'.  "Sets fcode for when double
*                                         "click(press f2)
*  gd_layout-zebra             = 'X'.
*  gd_layout-group_change_edit = 'X'.
*  gd_layout-header_text       = 'helllllo'.
endform.                    " BUILD_LAYOUT


*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_REPORT
*&---------------------------------------------------------------------*
*       Display report using ALV grid
*----------------------------------------------------------------------*
form display_alv_report.
  gd_repid = sy-repid.
  call function 'REUSE_ALV_GRID_DISPLAY'
       exporting
            i_callback_program      = gd_repid
*            i_callback_top_of_page   = 'TOP-OF-PAGE'  "see FORM
*            i_callback_user_command = 'USER_COMMAND'
*            i_grid_title           = outtext
            is_layout               = gd_layout
            it_fieldcat             = fieldcatalog[]
*            it_special_groups       = gd_tabgroup
*            IT_EVENTS                = GT_XEVENTS
            i_save                  = 'X'
*            is_variant              = z_template

       tables
            t_outtab                = it_ekko
       exceptions
            program_error           = 1
            others                  = 2.
  if sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  endif.
endform.                    " DISPLAY_ALV_REPORT


*&---------------------------------------------------------------------*
*&      Form  DATA_RETRIEVAL
*&---------------------------------------------------------------------*
*       Retrieve data form EKPO table and populate itab it_ekko
*----------------------------------------------------------------------*
form data_retrieval.
data: ld_color(1) type c.

select ebeln ebelp statu aedat matnr menge meins netpr peinh
 up to 10 rows
  from ekpo
  into table it_ekko.

*Populate field with color attributes
loop at it_ekko into wa_ekko.
* Populate color variable with colour properties
* Char 1 = C (This is a color property)
* Char 2 = 3 (Color codes: 1 - 7)
* Char 3 = Intensified on/off ( 1 or 0 )
* Char 4 = Inverse display on/off ( 1 or 0 )
*           i.e. wa_ekko-line_color = 'C410'
  ld_color = ld_color + 1.

* Only 7 colours so need to reset color value
  if ld_color = 8.
    ld_color = 1.
  endif.
  concatenate 'C' ld_color '10' into wa_ekko-line_color.
*  wa_ekko-line_color = 'C410'.
  modify it_ekko from wa_ekko.
endloop.
endform.                    " DATA_RETRIEVAL