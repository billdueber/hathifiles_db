require 'library_stdnums'


class HathifilesDB
  class SourceLine

    SOURCELINE_FIELDS = %w(htid access rights_code record_id
                enumchron source_code source_record_number
                oclc_list isbn_list issn_list lccn_list
                title imprint reason_code last_update
                govdoc pub_year pub_place language_code bib_format_code
                ).map(&:to_sym)
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
      allow          = sl.access == 'deny' ? false : true
      sl.source_code = sl.source_code.downcase

      sl.last_update = DateTime.parse(sl.last_update)
      sl.pub_year    = sl.pub_year.to_i

      sl.htid.freeze
      @id        = sl.htid
      @isbn      = isbn_lines(sl.isbn_list.split(SPLIT_ON_COMMA))
      @lccn      = sl.lccn_list.split(SPLIT_ON_COMMA).map {|i| {htid: id, type: LCCN_STR, value: StdNum::LCCN.normalize(i)}}
      @issn      = sl.issn_list.split(SPLIT_ON_COMMA).map {|i| {htid: id, type: ISSN_STR, value: StdNum::ISSN.normalize(i)}}
      @oclc      = sl.oclc_list.split(SPLIT_ON_COMMA).map {|i| {htid: id, type: OCLC_STR, value: normalize_oclc(i)}}
      @stdid     = [].concat(@isbn).concat(@issn).concat(@lccn).concat(@oclc)

      @main_hash = sl.to_h
      # We don't insert the things we split out
      [:access, :isbn_list, :issn_list, :lccn_list, :oclc_list].each do |key|
        @main_hash.delete key
      end

    end

    def isbn_lines(isbnlist)
      isbnlist.map{|i| StdNum::ISBN.allNormalizedValues(i)}.flatten.compact.map{|i| {htid: id, type: ISBN_STR, value: i}}.uniq
    end

    def normalize_oclc(o)
      o.to_s.gsub(/\A0+/, '')
    end
  end
end

