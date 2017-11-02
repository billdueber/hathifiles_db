create view htid_expanded as SELECT
  h.htid id,
  h.allow,
  h.rights_code, r.rights,
  h.record_id,
  h.enumchron,
  h.source_code, sc.source,
  h.source_record_number inst_record_number,
  h.title,
  h.imprint,
  h.reason_code, reason.description reason_description,
  h.last_update,
  h.govdoc is_govdoc,
  h.pub_year,
  h.pub_place pub_place_code, c.country pub_place,
  h.language_code, l.language,
  h.bib_format_code,
  h.collection_code,
  h.content_provider_code,
  h.responsible_entity resonsible_entitiy_code,
  h.digitization_agent
FROM
  htid h
  JOIN rights_codes r on h.rights_code = r.code
  JOIN source_codes sc on h.source_code = sc.code
  JOIN language_codes l on h.language_code = l.code
  JOIN reason_codes reason on h.reason_code = reason.code
  join country_codes c on h.pub_place = c.code;

