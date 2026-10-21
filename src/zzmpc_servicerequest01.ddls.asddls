@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZZMPServiceRequest01'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZZMPC_SERVICEREQUEST01
  provider contract TRANSACTIONAL_QUERY
  as projection on ZZMPR_SERVICEREQUEST01
  association [1..1] to ZZMPR_SERVICEREQUEST01 as _BaseEntity on $projection.UUID = _BaseEntity.UUID
{
  key UUID,
  Title,
  Description,
  Priority,
  Status,
  CreatedBy,
  CreatedAt,
  @Semantics: {
    User.Createdby: true
  }
  LocalCreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  LocalCreatedAt,
  @Semantics: {
    User.Localinstancelastchangedby: true
  }
  LocalLastChangedBy,
  @Semantics: {
    Systemdatetime.Localinstancelastchangedat: true
  }
  LocalLastChangedAt,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  _BaseEntity
}
