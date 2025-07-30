CLASS ltc_parse_string DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: cut TYPE REF TO zcl_wd_csv.

    METHODS:
      setup                         RAISING cx_root,
      teardown                      RAISING cx_root,
      simple_csv_no_header           FOR TESTING RAISING cx_root,
      simple_csv_with_header         FOR TESTING RAISING cx_root,
      csv_with_quotes                FOR TESTING RAISING cx_root,
      csv_with_embedded_separator    FOR TESTING RAISING cx_root,
      csv_with_embedded_newlines     FOR TESTING RAISING cx_root,
      csv_with_different_separators  FOR TESTING RAISING cx_root,
      empty_fields                   FOR TESTING RAISING cx_root,
      csv_with_spaces                FOR TESTING RAISING cx_root,
      csv_with_spaces2                FOR TESTING RAISING cx_root,
      single_column_csv              FOR TESTING RAISING cx_root,
      empty_csv_string               FOR TESTING RAISING cx_root,
      empty_csv_string2              FOR TESTING RAISING cx_root.

    TYPES:
      BEGIN OF ty_test_struc,
        field1 TYPE string,
        field2 TYPE string,
        field3 TYPE string,
      END OF ty_test_struc,
      ty_test_table TYPE STANDARD TABLE OF ty_test_struc WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_single_field,
        field1 TYPE string,
      END OF ty_single_field,
      ty_single_table TYPE STANDARD TABLE OF ty_single_field WITH EMPTY KEY.
ENDCLASS.

