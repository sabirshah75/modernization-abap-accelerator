@EndUserText.label: 'Service Request Priority Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP
define view entity ZI_MPA_PRIORITY_VH as select from zmpa_priority
{
  @ObjectModel.text.element: ['PriorityText']
  key priority as Priority,
  @Semantics.text: true
  priority_text as PriorityText
}
