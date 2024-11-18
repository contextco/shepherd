# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Chart::Dependency do
  describe '.from_name!' do
    Chart::Dependency::Data::DATA.each do |attrs|
      it "returns a dependency for #{attrs[:name]}" do
        expect(described_class.from_name!(attrs[:name])).to be_a(described_class)
      end
    end
  end

  describe '.all' do
    it 'returns all dependencies' do
      expect(described_class.all).to all(be_a(described_class))
    end

    it 'returns the correct number of dependencies' do
      expect(described_class.all.size).to eq(Chart::Dependency::Data::DATA.size)
    end
  end

end

