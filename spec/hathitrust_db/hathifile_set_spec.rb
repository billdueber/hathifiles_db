require 'hathifiles_db/hathifile_set'


RSpec.describe HathifilesDB::HathifileSet do
  let(:hfs) { HathifilesDB::HathifileSet.new(data_file_content('hathifiles.html')) }
  it "Can read a file" do
    hfs = HathifilesDB::HathifileSet.new(data_file_content('hathifiles.html'))
    expect(hfs)
  end
end

