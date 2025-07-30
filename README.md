# ZwdCSV-Cloud
## CSV Parser and Generator for ABAP Cloud

The Parser should respect [RFC 4180](https://tools.ietf.org/html/rfc4180), especially end-of-line characters inside of cells. Because of this, the entire CSV string is needed for correct parsing.

Class ZCL_WD_CSV contains Methods PARSE_STRING and GENERATE_STRING for directly handling csv strings.  

This is the abap cloud compatible successor to [ZwdCSV](https://github.com/WegnerDan/ZwdCSV)  

Currently, the conversion exit stuff is not working and there might be no way to include this in the ABAP Cloud version. 
