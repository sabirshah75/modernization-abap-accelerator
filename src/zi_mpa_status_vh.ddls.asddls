@EndUserText.label: 'Service Request Status Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP
define view entity ZI_MPA_STATUS_VH as select from zmpa_status
{
  @ObjectModel.text.element: ['StatusText']
  key status as Status,
  @Semantics.text: true
  status_text as StatusText
}
