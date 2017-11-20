module HathifilesDB
  class TSV
    include Enumerable

    attr_reader :writable, :number_of_columns

    TSVDIR = ENV['TSVDIR']

    def initialize(filename_or_io, schema:, writeable: false)
      opts               = if writeable
                             "w:utf-8"
                           else
                             "r:utf-8"
                           end
      @io                = if filename_or_io.respond_to?(:read)
                             filename_or_io
                           else
                             fname = File.join(TSVDIR, filename_or_io)
                             File.open(fname, opts)
                           end
      @writable          = writeable
      @schema            = schema
      @number_of_columns = schema.hathifile_tsv_columns.size
      @col_indexes       = schema.hathifile_tsv_column_indexes
    end

    def add_line(args)
      raise "IDTSV given #{args.size} columns instead of #{@number_of_columns}: #{args.inspect}" unless args.size == @number_of_columns
      raise "IDTSV not writable" unless writable
      @io.puts args.join("\t")
    end

    def <<(hline_as_array)
      insertables = @schema.hf_line_data(hline_as_array)
      return if insertables.empty?
      insertables = [insertables] unless insertables.first.kind_of? Array
      insertables.each do |hfl|
        self.add_line hfl.map {|x| /"/.match(x) ? '"' << x.gsub('"', '""') << '"' : x}
      end
    end

    def each
      @io.each_line {|x| yield x.split("\t")}
    end
  end

end
