# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comparisons::Warning do
  subject { described_class.new(comparisons).warnings }

  let(:service_changes) do
    [
      Comparisons::Change.new(field: "Port", old_value: 80, new_value: nil),
      Comparisons::Change.new(field: "Secret", old_value: "TEST", new_value: "THING"),
      Comparisons::Change.new(field: "Image", old_value: "nginx:1.2.3", new_value: "nginx:alpine")
    ]
  end
  let(:service_object) { Comparisons::ObjectComparison.new(name: 'nginx', type: :service, status: :modified, changes: service_changes) }
  let(:comparisons) { [ service_object ] }

  context "when there are changes" do
    it "results in two warnings" do
      expect(subject.count).to eq(2)
    end
  end

  context "when there are no relevant changes" do
    let(:service_changes) { Comparisons::Change.new(field: "Image", old_value: "nginx:1.2.3", new_value: "nginx:alpine") }

    it "results in no warnings" do
      expect(subject.count).to eq(0)
    end
  end

  context "when there are addition and deletion objects" do
    let(:comparisons) { [ service_object, addition_object ] }
    let(:addition_object) { Comparisons::ObjectComparison.new(name: 'worker', type: :service, status: :added, changes: []) }

    it "results in two warning" do
      expect(subject.count).to eq(2)
    end
  end
end
