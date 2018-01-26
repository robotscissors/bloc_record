require_relative '../lib/bloc_record/selection'

describe 'Selection' do
  describe '.find_one' do
    it "expect file to " do
      expect(Selection.find_one(-1)). eq('Invalid ID - ID must be greater than or equal to zero')
    end
  end
end
