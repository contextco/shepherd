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

  attribute :environment_variables, multiple: true do
    attribute :templated, default: false
    attribute :name
    attribute :value

    validate :name_valid

    def name_valid
      # for now allow empty names which we will ignore when creating the service object
      return if name.empty?
      return if name.match?(/^[a-zA-Z_][a-zA-Z0-9_]*$/)

      errors.add(:name, "must start with a letter or underscore and contain only letters, numbers, and underscores")
    end
  end

  validates :name, presence: true
  validates :image, presence: true
  validate :image_format
  validate :name_format

  def create_service(project_version)
    return unless valid?

    project_version.project_services.create!(
      name:,
      image:,
      resources: resources_object,
      environment_variables: environment_variables_object
    )
  end

  private

  def resources_object
    {
      cpu_request: "#{resources.cpu_request}#{resources.cpu_request_unit}",
      cpu_limit: "#{resources.cpu_limit}#{resources.cpu_limit_unit}",
      memory_request: "#{resources.memory_request}#{resources.memory_request_unit}",
      memory_limit: "#{resources.memory_limit}#{resources.memory_limit_unit}"
    }
  end

  def environment_variables_object
    # filter out empty environment variables names
    # TODO: we should handle this client side more gracefully..
    environment_variables.select { |env| env.name.present? }.map do |env|
      { name: env.name, value: env.value }
    end
  end

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
