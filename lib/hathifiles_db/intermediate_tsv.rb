require 'hathifiles_db/schema/id'
require 'hathifiles_db/schema/stdid'

module HathitrustDB
  class TSV
    include Enumerable

    attr_reader :writable, :number_of_columns

    def self.new(filename_or_io, writeable: false)
      opts      = if writeable
                    "w:utf-8"
                  else
                    "r:utf-8"
                  end
      @io       = filename_or_io.respond_to?(:read) ? filename_or_io : File.open(filename_or_io, opts)
      @writable = writeable
    end

    def <<(*args)
      raise "IDTSV given #{args.size} columns instead of #{@number_of_columns}: #{args.inspect}" unless args.size == @number_of_columns
      raise "IDTSV not writable" unless writable
      @io.puts args.join("\t")
    end

    def each
      @io.each_line {|x| yield x.split("\t")}
    end

  end

  class IDTSV < TSV
    def initalize(*args, **kwargs)
      super
      @number_of_columns = HathifilesDB::Schema::ID.new.columns.size
    end

    def add_from_full_line_values(flv)
      self << flv.values_at[]
    end

  end

  class STDIDTSV < TSV
    def initalize(*args, **kwargs)
      super
      @number_of_columns = 2 # just id and number
    end
  end

end

