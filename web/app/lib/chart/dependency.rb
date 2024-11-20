# frozen_string_literal: true

class Chart::Dependency
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name
  attribute :repository
  attribute :variants
  attribute :human_visible_name
  attribute :icon
  attribute :description
  attribute :form_component
  attribute :form

  def human_visible_name
    super || name
  end

  def human_visible_version(version)
    variants.find { |v| v.version == version }&.human_visible_version || version
  end

  class Variant
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :version
    attribute :human_visible_version

    def self.from_version(attrs)
      new(
        version: version.fetch(:version),
        human_visible_version: version.fetch(:human_visible_version)
      )
    end
  end

  class << self
    def from_name!(name)
      d = all.find { |d| d.name == name }
      raise ArgumentError, "Unknown dependency: #{name}" unless d
      d
    end

    def from_name(name)
      from_name!(name) rescue nil
    end

    def all
      @all ||= Chart::Dependency::Data::DATA.map do |attrs|
        from_attributes(attrs)
      end
    end

    private

    def from_attributes(attrs)
      new(
        name: attrs.fetch(:name),
        human_visible_name: attrs[:human_visible_name],
        repository: attrs.fetch(:repository),
        icon: attrs.fetch(:icon),
        description: attrs.fetch(:description),
        variants: attrs.fetch(:variants)&.map do |version|
          Chart::Dependency::Variant.new(version)
        end,
        form_component: attrs.fetch(:form_component),
        form: attrs.fetch(:form)
      )
    end
  end
end
