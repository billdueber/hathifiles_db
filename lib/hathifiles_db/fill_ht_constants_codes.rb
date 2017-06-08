require 'sequel'
require 'yaml'
require 'json'

class HathifilesDB
  class FillHTConstantCodes

    include Inject["db"]


    def fill_all
      fill_source_codes
      fill_rights_codes
      fill_reason_codes
    end


    def fill_source_codes
      codes = YAML.load_file("collection_code_to_original_from.yaml")
      codes.each_pair do |code, source|
        db[:source_codes].replace(code: code, source: source)
      end
    end

    def fill_rights_codes
      attributes = JSON.parse(File.open('ht_attributes.json', 'r:utf-8').read)
      attributes.each do |a|
        db[:rights_codes].replace(
           code: a['name'],
           rights: a['dscr']
        )
      end

    end

    def fill_reason_codes
      codes = YAML.load_file("reasons.yaml")
      codes.each_pair do |code, desc|
        db[:reason_codes].replace(code: code, description: desc)
      end
    end


  end
end
