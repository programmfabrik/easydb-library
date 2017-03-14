# easydb-library
Library to support Plugin Development for easydb

## Instead of:
```
class CustomDataTypePLUGINNAME extends CustomDataType
```

## Use: 
```
class CustomDataTypePLUGINNAME extends CustomDataTypeWithCommons
```
### And
* Remove the methods, which shell be used from *commons.coffee* from Plugincode
* Add the *commons.coffee* to your Makefile and prepend to your Pluginsource
* Rename the Autocompletion-Searchbar to "searchbarInput"
* CSS:
  * Class of Popover: commonPlugin_Popover
    * Class of Selects in Popover: commonPlugin_Select
    * Class of Inputs in Popover: commonPlugin_Input

