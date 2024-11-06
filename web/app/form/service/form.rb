# frozen_string_literal: true

class Service::Form
  include FormObject

  attribute :name
  attribute :image

  attribute :resources do
    attribute :cpu_request, default: 1
    attribute :cpu_limit, default: 2
    attribute :memory_request, default: 1
    attribute :memory_limit, default: 2

    attribute :cpu_request_unit, default: "Cores"
    attribute :cpu_limit_unit, default: "Cores"
    attribute :memory_request_unit, default: "Gi"
    attribute :memory_limit_unit, default: "Gi"

    validates :cpu_request, presence: true, numericality: { greater_than: 0, less_than: 1025 }
    validates :cpu_limit, presence: true, numericality: { greater_than: 0, less_than: 1025 }
    validates :memory_request, presence: true, numericality: { greater_than: 0, less_than: 1025 }
    validates :memory_limit, presence: true, numericality: { greater_than: 0, less_than: 1025 }

    validates :cpu_request_unit, presence: true, inclusion: { in: %w[Cores mCores] }
    validates :cpu_limit_unit, presence: true, inclusion: { in: %w[Cores mCores] }
    validates :memory_request_unit, presence: true, inclusion: { in: %w[Gi Mi Ki] }
    validates :memory_limit_unit, presence: true, inclusion: { in: %w[Gi Mi Ki] }
  end

  validates :name, presence: true
  validates :image, presence: true
  validate :image_format
  validate :name_format

  private

  def name_format
    # name should be lower case and contain only letters, numbers, and hyphens and no spaces
    return if name.match?(/\A[a-z0-9-]+\z/)

    errors.add(:name, "must be lower case and contain only letters, numbers, and hyphens")
  end

  def image_format
    begin
      url = DockerImageUrlParser.new(image)
    rescue DockerImageUrlParser::InvalidDockerImageURLError
      return errors.add(:image, "is not a valid docker image")
    end
    return if url.tag != "latest"

    errors.add(:image, "must specify an image version and not latest")
  end
end
