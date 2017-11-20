module HathifilesDB
  module Constants
    HF_COLUMNS = %i[
       id
       access
       rights_code
       record_id
       enumchron
       source_code
       source_record_number
       oclcs
       isbns
       issns
       lccns
       title
       imprint
       reason_code
       last_update
       govdoc
       pub_year
       pub_place
       language_code
       bib_format_code
       collection_code
       content_provider_code
       responsible_entity_code
       digitization_agent_code
      ]

    HF_COLUMN_INDEXES = HF_COLUMNS.each_with_index.inject({}) {|h, col_ind| h[col_ind.first] = col_ind.last; h}

  end
end
