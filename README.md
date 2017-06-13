# HathifilesDB: create and keep up-to-date an sql version of the hathifiiles

This is a (slow) program that will (slowly) create, and later keep up-to-date,
a simple sql database that reflects the information in the [HathiTrust
hathifiles](https://www.hathitrust.org/hathifiles) ([description](https://www.hathitrust.org/hathifiles_description)).

Downloading, processing, and importing the full file into a local mysql using jruby
takes me about an hour (on a reasonably fast machine and network). Updating with the 
incremental files takes me 3-4 minutes each.

I'm sure there are speed improvements to be had, but I'm planning on running it in a 
cronjob overnight so that's not a high priority right now.

## Creating or updating a database with hathifile data

```bash
# First, install this gem
gem install hathifiles_db

# ...and, if using sqlite, make sure you have sqlite3 installed
# and in your path
type sqlite3 # => /usr/bin/sqlite3


# You might want to check out the help text first

hathifiles help
hathifiles help update


# For simplicity create and update a local sqlite database in the current directory
# We'll notice the database is empty and do all the schema creation

hathifiles update --db='sqlite://hathifiles.db'

# ...or you can set the environment variable HATHIFILES_CONNECTION_STRING
# instead of using the '--db' switch

export HATHIFILES_CONNECTION_STRING='sqlite://hathifiles.db'

# You can also use a mysql database. Make sure to create it first
mysqladmin create hathifiles
export HATHIFILES_CONNECTION_STRING='mysql2://localhost/hathifiles?user=myname&password=mypass'


# The `update` command is used to both create the new database (from empty)
# and do incremental updates
#
# If the HATHIFILES_CONNECTION_STRING environment variable is set, just do

hathifiles update

# If for some reason you want to force a full update, you can set it

hathifiles update --force-reload



```

## How is the resulting database different from the raw hathifiles?

Besides being in a database, there are few changes:
  * Standard identifiers (lccn, oclc, isbn, issn) are broken off into
    their own table (`stdid`)
  * Standard identifiers are also normalized. This means:
    * LCCNs are normalized accrording to the LoC rules
    * OCLC numbers have leading zeros stripped
    * ISSNs are indexed just as a string of digits, with no intervening punctuation
    * ISBNs are indexed in both their 10-character and 13-digit form
 
 All normalization is done using [library_stdnums](https://github.com/billdueber/library_stdnums)


## The database schema

...is as simple as possible. A main table, `htid`, that holds the bulk of the 
data, and a single `stdid` table to standard identifiers associated with 
each hathitrust id.

### HTID table

These all correspond well to their counterparts in as noted in the 
[Hathifiles Description](https://www.hathitrust.org/hathifiles_description)

```ruby
 def create_htid
    db.create_table :htid do
      String :htid
      index :htid, unique: true

      TrueClass :allow, index: true

      # foreign_key :rights_code, :rights_codes, key: :code, type: String, index: true
      String :rights_code, index: true

      String :record_id, index: true
      String :enumchron

      # foreign_key :source_code, :source_codes, key: :code, type: String, index: true
      String :source_code, index: true

      String :source_record_number, index: true
      String :title, :text => true
      String :imprint, :text => true

      # foreign_key :reason_code, :reason_codes, key: :code, type: String, index: true
      String :reason_code, index: true

      DateTime :last_update, index: true
      TrueClass :govdoc, index: true
      Integer :pub_year, index: true
      String :pub_place
      String :language_code
      String :bib_format_code
    end
  end
  ```
  
  ### The STDID table
  
  ...is even simpler -- just the hathitrust id, one of several strings to
  indicate the type ('lccn', 'oclc', 'isbn', 'issn'), and the 
  value of said identifier.
  
  ```ruby 
  
  def create_stdid
    db.create_table :stdid do
      String :htid, index: true
      String :type, index: true
      String :value, index: true
    end
  end
  
  ```

### Other tables

Some of the `*_code` entries in the `htid` table have corresponding
lookup tables where you can turn the code value into a more human-readable 
string.

* `source_codes` map the code to the contributing institution. It's not as 
nuanced as we now track, but it corresponds to what's in the hathifiles.
* `rights_codes` gives an explanation (of a sort) as to what the access rights are
for the item.
* `reason_codes` gives insight into *why* a particular rights_code has been assigned.




## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hathifiles_db'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hathifiles_db



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/billdueber/hathifiles_db. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

