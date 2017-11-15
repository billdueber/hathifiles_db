require 'hathifiles_db/schema/base'

module HathifilesDB
  module Schema
    class BibFormatCodes < Base

      def table_name
        :bib_format_codes
      end

      def index_columns
        [
          :code
        ]
      end

      def create
        create_table do
          String :code, primary_key: true
          String :bib_format
        end
      end
    end
  end
end
