require 'hathifiles_db/hathifile_set'

RSpec.describe HathifilesDB::HathifileSet do
  let(:hfs) { HathifilesDB::HathifileSet.new(data_file_content('hathifiles.html')) }

  it "Can read a file" do
    hfs = HathifilesDB::HathifileSet.new(data_file_content('hathifiles.html'))
    expect(hfs)
  end

  it "parses out all the items" do
    expect(hfs.all.size).to equal(35)
  end

  it "finds the most recent full file" do
    expect(hfs.fullfile.datestamp).to eq(20171101)
  end



end

