require 'zlib'
require 'sequel'

class HathifilesDB

  FIELDS = %w(htid access rights_code recordid
                enumchron source_code source_record_number
                oclc_list isbn_list issn_list lccn_list
                title imprint reason_code last_update
                govdoc pub_year pub_place language_code bib_format_code
                ).map(&:to_sym)
  SOURCLINE = Struct.new(*FIELDS)
  LINEDATA  = Struct.new(:htid, :main, :isbn, :issn, :lccn, :oclc)

  OCLC_STR = 'oclc'.freeze
  ISBN_STR = 'isbn'.freeze
  ISSN_STR = 'issn'.freeze
  LCCN_STR = 'lccn'.freeze

  SPLIT_ON_COMMA = /\s*,\s*/
  def self.data_from_raw_line(line)
    sl = HathifilesDB::SOURCLINE.new(*(line.chomp.split(/\t/)))
    allow = sl.access == 'deny' ? false : true
    sl.source_code = sl.source_code.downcase

    sl.last_update = DateTime.parse(sl.last_update)
    sl.pub_year = sl.pub_year.to_i

    sl.htid.freeze
    id = sl.htid
    isbn = sl.isbn_list.split(SPLIT_ON_COMMA).map{|i| {htid: id, type: ISBN_STR, value: i}}
    lccn = sl.lccn_list.split(SPLIT_ON_COMMA).map{|i| {htid: id, type: LCCN_STR, value: i}}
    issn = sl.issn_list.split(SPLIT_ON_COMMA).map{|i| {htid: id, type: ISSN_STR, value: i}}
    oclc = sl.oclc_list.split(SPLIT_ON_COMMA).map{|i| {htid: id, type: OCLC_STR, value: i}}

    # We don't insert the things we split out
    main_hash = sl.to_h
    [:access, :isbn_list, :issn_list, :lccn_list, :oclc_list].each do |key|
      main_hash.delete key
    end
    LINEDATA.new(id, main_hash, isbn, issn, lccn, oclc)

  end
  #
  # class OCLC < Sequel::Model
  #   set_dataset Sequel::Model.db[:oclc]
  # end
  # class ISBN < Sequel::Model
  #   set_dataset Sequel::Model.db[:isbn]
  # end
  # class ISSN < Sequel::Model
  #   set_dataset Sequel::Model.db[:issn]
  # end
  # class LCCN < Sequel::Model
  #   set_dataset Sequel::Model.db[:lccn]
  # end
  #
  # class HTID < Sequel::Model
  #   # one_to_many :oclc_objs, primary_key: :htid, key: :htid, class: OCLC
  #   # one_to_many :isbn_objs, primary_key: :htid, key: :htid, class: ISBN
  #   # one_to_many :issn_objs, primary_key: :htid, key: :htid, class: ISSN
  #   # one_to_many :lccn_objs, primary_key: :htid, key: :htid, class: LCCN
  #
  #   unrestrict_primary_key
  #
  #   def self.new_from_line(line)
  #     sl = HathifilesDB::SOURCLINE.new(*(line.chomp.split(/\t/)))
  #     allow = sl.access == 'deny' ? false : true
  #     sl.source_code = sl.source_code.downcase
  #
  #     htid = self.find_or_create(htid: sl.htid)
  #     htid.set_fields(sl.to_h, htid.columns)
  #     htid.allow = allow
  #
  #     htid.save
  #     id = htid.htid
  #     isbns = sl.isbn_list.split(/\s*,\s*/)
  #     db[:isbn].where(htid: htid.htid).delete
  #     db[:isbn].import [:htid, :isbn], isbns.map{|i| [id, i]}
  #
  #
  #
  #     # TOO SLOW!
  #     # htid.remove_all_isbn_objs
  #     # sl.isbn_list.split(/\s*,\s*/).each do |oclc_str|
  #     #   o = ISBN.new(isbn: oclc_str)
  #     #   htid.add_isbn_obj o
  #     # end
  #     #
  #     # htid.remove_all_oclc_objs
  #     # sl.oclc_list.split(/\s*,\s*/).each do |oclc_str|
  #     #   o = OCLC.new( oclc: oclc_str)
  #     #   htid.add_oclc_obj o
  #     # end
  #     #
  #     # htid.remove_all_issn_objs
  #     # sl.issn_list.split(/\s*,\s*/).each do |oclc_str|
  #     #   o = ISSN.new( issn: oclc_str)
  #     #   htid.add_issn_obj o
  #     # end
  #     #
  #     # htid.remove_all_lccn_objs
  #     # sl.lccn_list.split(/\s*,\s*/).each do |oclc_str|
  #     #   o = LCCN.new( lccn: oclc_str)
  #     #   htid.add_lccn_obj o
  #     # end
  #
  #     htid
  #
  #   end
  #
  #   def issns
  #     issn_objs.map(&:issn)
  #   end
  #
  #   def oclcs
  #     oclc_objs.map(&:oclc)
  #   end
  #
  #   def isbns
  #     isbn_objs.map(&:isbn)
  #   end
  #
  #   def lccns
  #     lccn_objs.ap(&:lccn)
  #   end


  # end
end
