@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZZMPServiceRequest01'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZZMPR_SERVICEREQUEST01
  as select from ZZMPSRVCRQUEST01 as ServiceRequest
{
  key uuid as UUID,
  title as Title,
  description as Description,
  priority as Priority,
  status as Status,
  created_by as CreatedBy,
  created_at as CreatedAt,
  @Semantics.user.createdBy: true
  local_created_by as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  local_created_at as LocalCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt
}