CLASS ltc_parse_string IMPLEMENTATION.

  METHOD setup.
    CREATE OBJECT cut.
  ENDMETHOD.

  METHOD teardown.
    FREE cut.
  ENDMETHOD.

  METHOD simple_csv_no_header.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " Simple CSV without header
    csv = |Value1{ cl_abap_char_utilities=>horizontal_tab }Value2{ cl_abap_char_utilities=>horizontal_tab }Value3{ cl_abap_char_utilities=>cr_lf }|
       && |Value4{ cl_abap_char_utilities=>horizontal_tab }Value5{ cl_abap_char_utilities=>horizontal_tab }Value6{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( act = lines( result )
                                         exp = 2
                                         msg = 'Should have 2 rows' ).

    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-field1
                                         exp = 'Value1'
                                         msg = 'First row, first field incorrect' ).

    cl_abap_unit_assert=>assert_equals( act = result[ 2 ]-field3
                                         exp = 'Value6'
                                         msg = 'Second row, third field incorrect' ).
  ENDMETHOD.

  METHOD simple_csv_with_header.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " CSV with header
    csv = |field1{ cl_abap_char_utilities=>horizontal_tab }field2{ cl_abap_char_utilities=>horizontal_tab }field3{ cl_abap_char_utilities=>cr_lf }|
       && |Value1{ cl_abap_char_utilities=>horizontal_tab }Value2{ cl_abap_char_utilities=>horizontal_tab }Value3{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_true
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( act = lines( result )
                                         exp = 1
                                         msg = 'Should have 1 data row (header excluded)' ).

    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-field1
                                         exp = 'Value1'
                                         msg = 'First field incorrect' ).

    DATA(headers) = cut->get_header_columns( ).
    cl_abap_unit_assert=>assert_equals( act = lines( headers )
                                         exp = 3
                                         msg = 'Should have 3 header columns' ).
  ENDMETHOD.

  METHOD csv_with_quotes.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " CSV with quoted fields
    csv = |"Value1"{ cl_abap_char_utilities=>horizontal_tab }"Value2"{ cl_abap_char_utilities=>horizontal_tab }"Value3"{ cl_abap_char_utilities=>cr_lf }|
       && |"Value with ""quotes"""{ cl_abap_char_utilities=>horizontal_tab }Normal{ cl_abap_char_utilities=>horizontal_tab }"Another ""test"""{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-field1
                                         exp = 'Value1'
                                         msg = 'Quoted field incorrect' ).

    cl_abap_unit_assert=>assert_equals( act = result[ 2 ]-field1
                                         exp = 'Value with "quotes"'
                                         msg = 'Field with embedded quotes incorrect' ).
  ENDMETHOD.

  METHOD csv_with_embedded_separator.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " CSV with separator inside quoted field
    csv = |"Value{ cl_abap_char_utilities=>horizontal_tab }with tab"{ cl_abap_char_utilities=>horizontal_tab }Value2{ cl_abap_char_utilities=>horizontal_tab }Value3{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-field1
                                         exp = |Value{ cl_abap_char_utilities=>horizontal_tab }with tab|
                                         msg = 'Field with embedded separator incorrect' ).
  ENDMETHOD.

  METHOD csv_with_embedded_newlines.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " CSV with newline inside quoted field
    csv = |"Multi{ cl_abap_char_utilities=>cr_lf }line"{ cl_abap_char_utilities=>horizontal_tab }Value2{ cl_abap_char_utilities=>horizontal_tab }Value3{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-field1
                                         exp = |Multi{ cl_abap_char_utilities=>cr_lf }line|
                                         msg = 'Field with embedded newline incorrect' ).
  ENDMETHOD.

  METHOD csv_with_different_separators.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " Comma separator
    cut->set_separator( ',' ).

    csv = |Value1,Value2,Value3{ cl_abap_char_utilities=>cr_lf }|
       && |Value4,Value5,Value6{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-field2
                                         exp = 'Value2'
                                         msg = 'Comma separated field incorrect' ).

    " Semicolon separator
    CLEAR result.
    cut->set_separator( ';' ).

    csv = |Value1;Value2;Value3{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( act = result[ 1 ]-field3
                                         exp = 'Value3'
                                         msg = 'Semicolon separated field incorrect' ).
  ENDMETHOD.

  METHOD empty_fields.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " CSV with empty fields
    csv = |Value1{ cl_abap_char_utilities=>horizontal_tab }{ cl_abap_char_utilities=>horizontal_tab }Value3{ cl_abap_char_utilities=>cr_lf }|
       && |{ cl_abap_char_utilities=>horizontal_tab }Value2{ cl_abap_char_utilities=>horizontal_tab }{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_initial( act = result[ 1 ]-field2
                                         msg = 'Empty field should be initial' ).

    cl_abap_unit_assert=>assert_initial( act = result[ 2 ]-field1
                                         msg = 'Empty field at beginning should be initial' ).

    cl_abap_unit_assert=>assert_equals( act = result[ 2 ]-field2
                                         exp = 'Value2'
                                         msg = 'Non-empty field after empty incorrect' ).
  ENDMETHOD.

  METHOD csv_with_spaces.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " With trim_spaces enabled
    cut->set_trim_spaces( abap_true ).

    csv = |  Value1  { cl_abap_char_utilities=>horizontal_tab }Value2{ cl_abap_char_utilities=>horizontal_tab }  Value3{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header   = abap_false
                                 csv_string   = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( exp = 'Value1'
                                        act = result[ 1 ]-field1
                                        msg = 'Leading/trailing spaces should be trimmed' ).
  ENDMETHOD.

  METHOD csv_with_spaces2.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " With trim_spaces disabled (default)
    cut->set_trim_spaces( abap_false ).

    csv = |  Value1  { cl_abap_char_utilities=>horizontal_tab }Value2{ cl_abap_char_utilities=>horizontal_tab }  Value3{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header   = abap_false
                                 csv_string   = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( exp = `  Value1  `
                                        act = result[ 1 ]-field1
                                        msg = 'Spaces should be preserved when trim disabled' ).
  ENDMETHOD.

  METHOD single_column_csv.
    DATA: result TYPE ty_single_table,
          csv    TYPE string.

    " CSV with single column
    csv = |Value1{ cl_abap_char_utilities=>cr_lf }|
       && |Value2{ cl_abap_char_utilities=>cr_lf }|
       && |Value3{ cl_abap_char_utilities=>cr_lf }|.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_equals( act = lines( result )
                                         exp = 3
                                         msg = 'Should have 3 rows' ).

    cl_abap_unit_assert=>assert_equals( act = result[ 2 ]-field1
                                         exp = 'Value2'
                                         msg = 'Single column value incorrect' ).
  ENDMETHOD.

  METHOD empty_csv_string.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " Empty string
    CLEAR csv.

    cut->parse_string( EXPORTING has_header = abap_false
                                 csv_string = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = 'Empty CSV should result in empty table' ).


  ENDMETHOD.

  METHOD empty_csv_string2.
    DATA: result TYPE ty_test_table,
          csv    TYPE string.

    " Only spaces and newlines
    csv = |   { cl_abap_char_utilities=>cr_lf }{ cl_abap_char_utilities=>cr_lf }   |.

    cut->parse_string( EXPORTING has_header   = abap_false
                                 csv_string   = csv
                       IMPORTING target_table = result ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = 'CSV with only whitespace should result in empty table' ).
  ENDMETHOD.
ENDCLASS.
