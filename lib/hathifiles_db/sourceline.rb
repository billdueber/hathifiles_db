require 'library_stdnums'


class HathifilesDB
  class SourceLine

    SOURCELINE_FIELDS = %w(htid access rights_code record_id
                enumchron source_code source_record_number
                oclc_list isbn_list issn_list lccn_list
                title imprint reason_code last_update
                govdoc pub_year pub_place language_code bib_format_code
                collection_code content_provider_code responsible_entity
                digitization_agent).map(&:to_sym)

    SOURCELINE        = Struct.new(*SOURCELINE_FIELDS)
    LINEDATA          = Struct.new(:htid, :main, :isbn, :issn, :lccn, :oclc, :stdid)

    OCLC_STR = 'oclc'.freeze
    ISBN_STR = 'isbn'.freeze
    ISSN_STR = 'issn'.freeze
    LCCN_STR = 'lccn'.freeze

    SPLIT_ON_COMMA = /\s*,\s*/

    attr_accessor :id, :main_hash, :isbn, :issn, :lccn, :oclc, :stdid

    def initialize(line)
      sl             = SOURCELINE.new(*(line.chomp.split(/\t/)))
      allow          = sl.access == 'deny' ? 0 : 1
      sl.source_code = sl.source_code.downcase

      sl.last_update = DateTime.parse(sl.last_update)
      sl.pub_year    = sl.pub_year.to_i

      sl.htid.freeze
      @id        = sl.htid
      # @isbn      = isbn_lines(sl.isbn_list.split(SPLIT_ON_COMMA))
      # @lccn      = sl.lccn_list.split(SPLIT_ON_COMMA).map {|i| {htid: id, type: LCCN_STR, value: StdNum::LCCN.normalize(i)}}
      # @issn      = sl.issn_list.split(SPLIT_ON_COMMA).map {|i| {htid: id, type: ISSN_STR, value: StdNum::ISSN.normalize(i)}}
      # @oclc      = sl.oclc_list.split(SPLIT_ON_COMMA).map {|i| {htid: id, type: OCLC_STR, value: normalize_oclc(i)}}

      @isbn =      isbn_lines(sl.isbn_list.split(SPLIT_ON_COMMA))
      @lccn      = sl.lccn_list.split(SPLIT_ON_COMMA).map {|i| [id, LCCN_STR, StdNum::LCCN.normalize(i)]}
      @issn      = sl.issn_list.split(SPLIT_ON_COMMA).map {|i| [id, ISSN_STR, StdNum::ISSN.normalize(i)]}
      @oclc      = sl.oclc_list.split(SPLIT_ON_COMMA).map {|i| [id, OCLC_STR, normalize_oclc(i)]}

      @stdid     = [].concat(@isbn).concat(@issn).concat(@lccn).concat(@oclc)

      @main_hash = sl.to_h
      @main_hash[:allow] = allow

      # Remove the raw ID fields
      [:access, :isbn_list, :issn_list, :lccn_list, :oclc_list].each do |key|
        @main_hash.delete key
      end

    end



    def isbn_lines(isbnlist)
      isbnlist.map{|i| StdNum::ISBN.allNormalizedValues(i)}.flatten.compact.map{|i| [id, ISBN_STR, i]}
    end

    def normalize_oclc(o)
      o.to_s.gsub(/\A0+/, '')
    end
  end
end

