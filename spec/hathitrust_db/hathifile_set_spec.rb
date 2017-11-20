require 'hathifiles_db/hathifile_set'

RSpec.describe HathifilesDB::HathifileSet do

  # The test file goes from 20171001 to 20171102
  let(:hfs) {HathifilesDB::HathifileSet.new(data_file_content('hathifiles.html'))}

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

  it "will only do the most recent files, crossing a month boundary" do
    expect(hfs.catchup_files(0).size).to eq(3) # 1101full, 1101update, 1102update
  end

  it "finds both the full and update file on the 1st" do
    expect(hfs.truncate(20171101).catchup_files(0).size).to eq(2)
  end

  it "finds no update correctly" do
    expect(hfs.catchup_files(20171201).size).to eq(0)
  end

  it "finds only update files if fullfile not needed" do
    h = hfs.truncate(20171005)
    cf = h.catchup_files(20171003)
    expect(cf.find{|x| x.full?}).to be_nil
    expect(cf.map{|x| x.datestamp}).to eq([20171004, 20171005])
  end

end


